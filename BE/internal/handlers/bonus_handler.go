// internal/handlers/bonus_handler.go

package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AdminCreateBonus - Catat bonus manual untuk karyawan
func AdminCreateBonus(c *gin.Context) {
	var input struct {
		UserID      string  `json:"user_id" binding:"required"`
		Title       string  `json:"title" binding:"required"`
		Description string  `json:"description"`
		Amount      float64 `json:"amount" binding:"required"`
		Date        string  `json:"date" binding:"required"` // YYYY-MM-DD
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		utils.Error(c, "Input tidak valid: "+err.Error())
		return
	}

	bonus := models.Bonus{
		ID:          uuid.New().String(),
		UserID:      input.UserID,
		Title:       input.Title,
		Description: input.Description,
		Amount:      input.Amount,
		Date:        input.Date,
	}

	if err := database.DB.Create(&bonus).Error; err != nil {
		utils.Error(c, "Gagal mencatat bonus")
		return
	}

	// Trigger sinkronisasi gaji untuk bulan tersebut
	t, _ := time.Parse("2006-01-02", input.Date)
	generateSalary(input.UserID, int(t.Month()), t.Year())

	utils.Success(c, "Bonus berhasil dicatat", bonus)
}

// AdminGetBonuses - Ambil riwayat bonus dengan filter
func AdminGetBonuses(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	month := c.Query("month")
	year := c.Query("year")
	search := c.Query("search")

	// 1. Definisikan filter dasar (Security filter berdasarkan company_id)
	// Kita gunakan subquery agar lebih stabil dan tidak konflik dengan kolom di tabel Bonus
	userIDSQuery := database.DB.Model(&models.User{}).Select("id").Where("company_id = ?", adminUser.CompanyID)
	
	// Query utama untuk mengambil data
	query := database.DB.Model(&models.Bonus{}).Where("user_id IN (?)", userIDSQuery)

	// 2. Tambahkan Filter Pencarian & Waktu
	if year != "" {
		if month != "" && month != "0" {
			mInt, _ := strconv.Atoi(month)
			query = query.Where("date LIKE ?", fmt.Sprintf("%s-%02d-%%", year, mInt))
		} else {
			query = query.Where("date LIKE ?", year+"-%")
		}
	} else if month != "" && month != "0" {
		mInt, _ := strconv.Atoi(month)
		query = query.Where("date LIKE ?", fmt.Sprintf("%%-%02d-%%", mInt))
	}

	if search != "" {
		// Cari bonus berdasarkan nama user atau judul bonus
		searchUserQuery := database.DB.Model(&models.User{}).Select("id").Where("name ILIKE ?", "%"+search+"%")
		query = query.Where("(user_id IN (?) OR title ILIKE ?)", searchUserQuery, "%"+search+"%")
	}

	// 3. HITUNG TOTAL (Gunakan instance baru agar tidak mengganggu query utama)
	var total int64
	// Kita buat query baru khusus untuk count agar tidak tercemar pagination
	countQuery := database.DB.Model(&models.Bonus{}).Where("user_id IN (?)", userIDSQuery)
	// Apply filters yang sama ke countQuery
	if year != "" || month != "" {
		// (Ulangi filter waktu singkat untuk countQuery)
		if year != "" {
			if month != "" && month != "0" {
				mInt, _ := strconv.Atoi(month)
				countQuery = countQuery.Where("date LIKE ?", fmt.Sprintf("%s-%02d-%%", year, mInt))
			} else {
				countQuery = countQuery.Where("date LIKE ?", year+"-%")
			}
		} else {
			mInt, _ := strconv.Atoi(month)
			countQuery = countQuery.Where("date LIKE ?", fmt.Sprintf("%%-%02d-%%", mInt))
		}
	}
	if search != "" {
		searchUserQuery := database.DB.Model(&models.User{}).Select("id").Where("name ILIKE ?", "%"+search+"%")
		countQuery = countQuery.Where("(user_id IN (?) OR title ILIKE ?)", searchUserQuery, "%"+search+"%")
	}
	countQuery.Count(&total)

	// 4. AMBIL DATA DENGAN PAGINATION
	var bonuses []models.Bonus
	offset := (page - 1) * limit
	if err := query.Preload("User").
		Order("date DESC, created_at DESC").
		Limit(limit).Offset(offset).
		Find(&bonuses).Error; err != nil {
		utils.Error(c, "Gagal mengambil data bonus")
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    bonuses,
		"total":   total,
	})
}

// AdminDeleteBonus - Hapus catatan bonus
func AdminDeleteBonus(c *gin.Context) {
	id := c.Param("id")
	
	var bonus models.Bonus
	if err := database.DB.First(&bonus, "id = ?", id).Error; err != nil {
		utils.Error(c, "Data bonus tidak ditemukan")
		return
	}

	if err := database.DB.Delete(&bonus).Error; err != nil {
		utils.Error(c, "Gagal menghapus bonus")
		return
	}

	// Sinkronisasi gaji setelah penghapusan
	t, _ := time.Parse("2006-01-02", bonus.Date)
	generateSalary(bonus.UserID, int(t.Month()), t.Year())

	utils.Success(c, "Bonus berhasil dihapus", nil)
}

// AdminGetBonusYears - Ambil daftar tahun yang tersedia di data bonus
func AdminGetBonusYears(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var years []string
	database.DB.Table("bonuses").
		Select("DISTINCT EXTRACT(YEAR FROM TO_DATE(bonuses.date, 'YYYY-MM-DD'))::text as year").
		Joins("JOIN users ON users.id = bonuses.user_id").
		Where("users.company_id = ?", adminUser.CompanyID).
		Order("year DESC").
		Scan(&years)
	
	if len(years) == 0 {
		years = append(years, strconv.Itoa(time.Now().Year()))
	}

	utils.Success(c, "Berhasil mengambil daftar tahun", years)
}
