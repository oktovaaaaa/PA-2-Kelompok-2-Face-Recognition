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
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CreatePenalty - Admin creates a new penalty for an employee
func CreatePenalty(c *gin.Context) {
	userID := c.PostForm("user_id")
	title := c.PostForm("title")
	description := c.PostForm("description")
	amountStr := c.PostForm("amount")
	penaltyType := c.PostForm("type")
	dateStr := c.PostForm("date")

	if userID == "" || title == "" || amountStr == "" {
		utils.Error(c, "Data tidak lengkap")
		return
	}

	amount, err := strconv.ParseFloat(amountStr, 64)
	if err != nil || amount <= 0 {
		utils.Error(c, "Nominal denda tidak valid")
		return
	}

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

	utils.Success(c, "Denda berhasil dicatatkan", penalty)
}

// GetPenalties - List penalties (Admin: All / Filtered, Employee: Only theirs)
func GetPenalties(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	query := database.DB.Preload("User").Preload("User.Position").Model(&models.Penalty{})

	// Search filter
	search := c.Query("search")
	if search != "" {
		query = query.Joins("JOIN users ON users.id = penalties.user_id").
			Where("LOWER(penalties.title) LIKE LOWER(?) OR LOWER(users.name) LIKE LOWER(?)", "%"+search+"%", "%"+search+"%")
	}

	// Admin filters: Only show penalties for users in the same company
	if user.Role == "ADMIN" {
		query = query.Where("penalties.user_id IN (SELECT id FROM users WHERE company_id = ?)", user.CompanyID)
		
		filterUserID := c.Query("user_id")
		if filterUserID != "" {
			query = query.Where("penalties.user_id = ?", filterUserID)
		}
	} else {
		// Employee only sees their own
		query = query.Where("penalties.user_id = ?", user.ID)
	}

	// Date filters
	filter := c.Query("filter")
	month := c.Query("month")
	year := c.Query("year")

	if filter != "" {
		switch filter {
		case "today":
			today := time.Now().Format("2006-01-02")
			query = query.Where("penalties.date = ?", today)
		case "week":
			start := getFilterStart("week")
			query = query.Where("penalties.date >= ?", start)
		case "month":
			if month != "" && year != "" {
				monthInt, _ := strconv.Atoi(month)
				query = query.Where("penalties.date LIKE ?", fmt.Sprintf("%s-%02d-%%", year, monthInt))
			} else {
				start := getFilterStart("month")
				query = query.Where("penalties.date >= ?", start)
			}
		case "year":
			if year != "" {
				query = query.Where("penalties.date LIKE ?", year+"-%%")
			} else {
				start := getFilterStart("year")
				query = query.Where("penalties.date >= ?", start)
			}
		}
	} else if month != "" && year != "" {
		monthInt, _ := strconv.Atoi(month)
		query = query.Where("penalties.date LIKE ?", fmt.Sprintf("%s-%02d-%%", year, monthInt))
	} else if year != "" {
		query = query.Where("penalties.date LIKE ?", year+"-%%")
	} else {
		// Default behavior
		start := getFilterStart("month")
		query = query.Where("penalties.date >= ?", start)
	}

	// Pagination
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	offset := (page - 1) * limit

	var total int64
	query.Model(&models.Penalty{}).Count(&total)

	var penalties []models.Penalty
	if err := query.Order("created_at DESC").Offset(offset).Limit(limit).Find(&penalties).Error; err != nil {
		utils.Error(c, "Gagal mengambil data denda: "+err.Error())
		return
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

	var penalty models.Penalty
	if err := database.DB.First(&penalty, "id = ?", id).Error; err != nil {
		utils.Error(c, "Data denda tidak ditemukan")
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

	var years []string
	// Mengambil 4 karakter pertama dari kolom date (YYYY)
	err := database.DB.Model(&models.Penalty{}).
		Where("user_id IN (SELECT id FROM users WHERE company_id = ?)", adminUser.CompanyID).
		Select("DISTINCT(SUBSTRING(date, 1, 4)) as year").
		Order("year desc").
		Pluck("year", &years).Error

	if err != nil {
		utils.Error(c, "Gagal mengambil daftar tahun: "+err.Error())
		return
	}

	utils.Success(c, "Berhasil mengambil daftar tahun", years)
}
