// internal/handlers/position_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CreatePosition — admin membuat jabatan baru
func CreatePosition(c *gin.Context) {
	// 1. dapatkan user context admin dari middleware autentikasi
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	// 2. bind request body untuk data nama, gaji, dan deskripsi jabatan
	var body struct {
		Name        string  `json:"name"`
		Salary      float64 `json:"salary"`
		Description string  `json:"description"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.Name == "" {
		utils.Error(c, "Data jabatan tidak valid")
		return
	}

	// 3. buat objek model jabatan baru dengan generate id uuid baru
	position := models.Position{
		ID:          uuid.New().String(),
		CompanyID:   adminUser.CompanyID,
		Name:        body.Name,
		Salary:      body.Salary,
		Description: body.Description,
	}

	// 4. simpan data jabatan ke database utama
	if err := database.DB.Create(&position).Error; err != nil {
		utils.Error(c, "Gagal membuat jabatan")
		return
	}

	// 5. jalankan sinkronisasi data jabatan ke db absensi dan payroll secara async (goroutine)
	go func() {
		_ = database.SyncPositionToAttendance(position)
		_ = database.SyncPositionToPayroll(position)
	}()
	utils.Success(c, "Jabatan berhasil dibuat", position)
}

// GetPositions — list semua jabatan perusahaan
func GetPositions(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var positions []models.Position
	database.DB.Where("company_id = ? AND LOWER(name) NOT LIKE ? AND LOWER(name) NOT LIKE ?", adminUser.CompanyID, "%admin%", "%super admin%").Find(&positions)
	utils.Success(c, "Daftar jabatan", positions)
}

// UpdatePosition — edit nama/gaji jabatan
func UpdatePosition(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	var body struct {
		Name        string  `json:"name"`
		Salary      float64 `json:"salary"`
		Description string  `json:"description"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var position models.Position
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&position).Error; err != nil {
		utils.Error(c, "Jabatan tidak ditemukan")
		return
	}

	position.Name = body.Name
	position.Salary = body.Salary
	position.Description = body.Description
	database.DB.Save(&position)
	go func() {
		_ = database.SyncPositionToAttendance(position)
		_ = database.SyncPositionToPayroll(position)
	}()
	utils.Success(c, "Jabatan berhasil diperbarui", position)
}

// DeletePosition — hapus jabatan (hanya jika tidak ada karyawan di jabatan ini)
func DeletePosition(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")

	var position models.Position
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&position).Error; err != nil {
		utils.Error(c, "Jabatan tidak ditemukan")
		return
	}

	// Cek apakah ada karyawan dengan jabatan ini
	var count int64
	database.DB.Model(&models.User{}).Where("position_id = ? AND company_id = ?", id, adminUser.CompanyID).Count(&count)
	if count > 0 {
		utils.Error(c, "Jabatan masih digunakan oleh karyawan, tidak dapat dihapus")
		return
	}

	database.DB.Delete(&position)
	go func() {
		_ = database.DeletePositionToAttendance(id)
		_ = database.DeletePositionToPayroll(id)
	}()
	utils.Success(c, "Jabatan berhasil dihapus", nil)
}

// AssignPosition — assign jabatan ke karyawan
func AssignPosition(c *gin.Context) {
	// 1. dapatkan user context admin dari middleware autentikasi
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	// 2. bind request body untuk mendapatkan user_id karyawan dan position_id jabatan
	var body struct {
		UserID     string `json:"user_id"`
		PositionID string `json:"position_id"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	// 3. validasi bahwa karyawan yang akan diassign terdaftar di perusahaan admin tersebut
	var employee models.User
	if err := database.DB.Where("id = ? AND company_id = ?", body.UserID, adminUser.CompanyID).First(&employee).Error; err != nil {
		utils.Error(c, "Karyawan tidak ditemukan")
		return
	}

	// 4. validasi bahwa jabatan yang dipilih terdaftar di perusahaan admin tersebut
	if body.PositionID != "" {
		var position models.Position
		if err := database.DB.Where("id = ? AND company_id = ?", body.PositionID, adminUser.CompanyID).First(&position).Error; err != nil {
			utils.Error(c, "Jabatan tidak ditemukan")
			return
		}
	}

	// 5. perbarui data jabatan di tabel user karyawan (set nil jika position_id kosong)
	if body.PositionID == "" {
		database.DB.Model(&employee).Update("position_id", nil)
	} else {
		database.DB.Model(&employee).Update("position_id", body.PositionID)
	}

	// 6. buat dan kirim notifikasi secara async ke database dan firebase cloud messaging
	go func() {
		title := "Perubahan Jabatan"
		bodyText := "Posisi jabatan Anda telah diperbarui oleh Bos."
		if body.PositionID != "" {
			var pos models.Position
			if err := database.DB.Where("id = ?", body.PositionID).First(&pos).Error; err == nil {
				bodyText = fmt.Sprintf("Posisi jabatan Anda telah diperbarui menjadi %s.", pos.Name)
			}
		} else {
			bodyText = "Posisi jabatan Anda telah diberhentikan oleh Bos."
		}

		// 7. simpan riwayat notifikasi ke dalam tabel notifications
		notif := models.Notification{
			ID:        uuid.New().String(),
			UserID:    employee.ID,
			CompanyID: employee.CompanyID,
			Title:     title,
			Body:      bodyText,
			Type:      "POSITION_UPDATE",
			RefID:     body.PositionID,
			IsRead:    false,
			CreatedAt: time.Now(),
		}
		database.DB.Create(&notif)

		// 8. kirim push notification via firebase jika karyawan memiliki device id terdaftar
		if employee.DeviceID != "" {
			services.SendPushNotification(employee.ID, title, bodyText)
		}
	}()

	utils.Success(c, "Jabatan karyawan berhasil diperbarui", nil)
}
