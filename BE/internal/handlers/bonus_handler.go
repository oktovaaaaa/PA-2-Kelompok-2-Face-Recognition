// internal/handlers/bonus_handler.go

package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
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

	bonus := models.Bonus{
		ID:          uuid.New().String(),
		UserID:      input.UserID,
		Title:       input.Title,
		Description: input.Description,
		Amount:      input.Amount,
		Date:        input.Date,
	}

	if err := database.DB.Create(&bonus).Error; err != nil {
		utils.Error(c, "Gagal mencatat bonus: "+err.Error())
		return
	}

	// Trigger sinkronisasi gaji untuk bulan tersebut
	t, _ := time.Parse("2006-01-02", input.Date)
	generateSalary(input.UserID, int(t.Month()), t.Year())

	// Kirim Notifikasi ke Karyawan
	notif := models.Notification{
		ID:        uuid.New().String(),
		UserID:    input.UserID,
		CompanyID: checkUser.CompanyID,
		Title:     "Bonus Baru!",
		Body:      fmt.Sprintf("Anda menerima bonus sebesar %s untuk: %s", utils.FormatRupiah(input.Amount), input.Title),
		Type:      "BONUS_RECEIVED",
		IsRead:    false,
		CreatedAt: time.Now(),
	}
	database.DB.Create(&notif)

	// Push Notification via FCM
	services.SendPushNotification(checkUser.ID, notif.Title, notif.Body)

	utils.Success(c, "Bonus berhasil dicatat dan notifikasi dikirim", bonus)
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

	// [FIX MICROSERVICES] 1. Ambil list user ID dari perusahan ini via Auth Service
	var employees []models.User
	authURL := fmt.Sprintf("http://localhost:8081/api/internal/users?company_id=%s", adminUser.CompanyID)
	if err := utils.CallInternalAPI(authURL, &employees); err != nil {
		utils.Error(c, "Gagal mengambil data karyawan")
		return
	}

	userMap := make(map[string]models.User)
	var userIDs []string
	for _, e := range employees {
		// Filter search di memori jika ada
		if search != "" {
			if !utils.CaseInsensitiveContains(e.Name, search) {
				continue
			}
		}
		userIDs = append(userIDs, e.ID)
		userMap[e.ID] = e
	}

	if len(userIDs) == 0 && search != "" {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": []models.Bonus{}, "total": 0})
		return
	}
	
	// Query utama untuk mengambil data Bonus lokal
	query := database.DB.Model(&models.Bonus{})
	if search != "" {
		query = query.Where("user_id IN (?) OR title ILIKE ?", userIDs, "%"+search+"%")
	} else {
		query = query.Where("user_id IN (?)", userIDs)
	}

	// 2. Tambahkan Filter Waktu
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

	// 3. HITUNG TOTAL
	var total int64
	query.Count(&total)

	// 4. AMBIL DATA DENGAN PAGINATION
	var bonuses []models.Bonus
	offset := (page - 1) * limit
	if err := query.Order("date DESC, created_at DESC").
		Limit(limit).Offset(offset).
		Find(&bonuses).Error; err != nil {
		utils.Error(c, "Gagal mengambil data bonus")
		return
	}

	// 5. Tempelkan data User ke hasil
	for i := range bonuses {
		if u, ok := userMap[bonuses[i].UserID]; ok {
			bonuses[i].User = u
		}
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
	
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	var bonus models.Bonus
	if err := database.DB.Where("id = ?", id).First(&bonus).Error; err != nil {
		utils.Error(c, "Data bonus tidak ditemukan")
		return
	}

	// [FIX MICROSERVICES] Verifikasi kepemilikan user via Auth Service
	var checkUser models.User
	authURL := fmt.Sprintf("http://localhost:8081/api/internal/users/single?id=%s", bonus.UserID)
	if err := utils.CallInternalAPI(authURL, &checkUser); err != nil || checkUser.CompanyID != admin.CompanyID {
		utils.Error(c, "Anda tidak memiliki akses ke data ini")
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

	// [FIX MICROSERVICES] Ambil user IDs dulu
	var employees []models.User
	authURL := fmt.Sprintf("http://localhost:8081/api/internal/users?company_id=%s", adminUser.CompanyID)
	utils.CallInternalAPI(authURL, &employees)

	var userIDs []string
	for _, e := range employees {
		userIDs = append(userIDs, e.ID)
	}

	var years []string
	if len(userIDs) > 0 {
		database.DB.Table("bonuses").
			Select("DISTINCT EXTRACT(YEAR FROM TO_DATE(bonuses.date, 'YYYY-MM-DD'))::text as year").
			Where("user_id IN (?)", userIDs).
			Order("year DESC").
			Scan(&years)
	}
	
	if len(years) == 0 {
		years = append(years, strconv.Itoa(time.Now().Year()))
	}

	utils.Success(c, "Berhasil mengambil daftar tahun", years)
}
