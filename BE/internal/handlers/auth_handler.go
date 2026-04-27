// internal/handlers/auth_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"

	"fmt"
	"github.com/gin-gonic/gin"
)

func RegisterAdmin(c *gin.Context) {

	var body struct {
		Name       string
		Email      string
		Password   string
		Pin        string
		Phone      string
		BirthPlace string
		BirthDate  string
		Address    string
		PhotoURL   string

		CompanyName    string
		CompanyAddress string
		CompanyEmail   string
		CompanyPhone   string

		GoogleIDToken string
		OTPCode       string
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Data tidak valid")
		return
	}

	user := models.User{
		Name:       body.Name,
		Email:      body.Email,
		Password:   body.Password,
		Pin:        body.Pin,
		Phone:      body.Phone,
		BirthPlace: body.BirthPlace,
		BirthDate:  body.BirthDate,
		Address:    body.Address,
		PhotoURL:   body.PhotoURL,
	}

	if body.GoogleIDToken != "" {
		payload, err := services.VerifyGoogleToken(body.GoogleIDToken)
		if err == nil {
			user.Email = payload.Claims["email"].(string)
			user.GoogleID = payload.Subject
		} else {
			utils.Error(c, "Token Google tidak valid: "+err.Error())
			return
		}
	} else {
		// Verifikasi OTP untuk pendaftaran email biasa
		if body.OTPCode == "" {
			utils.Error(c, "Kode OTP wajib diisi")
			return
		}
		if err := services.VerifyOTP(body.Email, body.OTPCode); err != nil {
			utils.Error(c, "Kode OTP tidak valid atau kedaluwarsa")
			return
		}
	}

	company := models.Company{
		Name:    body.CompanyName,
		Address: body.CompanyAddress,
		Email:   body.CompanyEmail,
		Phone:   body.CompanyPhone,
	}

	err := services.RegisterAdmin(user, company)

	if err != nil {

		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "Registrasi admin berhasil", nil)
}

func SendOTP(c *gin.Context) {

	var body struct {
		Email string
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Email tidak valid")
		return
	}

	code, err := services.GenerateOTP(body.Email)

	if err != nil {

		utils.Error(c, err.Error())
		return
	}

	services.SendOTPEmail(body.Email, code)

	utils.Success(c, "OTP berhasil dikirim", nil)
}

func VerifyOTP(c *gin.Context) {

	var body struct {
		Email string
		Code  string
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Data tidak valid")
		return
	}

	err := services.VerifyOTP(body.Email, body.Code)

	if err != nil {

		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "OTP valid", nil)
}

func Login(c *gin.Context) {

	var body struct {
		Email        string `json:"email"`
		Password     string `json:"password"`
		IsAdminPanel bool   `json:"isAdminPanel"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	err := services.Login(body.Email, body.Password)
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	// FETCH USER UNTUK CEK ROLE & STATUS PERUSAHAAN
	var user models.User
	if err := database.DB.Preload("Company").Where("email = ?", body.Email).First(&user).Error; err == nil {
		// Proteksi Perusahaan: Jika perusahaan nonaktif, blokir login (kecuali Super Admin)
		if user.Role != "SUPER_ADMIN" && user.Company.Status == "INACTIVE" {
			utils.Error(c, "Akses Diblokir: Perusahaan/Organisasi Anda telah dinonaktifkan oleh sistem.")
			return
		}
	}

	// PROTEKSI MULTI-LAPIS: Jika mencoba login ke Panel Admin, WAJIB ROLE ADMIN
	if body.IsAdminPanel {
		if user.Role != "ADMIN" && user.Role != "SUPER_ADMIN" {
			utils.Error(c, "Akses Ditolak: Akun Anda tidak diperbolehkan masuk ke Panel Admin.")
			return
		}
	}

	code, err := services.GenerateLoginOTP(body.Email)

	if err != nil {

		utils.Error(c, "Gagal membuat OTP")
		return
	}

	err = services.SendOTPEmail(body.Email, code)

	if err != nil {

		utils.Error(c, "Gagal mengirim OTP")
		return
	}

	utils.Success(c, "OTP login dikirim", nil)
}

func VerifyLoginOTP(c *gin.Context) {

	var body struct {
		Email    string `json:"email"`
		Code     string `json:"code"`
		DeviceID string `json:"device_id"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Data tidak valid")
		return
	}

	err := services.VerifyOTP(body.Email, body.Code)

	if err != nil {

		utils.Error(c, err.Error())
		return
	}

	var user models.User
	err = database.DB.Preload("Company").Where("LOWER(email) = LOWER(?)", body.Email).First(&user).Error
	if err != nil {
		utils.Error(c, "Data pengguna tidak ditemukan setelah verifikasi OTP")
		return
	}

	// Proteksi Perusahaan: Jika perusahaan nonaktif, blokir login (kecuali Super Admin)
	if user.Role != "SUPER_ADMIN" && user.Company.Status == "INACTIVE" {
		utils.Error(c, "Akses Diblokir: Perusahaan/Organisasi Anda telah dinonaktifkan oleh sistem.")
		return
	}

	fmt.Printf("[DEBUG] Login Attempt: %s | Role: %s | Status: %s\n", user.Email, user.Role, user.Status)

	if user.Status == "PENDING" {
		utils.Error(c, "Akun Anda masih dalam status menunggu persetujuan admin")
		return
	}
	if user.Status == "REJECTED" {
		utils.Error(c, "Akun Anda telah ditolak oleh admin")
		return
	}

	// Device Binding Logic (Hanya untuk KARYAWAN)
	if user.Role != "ADMIN" {
		if user.DeviceID != "" && user.DeviceID != body.DeviceID {
			utils.Error(c, "Akun ini sudah aktif di perangkat lain")
			return
		}

		if user.DeviceID == "" {
			user.DeviceID = body.DeviceID
			database.DB.Save(&user)
		}
	}

	token, _ := services.GenerateToken(user.ID, user.Role, user.CompanyID)

	utils.Success(c, "Login berhasil", gin.H{
		"token":     token,
		"userId":    user.ID,
		"email":     user.Email,
		"role":      user.Role,
		"companyId": user.CompanyID,
	})
}

func GoogleLogin(c *gin.Context) {

	var body struct {
		IDToken string `json:"id_token"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Token tidak valid")
		return
	}

	payload, err := services.VerifyGoogleToken(body.IDToken)

	if err != nil {
		utils.Error(c, "Token Google tidak valid: "+err.Error())
		return
	}

	email := payload.Claims["email"].(string)

	var user models.User
	err = database.DB.Preload("Company").Where("email = ?", email).First(&user).Error

	if err != nil {
		utils.Error(c, "Akun Google ini belum terdaftar di sistem")
		return
	}

	// Proteksi Perusahaan: Jika perusahaan nonaktif, blokir login (kecuali Super Admin)
	if user.Role != "SUPER_ADMIN" && user.Company.Status == "INACTIVE" {
		utils.Error(c, "Akses Diblokir: Perusahaan/Organisasi Anda telah dinonaktifkan oleh sistem.")
		return
	}

	if user.Status == "PENDING" {
		utils.Error(c, "Akun Anda masih dalam status menunggu persetujuan admin")
		return
	}
	if user.Status == "REJECTED" {
		utils.Error(c, "Akun Anda telah ditolak oleh admin")
		return
	}

	code, err := services.GenerateLoginOTP(email)

	if err != nil {
		utils.Error(c, "Gagal membuat OTP")
		return
	}

	err = services.SendOTPEmail(email, code)

	if err != nil {
		utils.Error(c, "Gagal mengirim OTP")
		return
	}

	utils.Success(c, "OTP login dikirim", nil)
}

// internal/handlers/auth_handler.go

func LoginPin(c *gin.Context) {

	var body struct {
		UserID   string `json:"userID"`
		Pin      string `json:"pin"`
		DeviceID string `json:"device_id"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Data tidak valid")
		return
	}

	user, err := services.LoginWithPin(body.UserID, body.Pin)

	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	// Fetch company to check status (if not preloaded by services)
	var company models.Company
	database.DB.Where("id = ?", user.CompanyID).First(&company)

	// Proteksi Perusahaan: Jika perusahaan nonaktif, blokir login (kecuali Super Admin)
	if user.Role != "SUPER_ADMIN" && company.Status == "INACTIVE" {
		utils.Error(c, "Akses Diblokir: Perusahaan/Organisasi Anda telah dinonaktifkan oleh sistem.")
		return
	}

	// Device Binding Logic (Hanya untuk KARYAWAN)
	if user.Role != "ADMIN" {
		if user.DeviceID != "" && user.DeviceID != body.DeviceID {
			utils.Error(c, "Akun ini sudah aktif di perangkat lain")
			return
		}

		if user.DeviceID == "" && body.DeviceID != "" {
			user.DeviceID = body.DeviceID
			database.DB.Save(&user)
		}
	}

	token, _ := services.GenerateToken(user.ID, user.Role, user.CompanyID)

	utils.Success(c, "Login berhasil", gin.H{
		"token": token,
	})
}

func ForgotPassword(c *gin.Context) {
	var body struct {
		Email string `json:"email"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Email tidak valid")
		return
	}

	code, err := services.GenerateResetOTP(body.Email)
	if err != nil {
		utils.Error(c, "Email tidak terdaftar atau gagal membuat OTP")
		return
	}

	err = services.SendOTPEmail(body.Email, code)
	if err != nil {
		utils.Error(c, "Gagal mengirim email reset")
		return
	}

	utils.Success(c, "OTP reset password telah dikirim", nil)
}

func ResetPassword(c *gin.Context) {
	var body struct {
		Email       string `json:"email"`
		Code        string `json:"code"`
		NewPassword string `json:"newPassword"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak lengkap")
		return
	}

	// Verify OTP
	err := services.VerifyOTP(body.Email, body.Code)
	if err != nil {
		utils.Error(c, "OTP tidak valid atau sudah kedaluwarsa")
		return
	}

	// Update Password
	err = services.ResetPassword(body.Email, body.NewPassword)
	if err != nil {
		utils.Error(c, "Gagal mereset password")
		return
	}

	utils.Success(c, "Password berhasil diperbarui", nil)
}

// GetInternalUsers - Endpoint internal untuk menyediakan data user ke service lain (Microservices)
func GetInternalUsers(c *gin.Context) {
	companyID := c.Query("company_id")
	if companyID == "" {
		c.JSON(400, gin.H{"error": "company_id required"})
		return
	}

	var users []models.User
	database.DB.Preload("Position").Where("company_id = ?", companyID).Find(&users)
	c.JSON(200, users)
}

// GetInternalUserByID - Endpoint internal untuk mengambil data 1 user spesifik
func GetInternalUserByID(c *gin.Context) {
	id := c.Query("id")
	var user models.User
	if err := database.DB.Preload("Position").First(&user, "id = ?", id).Error; err != nil {
		c.JSON(404, gin.H{"error": "user not found"})
		return
	}
	c.JSON(200, user)
}

// GetInternalAdmins - Endpoint internal untuk mengambil daftar admin di suatu perusahaan
func GetInternalAdmins(c *gin.Context) {
	companyID := c.Query("company_id")
	var admins []models.User
	database.DB.Where("company_id = ? AND role = ?", companyID, "ADMIN").Find(&admins)
	c.JSON(200, admins)
}
