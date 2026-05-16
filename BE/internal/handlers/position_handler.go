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
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		Name        string  `json:"name"`
		Salary      float64 `json:"salary"`
		Description string  `json:"description"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.Name == "" {
		utils.Error(c, "Data jabatan tidak valid")
		return
	}

	position := models.Position{
		ID:          uuid.New().String(),
		CompanyID:   adminUser.CompanyID,
		Name:        body.Name,
		Salary:      body.Salary,
		Description: body.Description,
	}
	if err := database.DB.Create(&position).Error; err != nil {
		utils.Error(c, "Gagal membuat jabatan")
		return
	}
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
	utils.Success(c, "Jabatan berhasil dihapus", nil)
}

// AssignPosition — assign jabatan ke karyawan
func AssignPosition(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		UserID     string `json:"user_id"`
		PositionID string `json:"position_id"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	// Validasi karyawan milik perusahaan ini
	var employee models.User
	if err := database.DB.Where("id = ? AND company_id = ?", body.UserID, adminUser.CompanyID).First(&employee).Error; err != nil {
		utils.Error(c, "Karyawan tidak ditemukan")
		return
	}

	// Validasi jabatan milik perusahaan ini (boleh kosong untuk unassign)
	if body.PositionID != "" {
		var position models.Position
		if err := database.DB.Where("id = ? AND company_id = ?", body.PositionID, adminUser.CompanyID).First(&position).Error; err != nil {
			utils.Error(c, "Jabatan tidak ditemukan")
			return
		}
	}

	if body.PositionID == "" {
		database.DB.Model(&employee).Update("position_id", nil)
	} else {
		database.DB.Model(&employee).Update("position_id", body.PositionID)
	}

	// Kirim Notifikasi
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

		// Simpan Notifikasi ke DB
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

		// Kirim Push Notification jika ada DeviceID
		if employee.DeviceID != "" {
			services.SendPushNotification(employee.ID, title, bodyText)
		}
	}()

	utils.Success(c, "Jabatan karyawan berhasil diperbarui", nil)
}
