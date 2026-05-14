package handlers

import (
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

func GenerateInvite(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	invite, err := services.GenerateInvite(adminUser.CompanyID)

	if err != nil {

		utils.Error(c, "Gagal membuat invite token")
		return
	}

	qr, _ := services.GenerateQRCode(invite.Token)

	utils.Success(c, "Invite berhasil dibuat", gin.H{
		"token": invite.Token,
		"qr":    qr,
	})
}

func ValidateInvite(c *gin.Context) {

	var body struct {
		Token string
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Token tidak valid")
		return
	}

	var invite models.InviteToken

	err := database.DB.Preload("Company").Where("token = ?", body.Token).First(&invite).Error

	if err != nil {

		utils.Error(c, "Barcode tidak valid")
		return
	}

	if invite.Status == "USED" {

		utils.Error(c, "Barcode sudah pernah digunakan")
		return
	}

	if time.Now().After(invite.ExpiresAt) {

		invite.Status = "EXPIRED"
		database.DB.Save(&invite)
		utils.Error(c, "Barcode sudah kedaluwarsa")
		return
	}

	utils.Success(c, "Token valid", gin.H{
		"company_id":   invite.CompanyID,
		"company_name": invite.Company.Name,
	});
}

// utk admin melihat pending employee
func GetPendingEmployees(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var employees []models.User

	database.DB.Where("status = ? AND company_id = ?", "PENDING", adminUser.CompanyID).Find(&employees)

	utils.Success(c, "Daftar karyawan pending", employees)
}

// utk admin bisa approve employee
func ApproveEmployee(c *gin.Context) {

	var body struct {
		UserID string `json:"user_id"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Data tidak valid")
		return
	}

	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var user models.User

	err := database.DB.Where("id = ? AND company_id = ?", body.UserID, adminUser.CompanyID).First(&user).Error

	if err != nil {

		utils.Error(c, "User tidak ditemukan atau bukan bagian dari perusahaan")
		return
	}

	user.Status = "ACTIVE"
	database.DB.Save(&user)

	// Kirim Notifikasi ke Karyawan
	services.CreateNotification(user.ID, user.CompanyID, "Akun Disetujui",
		"Selamat! Akun Anda telah disetujui oleh admin. Anda sekarang bisa mengakses seluruh fitur aplikasi.", "EMPLOYEE_APPROVED", user.ID)
	services.SendPushNotification(user.ID, "Akun Disetujui", "Akun Anda telah aktif. Silakan masuk kembali.")

	utils.Success(c, "Karyawan berhasil diapprove", nil)
}

// fungsi rejecrt
func RejectEmployee(c *gin.Context) {

	var body struct {
		UserID string `json:"user_id"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Data tidak valid")
		return
	}

	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var user models.User

	err := database.DB.Where("id = ? AND company_id = ?", body.UserID, adminUser.CompanyID).First(&user).Error

	if err != nil {

		utils.Error(c, "User tidak ditemukan atau bukan bagian dari perusahaan")
		return
	}

	// Hapus User secara Permanen (Hard Delete) agar email/phone bisa digunakan kembali
	if err := database.DB.Delete(&user).Error; err != nil {
		utils.Error(c, "Gagal menghapus data karyawan yang ditolak")
		return
	}

	utils.Success(c, "Pendaftaran karyawan telah ditolak dan data dihapus", nil)
}

func GetAllUsers(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var users []models.User

	database.DB.Where("company_id = ?", adminUser.CompanyID).Find(&users)

	utils.Success(c, "Daftar user", users)
}

func UpdateCompanySettings(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		Name    string
		Address string
		Email   string
		Phone   string
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var company models.Company
	if err := database.DB.Where("id = ?", adminUser.CompanyID).First(&company).Error; err != nil {
		utils.Error(c, "Perusahaan tidak ditemukan")
		return
	}

	company.Name = body.Name
	company.Address = body.Address
	company.Email = body.Email
	company.Phone = body.Phone

	database.DB.Save(&company)

	utils.Success(c, "Data perusahaan berhasil diperbarui", company)
}

func GetCompanySettings(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var company models.Company
	if err := database.DB.Where("id = ?", adminUser.CompanyID).First(&company).Error; err != nil {
		utils.Error(c, "Perusahaan tidak ditemukan")
		return
	}

	utils.Success(c, "Data perusahaan", company)
}

// ResetDeviceBinding clears the device_id for a user so they can re-login after reinstalling the app
func ResetDeviceBinding(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		UserID string `json:"user_id"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var user models.User
	err := database.DB.Where("id = ? AND company_id = ?", body.UserID, adminUser.CompanyID).First(&user).Error
	if err != nil {
		utils.Error(c, "User tidak ditemukan atau bukan bagian dari perusahaan")
		return
	}

	user.DeviceID = ""
	database.DB.Save(&user)

	utils.Success(c, "Device binding berhasil direset", nil)
}
