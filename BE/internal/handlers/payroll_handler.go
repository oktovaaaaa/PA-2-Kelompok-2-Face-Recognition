// internal/handlers/payroll_handler.go

package handlers

import (
	"encoding/json"
	"fmt"
	"strconv"
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

// GetMySalaries - Employee view (Only shows past months since joining)
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
	query := database.DB.Preload("User").Preload("User.Position").Preload("Payments").
		Joins("JOIN users ON users.id = salaries.user_id").
		Where("salaries.user_id = ? AND salaries.year = ?", userID, yearStr)

	if monthStr != "" && monthStr != "0" {
		query = query.Where("salaries.month = ?", monthStr)
	}

	if err := query.Order("salaries.month DESC").Find(&salaries).Error; err != nil {
		utils.Error(c, "Gagal mengambil riwayat gaji")
		return
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

// AdminGetSalaries - Admin view with filters
func AdminGetSalaries(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	month, _ := strconv.Atoi(c.Query("month"))
	year, _ := strconv.Atoi(c.Query("year"))
	positionID := c.Query("position_id")
	search := c.Query("search")

	// Proactive Generation & Cleanup: Pastikan data akurat sesuai tanggal bergabung
	if month > 0 && year > 0 {
		var employees []models.User
		database.DB.Where("role = ? AND company_id = ?", "EMPLOYEE", admin.CompanyID).Find(&employees)

		targetMonth := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local)

		for _, emp := range employees {
			joinMonth := time.Date(emp.CreatedAt.Year(), emp.CreatedAt.Month(), 1, 0, 0, 0, 0, time.Local)

			if targetMonth.Before(joinMonth) {
				// Hapus data sampah jika ada (Pembersihan Database)
				database.DB.Where("user_id = ? AND month = ? AND year = ?", emp.ID, month, year).Delete(&models.Salary{})
				continue
			}

			// Generate/Update data valid
			generateSalary(emp.ID, month, year)
		}
	}

	var salaries []models.Salary
	query := database.DB.Preload("User").Preload("User.Position").Preload("Payments").
		Joins("JOIN users ON users.id = salaries.user_id").
		Where("users.company_id = ?", admin.CompanyID)

	if month > 0 && year > 0 {
		periodEnd := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local).AddDate(0, 1, 0)
		query = query.Where("salaries.month = ? AND salaries.year = ? AND users.created_at < ?", month, year, periodEnd)
	} else {
		if month > 0 {
			query = query.Where("salaries.month = ?", month)
		}
		if year > 0 {
			query = query.Where("salaries.year = ?", year)
		}
	}

	// Filter by User
	userSubQuery := database.DB.Model(&models.User{}).Where("company_id = ?", admin.CompanyID)
	if positionID != "" {
		userSubQuery = userSubQuery.Where("position_id = ?", positionID)
	}
	if search != "" {
		userSubQuery = userSubQuery.Where("LOWER(name) LIKE LOWER(?)", "%"+search+"%")
	}

	var userIDs []string
	userSubQuery.Pluck("id", &userIDs)

	if len(userIDs) > 0 || (positionID == "" && search == "") {
		if positionID != "" || search != "" {
			query = query.Where("salaries.user_id IN ?", userIDs)
		}
		query.Order("year desc, month desc").Find(&salaries)
	} else {
		salaries = []models.Salary{}
	}

	utils.Success(c, "Berhasil mengambil data payroll", salaries)
}

// AdminPaySalary - Process payment (supports installments)
func AdminPaySalary(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	salaryID := c.Param("id")
	amountStr := c.PostForm("amount")

	var salary models.Salary
	if err := database.DB.Joins("JOIN users ON users.id = salaries.user_id").
		Where("salaries.id = ? AND users.company_id = ?", salaryID, admin.CompanyID).
		First(&salary).Error; err != nil {
		utils.Error(c, "Data gaji tidak ditemukan atau Anda tidak memiliki akses")
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
	var user models.User
	if err := database.DB.Preload("Position").First(&user, "id = ?", userID).Error; err != nil {
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
	deductions, bonuses, deductionDetails, bonusDetails := CalculateAdjustments(userID, month, year)

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

func CalculateAdjustments(userID string, month int, year int) (float64, float64, string, string) {
	var user models.User
	database.DB.First(&user, "id = ?", userID)

	var settingsList []models.AttendanceSettings
	database.DB.Where("company_id = ?", user.CompanyID).Limit(1).Find(&settingsList)
	var settings models.AttendanceSettings
	if len(settingsList) > 0 {
		settings = settingsList[0]
	}

	// Parse Tiers
	var tiers []LateTier
	if settings.LatePenaltyTiers != "" {
		json.Unmarshal([]byte(settings.LatePenaltyTiers), &tiers)
	}

	// Get Attendances for this month
	startDate := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local)
	endDate := startDate.AddDate(0, 1, 0)

	var attendances []models.Attendance
	database.DB.Where("user_id = ? AND date >= ? AND date < ?", userID, startDate.Format("2006-01-02"), endDate.Format("2006-01-02")).Find(&attendances)

	// Tentukan batas akhir pencarian (jangan melewati hari ini jika bulan berjalan)
	calculationEnd := endDate
	now := time.Now()
	if year == now.Year() && month == int(now.Month()) {
		calculationEnd = time.Date(now.Year(), now.Month(), now.Day()+1, 0, 0, 0, 0, now.Location()) 
		if calculationEnd.After(endDate) {
			calculationEnd = endDate
		}
	}

	// 1. Map record yang ada untuk lookup cepat
	existingRecords := make(map[string]models.Attendance)
	for _, att := range attendances {
		existingRecords[att.Date] = att
	}

	totalDeduction := 0.0
	totalBonus := 0.0
	deductionDetails := ""
	bonusDetails := ""

	// 2. Loop setiap tanggal dalam range bulan ini (Denda Absensi)
	for d := startDate; d.Before(calculationEnd); d = d.AddDate(0, 0, 1) {
		dateStr := d.Format("2006-01-02")
		
		if dateStr < user.CreatedAt.Format("2006-01-02") {
			continue
		}

		if att, exists := existingRecords[dateStr]; exists {
			checkInEnd := parseT(dateStr, settings.CheckInEnd, now.Location())
			lateDeduction := 0.0
			if att.CheckInTime != nil && att.CheckInTime.After(checkInEnd) {
				lateDeduction = calculateLatePenalty(*att.CheckInTime, checkInEnd, settings.LatePenalty, settings.LatePenaltyTiers)
			}

			earlyDeduction := 0.0
			isEarly := false
			if att.CheckInTime != nil {
				if att.CheckOutTime == nil {
					if dateStr < now.Format("2006-01-02") || (dateStr == now.Format("2006-01-02") && now.After(parseT(dateStr, settings.CheckOutEnd, now.Location()))) {
						isEarly = true
						earlyDeduction = settings.EarlyLeavePenalty
					}
				} else {
					if att.CheckOutTime.Before(parseT(dateStr, settings.CheckOutStart, now.Location())) {
						isEarly = true
						earlyDeduction = settings.EarlyLeavePenalty
					}
				}
			}

			if lateDeduction > 0 && isEarly {
				totalDeduction += lateDeduction + earlyDeduction
				deductionDetails += "Terlambat & Pulang di jam kerja pada " + formatDateIndo(dateStr) + " (" + utils.FormatRupiah(lateDeduction+earlyDeduction) + "); "
			} else if lateDeduction > 0 {
				totalDeduction += lateDeduction
				deductionDetails += "Terlambat pada " + formatDateIndo(dateStr) + " (" + utils.FormatRupiah(lateDeduction) + "); "
			} else if isEarly {
				totalDeduction += earlyDeduction
				deductionDetails += "Pulang di jam kerja pada " + formatDateIndo(dateStr) + " (" + utils.FormatRupiah(earlyDeduction) + "); "
			} else if att.SalaryDeduction > 0 && att.Status != "LATE" && att.Status != "EARLY_LEAVE" && att.Status != "LATE_EARLY_LEAVE" {
				totalDeduction += att.SalaryDeduction
				deductionDetails += att.Status + " pada " + formatDateIndo(dateStr) + " (" + utils.FormatRupiah(att.SalaryDeduction) + "); "
			}
		} else {
			isHold, _ := isHoliday(user.CompanyID, d)
			if !isHold {
				if dateStr == now.Format("2006-01-02") {
					loc := now.Location()
					checkOutEnd := parseT(dateStr, settings.CheckOutEnd, loc)
					if now.Before(checkOutEnd) {
						continue 
					}
				}

				if settings.AlphaPenalty > 0 {
					totalDeduction += settings.AlphaPenalty
					deductionDetails += "Alpha pada " + formatDateIndo(dateStr) + " (" + utils.FormatRupiah(settings.AlphaPenalty) + "); "
				}
			}
		}
	}

	// 3. Tambahkan Denda Manual (Non-Absensi)
	var manualPenalties []models.Penalty
	database.DB.Where("user_id = ? AND date LIKE ?", userID, fmt.Sprintf("%d-%02d-%%", year, month)).Find(&manualPenalties)

	for _, p := range manualPenalties {
		totalDeduction += p.Amount
		deductionDetails += p.Title + " (" + utils.FormatRupiah(p.Amount) + "); "
	}

	// 4. Tambahkan Bonus Manual [NEW]
	var bonuses []models.Bonus
	database.DB.Where("user_id = ? AND date LIKE ?", userID, fmt.Sprintf("%d-%02d-%%", year, month)).Find(&bonuses)

	for _, b := range bonuses {
		totalBonus += b.Amount
		bonusDetails += b.Title + " (" + utils.FormatRupiah(b.Amount) + "); "
	}

	return totalDeduction, totalBonus, deductionDetails, bonusDetails
}
