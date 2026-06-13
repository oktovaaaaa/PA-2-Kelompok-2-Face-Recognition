// internal/handlers/wifi_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GetCompanyWifis — admin mendapatkan semua Wi-Fi terdaftar di perusahaan
func GetCompanyWifis(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	wifis := []models.CompanyWifi{}
	database.DB.Where("company_id = ?", admin.CompanyID).Order("created_at desc").Find(&wifis)

	utils.Success(c, "Daftar Wi-Fi absensi", wifis)
}

// GetActiveCompanyWifis — karyawan mendapatkan daftar Wi-Fi aktif
func GetActiveCompanyWifis(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	wifis := []models.CompanyWifi{}
	database.DB.Where("company_id = ? AND is_active = ?", emp.CompanyID, true).Find(&wifis)

	utils.Success(c, "Daftar Wi-Fi absensi aktif", wifis)
}

// CreateCompanyWifi — admin mendaftarkan Wi-Fi baru
func CreateCompanyWifi(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	var body struct {
		LocationID string `json:"location_id"`
		Name       string `json:"name" binding:"required"`
		BSSID      string `json:"bssid" binding:"required"`
		IsActive   *bool  `json:"is_active"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "SSID (name) dan BSSID (MAC Address) wajib diisi")
		return
	}

	isActiveVal := true
	if body.IsActive != nil {
		isActiveVal = *body.IsActive
	}

	var locPtr *string
	if body.LocationID != "" {
		locPtr = &body.LocationID
	}

	wifi := models.CompanyWifi{
		ID:         uuid.New().String(),
		CompanyID:  admin.CompanyID,
		LocationID: locPtr,
		Name:       body.Name,
		BSSID:      body.BSSID,
		IsActive:   isActiveVal,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}

	if err := database.DB.Create(&wifi).Error; err != nil {
		utils.Error(c, "Gagal menambahkan Wi-Fi: "+err.Error())
		return
	}

	utils.Success(c, "Wi-Fi berhasil ditambahkan", wifi)
}

// UpdateCompanyWifi — admin mengubah data Wi-Fi terdaftar
func UpdateCompanyWifi(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)
	id := c.Param("id")

	var wifi models.CompanyWifi
	if err := database.DB.Where("id = ? AND company_id = ?", id, admin.CompanyID).First(&wifi).Error; err != nil {
		utils.Error(c, "Data Wi-Fi tidak ditemukan")
		return
	}

	var body struct {
		LocationID string `json:"location_id"`
		Name       string `json:"name"`
		BSSID      string `json:"bssid"`
		IsActive   *bool  `json:"is_active"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Format data tidak valid")
		return
	}

	if body.Name != "" {
		wifi.Name = body.Name
	}
	if body.BSSID != "" {
		wifi.BSSID = body.BSSID
	}
	
	var locPtr *string
	if body.LocationID != "" {
		locPtr = &body.LocationID
	}
	wifi.LocationID = locPtr // Boleh dikosongkan

	if body.IsActive != nil {
		wifi.IsActive = *body.IsActive
	}
	wifi.UpdatedAt = time.Now()

	if err := database.DB.Save(&wifi).Error; err != nil {
		utils.Error(c, "Gagal memperbarui data Wi-Fi")
		return
	}

	utils.Success(c, "Data Wi-Fi berhasil diperbarui", wifi)
}

// DeleteCompanyWifi — admin menghapus Wi-Fi terdaftar
func DeleteCompanyWifi(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)
	id := c.Param("id")

	if err := database.DB.Where("id = ? AND company_id = ?", id, admin.CompanyID).Delete(&models.CompanyWifi{}).Error; err != nil {
		utils.Error(c, "Gagal menghapus data Wi-Fi")
		return
	}

	utils.Success(c, "Wi-Fi berhasil dihapus", nil)
}
