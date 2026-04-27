// internal/handlers/payroll_handler.go

package handlers

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Helper: Format Date ke Indonesia (Misal: 2026-04-01 -> Rabu 1 April 2026)
func formatDateIndo(dateStr string) string {
	t, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return dateStr
	}

	days := []string{"Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"}
	months := []string{"Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"}

	return fmt.Sprintf("%s %d %s %d", days[t.Weekday()], t.Day(), months[t.Month()-1], t.Year())
}

// Helper: Get Month Name in Indo
func getMonthNameIndo(m int) string {
	months := []string{"Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"}
	if m < 1 || m > 12 {
		return "-"
	}
	return months[m-1]
}

type LateTier struct {
	Hours   int     `json:"hours"`
	Penalty float64 `json:"penalty"`
}

// GetMySalaries - Employee view (Microservices version)
func GetMySalaries(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)
	userID := user.ID

	yearStr := c.Query("year")
	monthStr := c.Query("month")
	if yearStr == "" {
		yearStr = strconv.Itoa(time.Now().Year())
	}
	
	ensureSalariesGenerated(userID)

	var salaries []models.Salary
	query := database.DB.Preload("Payments").
		Where("user_id = ? AND year = ?", userID, yearStr)

	if monthStr != "" && monthStr != "0" {
		query = query.Where("month = ?", monthStr)
	}

	if err := query.Order("month DESC").Find(&salaries).Error; err != nil {
		utils.Error(c, "Gagal mengambil riwayat gaji")
		return
	}

	// Link user info for display (User is already in context)
	for i := range salaries {
		salaries[i].User = user
	}

	utils.Success(c, "Berhasil mengambil riwayat gaji", salaries)
}

// GetSalaryYears - Get list of unique years that have salary data for the current user
func GetSalaryYears(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)
	userID := user.ID

	var years []int
	err := database.DB.Model(&models.Salary{}).
		Where("user_id = ?", userID).
		Distinct("year").
		Order("year DESC").
		Pluck("year", &years).Error

	if err != nil {
		utils.Error(c, "Gagal mengambil daftar tahun")
		return
	}

	utils.Success(c, "Berhasil mengambil daftar tahun", years)
}

// AdminGetSalaries - Admin view with filters (Microservices version)
func AdminGetSalaries(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	month, _ := strconv.Atoi(c.Query("month"))
	year, _ := strconv.Atoi(c.Query("year"))
	positionID := c.Query("position_id")
	search := c.Query("search")

	// 1. Fetch Employees from Auth Service (Port 8081)
	var employees []models.User
	authURL := fmt.Sprintf("http://localhost:8081/api/internal/users?company_id=%s", admin.CompanyID)
	if err := utils.CallInternalAPI(authURL, &employees); err != nil {
		utils.Error(c, "Gagal mengambil data karyawan dari Auth Service")
		return
	}

	// 2. Filter employees in memory (mimic previous DB filters)
	var filteredUserIDs []string
	userMap := make(map[string]models.User)
	for _, emp := range employees {
		// Filter by Position
		if positionID != "" && (emp.PositionID == nil || *emp.PositionID != positionID) {
			continue
		}
		// Filter by Search
		if search != "" && !strings.Contains(strings.ToLower(emp.Name), strings.ToLower(search)) {
			continue
		}
		filteredUserIDs = append(filteredUserIDs, emp.ID)
		userMap[emp.ID] = emp
	}

	// Proactive Generation: Ensure salaries exist for filtered users
	if month > 0 && year > 0 {
		for _, userID := range filteredUserIDs {
			generateSalary(userID, month, year)
		}
	}

	// 3. Fetch Salaries from Payroll DB
	var salaries []models.Salary
	query := database.DB.Preload("Payments").Where("user_id IN ?", filteredUserIDs)

	if month > 0 && year > 0 {
		query = query.Where("month = ? AND year = ?", month, year)
	} else {
		if month > 0 {
			query = query.Where("month = ?", month)
		}
		if year > 0 {
			query = query.Where("year = ?", year)
		}
	}

	query.Order("year desc, month desc").Find(&salaries)

	// 4. Manually link User data back to Salary objects
	for i := range salaries {
		if u, ok := userMap[salaries[i].UserID]; ok {
			salaries[i].User = u
		}
	}

	utils.Success(c, "Berhasil mengambil data payroll", salaries)
}

// AdminPaySalary - Process payment (supports installments)
func AdminPaySalary(c *gin.Context) {
	salaryID := c.Param("id")
	amountStr := c.PostForm("amount")

	var salary models.Salary
	if err := database.DB.Where("id = ?", salaryID).First(&salary).Error; err != nil {
		utils.Error(c, "Data gaji tidak ditemukan")
		return
	}

	// Force recalculate if total salary is 0 (prevent zero-amount payment bug)
	if salary.TotalSalary <= 0 {
		generateSalary(salary.UserID, salary.Month, salary.Year)
		database.DB.First(&salary, "id = ?", salaryID) // reload
	}

	if salary.TotalSalary <= 0 {
		utils.Error(c, "Gaji belum terkonfigurasi (Total Rp 0). Harap pastikan Jabatan & Gaji Pokok sudah benar.")
		return
	}

	if salary.Status == "PAID" {
		utils.Error(c, "Gaji ini sudah lunas")
		return
	}

	// Calculate remaining balance
	balance := salary.TotalSalary - salary.PaidAmount

	var payAmount float64
	if amountStr == "" {
		payAmount = balance // Pay Full if amount not specified
	} else {
		var err error
		payAmount, err = strconv.ParseFloat(amountStr, 64)
		if err != nil || payAmount <= 0 {
			utils.Error(c, "Nominal pembayaran tidak valid")
			return
		}
		if payAmount > balance {
			utils.Error(c, "Nominal melebihi sisa gaji (Sisa: "+utils.FormatRupiah(balance)+")")
			return
		}
	}

	// Handle optional payment proof photo
	photo, err := c.FormFile("proof")
	var photoPath string
	if err == nil {
		photoName := uuid.New().String() + ".jpg"
		photoPath = "/uploads/payments/" + photoName
		if err := c.SaveUploadedFile(photo, "uploads/payments/"+photoName); err != nil {
			utils.Error(c, "Gagal menyimpan bukti pembayaran")
			return
		}
	}

	now := time.Now()

	// Start transaction for atomic payment recording
	err = database.DB.Transaction(func(tx *gorm.DB) error {
		// 1. Create individual payment record
		payment := models.SalaryPayment{
			ID:       uuid.New().String(),
			SalaryID: salaryID,
			Amount:   payAmount,
			Proof:    photoPath,
			PaidAt:   now,
		}
		if err := tx.Create(&payment).Error; err != nil {
			return err
		}

		// 2. Recalculate total paid amount from all payments for this salary
		var totalPaid float64
		if err := tx.Model(&models.SalaryPayment{}).Where("salary_id = ?", salaryID).Select("sum(amount)").Scan(&totalPaid).Error; err != nil {
			return err
		}

		// 3. Update main salary record status and total
		status := "PARTIAL"
		if totalPaid >= salary.TotalSalary {
			status = "PAID"
		} else if totalPaid > 0 {
			status = "PARTIAL"
		} else {
			status = "PENDING"
		}

		updates := map[string]interface{}{
			"paid_amount":   totalPaid,
			"payment_proof": photoPath,
			"paid_at":       &now,
			"status":        status,
		}

		if err := tx.Model(&models.Salary{}).Where("id = ?", salaryID).Updates(updates).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		utils.Error(c, "Gagal mencatatkan pembayaran: "+err.Error())
		return
	}

	// Load updated record with payments preloaded
	database.DB.Preload("Payments").First(&salary, "id = ?", salaryID)

	// Kirim notifikasi ke karyawan
	var user models.User
	database.DB.Select("company_id").First(&user, "id = ?", salary.UserID)

	monthName := getMonthNameIndo(salary.Month)
	services.CreateNotification(salary.UserID, user.CompanyID, "Gaji Dibayarkan",
		fmt.Sprintf("Gaji kamu untuk bulan %s %d telah dibayarkan sebesar %s.", monthName, salary.Year, utils.FormatRupiah(payAmount)),
		"PAYROLL_PAID", salary.ID)
	services.SendPushNotification(salary.UserID, "Gaji Dibayarkan",
		fmt.Sprintf("Gaji bulan %s kamu telah dibayarkan sebesar %s. Silakan cek detailnya!", monthName, utils.FormatRupiah(payAmount)))

	utils.Success(c, "Pembayaran berhasil dicatat", salary)
}

// UpdateBankInfo - Employee sets their own bank info
func UpdateBankInfo(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)
	userID := user.ID

	var input struct {
		BankName          string `json:"bank_name" binding:"required"`
		BankAccountNumber string `json:"bank_account_number" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		utils.Error(c, "Input tidak valid")
		return
	}

	if err := database.DB.Model(&models.User{}).Where("id = ?", userID).Updates(models.User{
		BankName:          input.BankName,
		BankAccountNumber: input.BankAccountNumber,
	}).Error; err != nil {
		utils.Error(c, "Gagal memperbarui info bank")
		return
	}

	utils.Success(c, "Info bank berhasil diperbarui", nil)
}

// Logic to ensure salaries are generated for specific user
func ensureSalariesGenerated(userID string) {
	now := time.Now()
	// Cek bulan ini dan bulan lalu
	monthsToCheck := []time.Time{now, now.AddDate(0, -1, 0)}

	for _, t := range monthsToCheck {
		month := int(t.Month())
		year := t.Year()

		// Bersihkan duplikasi jika ada sebelum memproses penjaminan record
		repairDuplicates(userID, month, year)

		isCurrentMonth := (t.Year() == now.Year() && int(t.Month()) == int(now.Month()))

		var exist models.Salary
		err := database.DB.Where("user_id = ? AND month = ? AND year = ?", userID, month, year).First(&exist).Error
		if err != nil { // Not found
			generateSalary(userID, month, year)
		} else if isCurrentMonth || exist.Status == "PENDING" || exist.TotalSalary <= 0 || (exist.Status == "PAID" && exist.PaidAmount < exist.TotalSalary) {
			// Update rincian jika:
			// 1. Bulan berjalan (absensi masih bisa bertambah)
			// 2. Masih pending
			// 3. Data korup (TotalSalary 0)
			// 4. Status salah (Tertulis PAID tapi belum bayar penuh)
			generateSalary(userID, month, year)
		}
	}
}

// repairDuplicates menggabungkan data gaji ganda jika ditemukan untuk satu user/bulan/tahun
func repairDuplicates(userID string, month int, year int) {
	var salaries []models.Salary
	database.DB.Where("user_id = ? AND month = ? AND year = ?", userID, month, year).Find(&salaries)

	if len(salaries) <= 1 {
		return
	}

	// Pilih satu sebagai primary (yang sudah lunas atau yang punya pembayaran terbanyak)
	primary := salaries[0]
	for i := 1; i < len(salaries); i++ {
		// Pindahkan semua Payments dari secondary ke primary
		database.DB.Model(&models.SalaryPayment{}).Where("salary_id = ?", salaries[i].ID).Update("salary_id", primary.ID)
		// Hapus record secondary
		database.DB.Unscoped().Delete(&salaries[i])
	}

	// Setelah digabung, trigger hitung ulang total bayar pada record primary
	generateSalary(userID, month, year)
}

func generateSalary(userID string, month int, year int) {
	// 1. Fetch User data from Auth Service (Microservices)
	var user models.User
	
	utils.CallInternalAPI(fmt.Sprintf("http://localhost:8081/api/internal/users/single?id=%s", userID), &user)

	if user.ID == "" {
		return
	}

	// JANGAN buat gaji untuk peran ADMIN
	if user.Role == "ADMIN" {
		// Cleanup jika ada record tersisa
		database.DB.Where("user_id = ?", userID).Delete(&models.Salary{})
		return
	}

	// JANGAN buat gaji untuk bulan SEBELUM karyawan bergabung
	joinMonth := time.Date(user.CreatedAt.Year(), user.CreatedAt.Month(), 1, 0, 0, 0, 0, time.Local)
	targetMonth := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local)
	if targetMonth.Before(joinMonth) {
		// Jika ini adalah data sampah dari bug sebelumnya, kita hapus saja
		database.DB.Where("user_id = ? AND month = ? AND year = ?", userID, month, year).Delete(&models.Salary{})
		return
	}

	// [NEW] Perbaiki record ganda sebelum memproses update
	repairDuplicates(userID, month, year)

	// Gaji dasar dari Position
	baseSalary := 0.0
	if user.PositionID != nil {
		baseSalary = user.Position.Salary
	}

	// Hitung Penyesuaian (Bonuses & Deductions)
	deductions, bonuses, deductionDetails, bonusDetails := FetchAdjustmentsFromAttendance(userID, month, year)

	// Update or Create
	var salary models.Salary
	database.DB.Where("user_id = ? AND month = ? AND year = ?", userID, month, year).First(&salary)

	// Recalculate PaidAmount from actual payments to fix corruption
	var actualPaid float64
	database.DB.Model(&models.SalaryPayment{}).Where("salary_id = ?", salary.ID).Select("sum(amount)").Scan(&actualPaid)
	salary.PaidAmount = actualPaid

	if salary.ID == "" {
		salary.ID = uuid.New().String()
		salary.UserID = userID
		salary.Month = month
		salary.Year = year
		salary.Status = "PENDING"
	}

	salary.BaseSalary = baseSalary
	salary.Deductions = deductions
	salary.Bonuses = bonuses
	
	// Trim trailing semicolon and space from details
	if len(deductionDetails) > 2 && deductionDetails[len(deductionDetails)-2:] == "; " {
		deductionDetails = deductionDetails[:len(deductionDetails)-2]
	}
	if len(bonusDetails) > 2 && bonusDetails[len(bonusDetails)-2:] == "; " {
		bonusDetails = bonusDetails[:len(bonusDetails)-2]
	}

	salary.DeductionsDetail = deductionDetails
	salary.BonusesDetail = bonusDetails
	salary.TotalSalary = baseSalary + bonuses - deductions
	if salary.TotalSalary < 0 {
		salary.TotalSalary = 0
	}

	// Sinkronisasi status berdasarkan histori pembayaran
	if salary.TotalSalary > 0 {
		if salary.PaidAmount >= salary.TotalSalary {
			salary.Status = "PAID"
		} else if salary.PaidAmount > 0 {
			salary.Status = "PARTIAL"
		} else {
			salary.Status = "PENDING"
		}
	} else {
		salary.Status = "PENDING"
	}

	database.DB.Save(&salary)
}

func FetchAdjustmentsFromAttendance(userID string, month int, year int) (float64, float64, string, string) {
	// 1. Call Attendance Service (Port 8082) to get attendance-based adjustments
	url := fmt.Sprintf("http://localhost:8082/api/internal/salary-adjustments?user_id=%s&month=%d&year=%d", userID, month, year)
	
	var result struct {
		Deductions       float64 `json:"deductions"`
		Bonuses          float64 `json:"bonuses"`
		DeductionDetails string  `json:"deduction_details"`
		BonusDetails     string  `json:"bonus_details"`
	}

	if err := utils.CallInternalAPI(url, &result); err != nil {
		fmt.Printf("[Payroll] Error fetching adjustments from Attendance: %v\n", err)
	}

	totalDeductions := result.Deductions
	totalBonuses := result.Bonuses
	deductionDetails := result.DeductionDetails
	bonusDetails := result.BonusDetails

	// 2. Fetch Manual Penalties from Local DB (Payroll Service)
	var manualPenalties []models.Penalty
	database.DB.Where("user_id = ? AND month(date) = ? AND year(date) = ?", userID, month, year).Find(&manualPenalties)
	for _, p := range manualPenalties {
		totalDeductions += p.Amount
		deductionDetails += fmt.Sprintf("%s: %s (Rp%.0f); ", p.Date, p.Title, p.Amount)
	}

	// 3. Fetch Manual Bonuses from Local DB (Payroll Service)
	var manualBonuses []models.Bonus
	database.DB.Where("user_id = ? AND month(date) = ? AND year(date) = ?", userID, month, year).Find(&manualBonuses)
	for _, b := range manualBonuses {
		totalBonuses += b.Amount
		bonusDetails += fmt.Sprintf("%s: %s (Rp%.0f); ", b.Date, b.Title, b.Amount)
	}

	return totalDeductions, totalBonuses, deductionDetails, bonusDetails
}

// GetInternalSalary - Endpoint internal untuk mengambil data gaji (Microservices)
func GetInternalSalary(c *gin.Context) {
	userID := c.Query("user_id")
	month, _ := strconv.Atoi(c.Query("month"))
	year, _ := strconv.Atoi(c.Query("year"))

	if userID == "" || month == 0 || year == 0 {
		c.JSON(400, gin.H{"error": "missing parameters"})
		return
	}

	// Pastikan data gaji sudah digenerate/diupdate
	ensureSalariesGenerated(userID)

	var salary models.Salary
	database.DB.Where("user_id = ? AND month = ? AND year = ?", userID, month, year).First(&salary)

	c.JSON(200, salary)
}
