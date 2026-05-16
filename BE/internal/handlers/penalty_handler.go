// internal/handlers/penalty_handler.go

package handlers

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CreatePenalty - Admin creates a new penalty for an employee
func CreatePenalty(c *gin.Context) {
	var input struct {
		UserID      string  `json:"user_id" binding:"required"`
		Title       string  `json:"title" binding:"required"`
		Description string  `json:"description"`
		Amount      float64 `json:"amount" binding:"required"`
		Type        string  `json:"type"`
		Date        string  `json:"date"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		utils.Error(c, "Data tidak lengkap atau format salah: "+err.Error())
		return
	}

	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	// [FIX MICROSERVICES] Verifikasi via Auth Service (Port 8081)
	var checkUser models.User
	authURL := fmt.Sprintf("http://localhost:8081/api/internal/users/single?id=%s", input.UserID)
	if err := utils.CallInternalAPI(authURL, &checkUser); err != nil {
		utils.Error(c, "Karyawan tidak ditemukan atau gangguan koneksi service")
		return
	}

	if checkUser.CompanyID != admin.CompanyID {
		utils.Error(c, "Karyawan tidak ditemukan di instansi Anda")
		return
	}

	userID := input.UserID
	title := input.Title
	description := input.Description
	amount := input.Amount
	penaltyType := input.Type
	dateStr := input.Date

	if dateStr == "" {
		dateStr = time.Now().Format("2006-01-02")
	}

	// Handle optional attachment photo
	file, err := c.FormFile("attachment")
	var attachmentPath string
	if err == nil {
		// Ensure directory exists
		uploadDir := "uploads/penalties"
		if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
			os.MkdirAll(uploadDir, 0755)
		}

		filename := uuid.New().String() + filepath.Ext(file.Filename)
		attachmentPath = "/" + uploadDir + "/" + filename
		if err := c.SaveUploadedFile(file, uploadDir+"/"+filename); err != nil {
			utils.Error(c, "Gagal menyimpan lampiran denda")
			return
		}
	}

	penalty := models.Penalty{
		ID:          uuid.New().String(),
		UserID:      userID,
		Title:       title,
		Description: description,
		Amount:      amount,
		Type:        penaltyType,
		Attachment:  attachmentPath,
		Date:        dateStr,
	}

	if err := database.DB.Create(&penalty).Error; err != nil {
		utils.Error(c, "Gagal membuat data denda: "+err.Error())
		return
	}

	// Trigger payroll recalculation for this month
	t, _ := time.Parse("2006-01-02", dateStr)
	generateSalary(userID, int(t.Month()), t.Year())

	// Kirim Notifikasi ke Karyawan
	notif := models.Notification{
		ID:        uuid.New().String(),
		UserID:    userID,
		CompanyID: checkUser.CompanyID,
		Title:     "Sanksi Baru",
		Body:      fmt.Sprintf("Anda telah dikenakan sanksi sebesar %s atas: %s.", utils.FormatRupiah(amount), title),
		Type:      "PENALTY_RECEIVED",
		IsRead:    false,
		CreatedAt: time.Now(),
	}
	database.DB.Create(&notif)

	// Push Notification via FCM
	services.SendPushNotification(checkUser.ID, notif.Title, notif.Body)

	utils.Success(c, "Denda berhasil dicatatkan dan notifikasi dikirim", penalty)
}

// GetPenalties - List penalties (Admin: All / Filtered, Employee: Only theirs)
func GetPenalties(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	// [FIX MICROSERVICES] Ambil data user via Auth Service
	var employees []models.User
	authURL := fmt.Sprintf("http://localhost:8081/api/internal/users?company_id=%s", user.CompanyID)
	utils.CallInternalAPI(authURL, &employees)

	userMap := make(map[string]models.User)
	var userIDs []string
	search := c.Query("search")

	for _, e := range employees {
		userIDs = append(userIDs, e.ID)
		userMap[e.ID] = e
	}

	query := database.DB.Model(&models.Penalty{})

	// Search filter
	if search != "" {
		// Cari penalty berdasarkan title atau user IDs yang match namanya
		var matchingUserIDs []string
		for _, e := range employees {
			if utils.CaseInsensitiveContains(e.Name, search) {
				matchingUserIDs = append(matchingUserIDs, e.ID)
			}
		}
		if len(matchingUserIDs) > 0 {
			query = query.Where("(LOWER(title) LIKE LOWER(?) OR user_id IN (?))", "%"+search+"%", matchingUserIDs)
		} else {
			query = query.Where("LOWER(title) LIKE LOWER(?)", "%"+search+"%")
		}
	}

	// Role filters
	if user.Role == "ADMIN" {
		query = query.Where("user_id IN (?)", userIDs)
		
		filterUserID := c.Query("user_id")
		if filterUserID != "" {
			query = query.Where("user_id = ?", filterUserID)
		}
	} else {
		// Employee only sees their own
		query = query.Where("user_id = ?", user.ID)
	}

	// Date filters
	filter := c.Query("filter")
	month := c.Query("month")
	year := c.Query("year")

	if filter != "" {
		switch filter {
		case "today":
			today := time.Now().Format("2006-01-02")
			query = query.Where("date = ?", today)
		case "week":
			start := getFilterStart("week")
			query = query.Where("date >= ?", start)
		case "month":
			if month != "" && year != "" {
				monthInt, _ := strconv.Atoi(month)
				query = query.Where("date LIKE ?", fmt.Sprintf("%s-%02d-%%", year, monthInt))
			} else {
				start := getFilterStart("month")
				query = query.Where("date >= ?", start)
			}
		case "year":
			if year != "" {
				query = query.Where("date LIKE ?", year+"-%%")
			} else {
				start := getFilterStart("year")
				query = query.Where("date >= ?", start)
			}
		}
	} else if month != "" && year != "" {
		monthInt, _ := strconv.Atoi(month)
		query = query.Where("date LIKE ?", fmt.Sprintf("%s-%02d-%%", year, monthInt))
	} else if year != "" {
		query = query.Where("date LIKE ?", year+"-%%")
	}

	// Pagination
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	var total int64
	query.Count(&total)

	var penalties []models.Penalty
	if err := query.Order("date DESC, created_at DESC").Offset(offset).Limit(limit).Find(&penalties).Error; err != nil {
		utils.Error(c, "Gagal mengambil data denda: "+err.Error())
		return
	}

	// Tempelkan data User ke hasil
	for i := range penalties {
		if u, ok := userMap[penalties[i].UserID]; ok {
			penalties[i].User = u
		}
	}

	utils.Success(c, "Data denda berhasil diambil", gin.H{
		"data":  penalties,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// DeletePenalty - Admin removes a penalty
func DeletePenalty(c *gin.Context) {
	id := c.Param("id")

	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	var penalty models.Penalty
	if err := database.DB.Where("id = ?", id).First(&penalty).Error; err != nil {
		utils.Error(c, "Data denda tidak ditemukan")
		return
	}

	// [FIX MICROSERVICES] Verifikasi via Auth Service
	var checkUser models.User
	authURL := fmt.Sprintf("http://localhost:8081/api/internal/users/single?id=%s", penalty.UserID)
	if err := utils.CallInternalAPI(authURL, &checkUser); err != nil || checkUser.CompanyID != admin.CompanyID {
		utils.Error(c, "Anda tidak memiliki akses ke data ini")
		return
	}

	// Store info for recalculation before deleting
	userID := penalty.UserID
	t, _ := time.Parse("2006-01-02", penalty.Date)

	if err := database.DB.Delete(&penalty).Error; err != nil {
		utils.Error(c, "Gagal menghapus data denda")
		return
	}

	// Trigger payroll recalculation
	generateSalary(userID, int(t.Month()), t.Year())

	utils.Success(c, "Denda berhasil dihapus", nil)
}

// AdminGetPenaltyYears - Mengambil daftar tahun unik yang memiliki data denda untuk filter dinamis
func AdminGetPenaltyYears(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	// [FIX MICROSERVICES] Ambil user IDs
	var employees []models.User
	authURL := fmt.Sprintf("http://localhost:8081/api/internal/users?company_id=%s", adminUser.CompanyID)
	utils.CallInternalAPI(authURL, &employees)

	var userIDs []string
	for _, e := range employees {
		userIDs = append(userIDs, e.ID)
	}

	var years []string
	if len(userIDs) > 0 {
		err := database.DB.Model(&models.Penalty{}).
			Where("user_id IN (?)", userIDs).
			Select("DISTINCT(SUBSTRING(date, 1, 4)) as year").
			Order("year desc").
			Pluck("year", &years).Error
		
		if err != nil {
			utils.Error(c, "Gagal mengambil daftar tahun: "+err.Error())
			return
		}
	}

	if len(years) == 0 {
		years = append(years, strconv.Itoa(time.Now().Year()))
	}

	utils.Success(c, "Berhasil mengambil daftar tahun", years)
}
