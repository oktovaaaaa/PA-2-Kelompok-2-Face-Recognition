// internal/handlers/auth_handler.go

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

// SendOTP ditrigger ketika user meminta OTP untuk registrasi baru atau login (melalui form login/register).
// Flow:
// 1. FE (Flutter/NextJS) mengirim request POST ke `/auth/send-otp` dengan payload `email`, `isAdminPanel`, dan `type` (LOGIN/REGISTER).
// 2. Handler memvalidasi status akun di database (apakah email sudah terdaftar atau belum).
// 3. Jika validasi lolos, sistem men-generate kode OTP baru menggunakan services.GenerateOTP.
// 4. Sistem kemudian mengirim email berisi kode OTP tersebut melalui services.SendOTPEmail.
func SendOTP(c *gin.Context) {
	var body struct {
		Email        string `json:"email"`
		IsAdminPanel bool   `json:"isAdminPanel"`
		Type         string `json:"type"` // "LOGIN" or "REGISTER"
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Email tidak valid")
		return
	}

	var user models.User
	userExists := true
	if err := database.DB.Where("email = ?", body.Email).First(&user).Error; err != nil {
		userExists = false
	}

	if body.Type == "LOGIN" {
		if !userExists {
			utils.Error(c, "Akun tidak terdaftar")
			return
		}
		if body.IsAdminPanel {
			if user.Role != "ADMIN" && user.Role != "SUPER_ADMIN" && user.Role != "OWNER" {
				utils.Error(c, "Akses Ditolak: Akun Anda tidak memiliki hak akses administrator.")
				return
			}
		}
	} else if body.Type == "REGISTER" {
		if userExists {
			utils.Error(c, "Email sudah terdaftar")
			return
		}
	} else {
		// Backward compatibility
		if body.IsAdminPanel {
			if userExists {
				if user.Role != "ADMIN" && user.Role != "SUPER_ADMIN" && user.Role != "OWNER" {
					utils.Error(c, "Akses Ditolak: Akun Anda tidak memiliki hak akses administrator.")
					return
				}
			}
		}
	}

	// 1. Menghasilkan kode OTP unik baru di DB/sistem untuk email yang bersangkutan.
	code, err := services.GenerateOTP(body.Email)
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	// 2. Memanggil email service untuk mengirimkan email OTP kepada user.
	services.SendOTPEmail(body.Email, code)
	// 3. Memberitahukan klien (FE) bahwa OTP sukses terkirim.
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

// Login ditrigger saat pengguna memasukkan email & password di halaman login (Step 1).
// Flow:
// 1. FE mengirim request POST ke `/auth/login` dengan payload `email`, `password`, dan `isAdminPanel`.
// 2. Sistem memverifikasi kecocokan password.
// 3. Jika cocok, sistem men-generate kode OTP login via services.GenerateLoginOTP.
// 4. Sistem mengirim OTP ini ke email pengguna menggunakan goroutine asinkron (tidak memblokir respon login).
// 5. Setelah respon sukses diterima oleh FE, halaman akan beralih ke form OTP untuk input kode verifikasi (Step 2).
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
		if user.Role != "ADMIN" && user.Role != "SUPER_ADMIN" && user.Role != "OWNER" {
			utils.Error(c, "Akses Ditolak: Akun Anda tidak diperbolehkan masuk ke Panel Admin.")
			return
		}
	}

	// 1. Menghasilkan kode OTP baru khusus untuk keperluan verifikasi Login (Step 1 sukses).
	code, err := services.GenerateLoginOTP(body.Email)

	if err != nil {

		utils.Error(c, "Gagal membuat OTP")
		return
	}

	// 2. Menjalankan pengiriman email secara asinkron (goroutine) agar respon HTTP tidak tertunda oleh proses SMTP.
	go func() {
		// 3. Memanggil email service untuk mengirimkan kode OTP login.
		if err := services.SendOTPEmail(body.Email, code); err != nil {
			fmt.Printf("[ERROR] Failed to send Login OTP: %v\n", err)
		}
	}()

	// 4. Mengembalikan respon sukses ke FE agar FE dapat menampilkan form input OTP (Step 2).
	utils.Success(c, "OTP login dikirim", nil)
}

func VerifyLoginOTP(c *gin.Context) {

	var body struct {
		Email      string `json:"email"`
		Code       string `json:"code"`
		DeviceID   string `json:"device_id"`
		DeviceName string `json:"device_name"`
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
	if user.Role != "ADMIN" && user.Role != "SUPER_ADMIN" && user.Role != "OWNER" {
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

	// Record Session ONLY for ADMIN or SUPER_ADMIN
	if user.Role == "ADMIN" || user.Role == "SUPER_ADMIN" {
		var session models.Session
		exists := false
		if body.DeviceID != "" {
			if err := database.DB.Where("user_id = ? AND device_id = ?", user.ID, body.DeviceID).First(&session).Error; err == nil {
				exists = true
			}
		}

		if exists {
			session.Token = token
			session.LastActiveAt = time.Now()
			session.ExpiresAt = time.Now().Add(24 * time.Hour)
			database.DB.Save(&session)
		} else {
			session = models.Session{
				ID:           uuid.New().String(),
				UserID:       user.ID,
				Token:        token,
				DeviceID:     body.DeviceID,
				DeviceName:   body.DeviceName,
				IsLocked:     false,
				LastActiveAt: time.Now(),
				ExpiresAt:    time.Now().Add(24 * time.Hour),
				CreatedAt:    time.Now(),
			}
			database.DB.Create(&session)
		}
	}

	utils.Success(c, "Login berhasil", gin.H{
		"token":     token,
		"userId":    user.ID,
		"email":     user.Email,
		"role":      user.Role,
		"companyId": user.CompanyID,
	})
}

// GoogleLogin ditrigger saat pengguna login menggunakan OAuth Google.
// Flow:
// 1. FE memverifikasi kredensial Google, mendapatkan ID Token, dan mengirimkannya ke `/auth/google-login`.
// 2. BE memverifikasi validitas token tersebut dan mencocokkan email Google dengan database.
// 3. Jika email terdaftar, BE men-generate kode OTP login tambahan untuk keamanan ganda.
// 4. OTP dikirim ke email tujuan via services.SendOTPEmail secara asinkron.
func GoogleLogin(c *gin.Context) {
	var body struct {
		IDToken      string `json:"id_token"`
		IsAdminPanel bool   `json:"isAdminPanel"`
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

	// Proteksi Admin Panel
	if body.IsAdminPanel {
		if user.Role != "ADMIN" && user.Role != "SUPER_ADMIN" && user.Role != "OWNER" {
			utils.Error(c, "Akses Ditolak: Akun Anda tidak diperbolehkan masuk ke Panel Admin.")
			return
		}
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

	// 1. Menghasilkan kode OTP login khusus untuk email akun Google yang sukses divalidasi.
	code, err := services.GenerateLoginOTP(email)

	if err != nil {
		utils.Error(c, "Gagal membuat OTP")
		return
	}

	// 2. Mengirimkan email OTP secara asinkron menggunakan goroutine.
	go func() {
		// 3. Memproses pengiriman SMTP lewat email service.
		if err := services.SendOTPEmail(email, code); err != nil {
			fmt.Printf("[ERROR] Failed to send Google Login OTP: %v\n", err)
		}
	}()

	// 4. Memberikan respon sukses ke FE agar melangkah ke form input OTP.
	utils.Success(c, "OTP login dikirim", nil)
}

// internal/handlers/auth_handler.go

func LoginPin(c *gin.Context) {

	var body struct {
		UserID     string `json:"userID"`
		Pin        string `json:"pin"`
		DeviceID   string `json:"device_id"`
		DeviceName string `json:"device_name"`
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
	if user.Role != "ADMIN" && user.Role != "SUPER_ADMIN" && user.Role != "OWNER" {
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

	// Record Session ONLY for ADMIN or SUPER_ADMIN
	if user.Role == "ADMIN" || user.Role == "SUPER_ADMIN" {
		var session models.Session
		exists := false
		if body.DeviceID != "" {
			if err := database.DB.Where("user_id = ? AND device_id = ?", user.ID, body.DeviceID).First(&session).Error; err == nil {
				exists = true
			}
		}

		if exists {
			session.Token = token
			session.LastActiveAt = time.Now()
			session.ExpiresAt = time.Now().Add(24 * time.Hour)
			database.DB.Save(&session)
		} else {
			session = models.Session{
				ID:           uuid.New().String(),
				UserID:       user.ID,
				Token:        token,
				DeviceID:     body.DeviceID,
				DeviceName:   body.DeviceName,
				IsLocked:     false,
				LastActiveAt: time.Now(),
				ExpiresAt:    time.Now().Add(24 * time.Hour),
				CreatedAt:    time.Now(),
			}
			database.DB.Create(&session)
		}
	}

	utils.Success(c, "Login berhasil", gin.H{
		"token": token,
	})
}

// ForgotPassword ditrigger saat pengguna mengklik "Lupa Password" dan memasukkan email mereka.
// Flow:
// 1. FE mengirim request POST ke `/auth/forgot-password` dengan payload `email` dan `isAdminPanel`.
// 2. BE memeriksa apakah email terdaftar dan memiliki akses yang sesuai.
// 3. BE menghasilkan kode OTP khusus reset password menggunakan services.GenerateResetOTP.
// 4. BE mengirimkan OTP tersebut ke email pengguna secara asinkron melalui services.SendOTPEmail.
// 5. FE mengarahkan pengguna ke halaman reset password untuk memasukkan kode OTP beserta password baru.
func ForgotPassword(c *gin.Context) {
	var body struct {
		Email        string `json:"email"`
		IsAdminPanel bool   `json:"isAdminPanel"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Email tidak valid")
		return
	}

	// Cek Role jika dari Admin Panel
	if body.IsAdminPanel {
		var user models.User
		if err := database.DB.Where("email = ?", body.Email).First(&user).Error; err == nil {
			if user.Role != "ADMIN" && user.Role != "SUPER_ADMIN" && user.Role != "OWNER" {
				utils.Error(c, "Akses Ditolak: Anda tidak dapat mereset sandi dari sini.")
				return
			}
		} else {
			// User tidak ditemukan
			utils.Error(c, "Email tidak terdaftar")
			return
		}
	}

	// 1. Menghasilkan kode OTP baru yang khusus berjenis Reset Password di DB/sistem.
	code, err := services.GenerateResetOTP(body.Email)
	if err != nil {
		utils.Error(c, "Email tidak terdaftar atau gagal membuat OTP")
		return
	}

	// 2. Memicu pengiriman email secara asinkron (goroutine) supaya API response cepat.
	go func() {
		// 3. Mengirim email berisi link/kode OTP reset password ke inbox user.
		if err := services.SendOTPEmail(body.Email, code); err != nil {
			fmt.Printf("[ERROR] Failed to send Forgot Password OTP: %v\n", err)
		}
	}()

	// 4. Memberitahukan FE bahwa kode OTP reset telah berhasil dikirim ke alamat email terkait.
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

// GetInternalUserCount - Endpoint internal untuk menghitung jumlah user dengan filter tertentu
func GetInternalUserCount(c *gin.Context) {
	companyID := c.Query("company_id")
	status := c.Query("status")
	role := c.Query("role")

	query := database.DB.Model(&models.User{}).Where("company_id = ?", companyID)
	if status != "" {
		query = query.Where("status = ?", status)
	}
	if role != "" {
		query = query.Where("role = ?", role)
	}

	var count int64
	query.Count(&count)

	c.JSON(200, gin.H{"count": count})
}
// CreateInternalNotification - Endpoint internal untuk membuat notifikasi dari service lain
func CreateInternalNotification(c *gin.Context) {
	var body struct {
		UserID    string `json:"user_id"`
		CompanyID string `json:"company_id"`
		Title     string `json:"title"`
		Body      string `json:"body"`
		Type      string `json:"type"`
		RefID     string `json:"ref_id"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(400, gin.H{"error": "invalid body"})
		return
	}

	notif := models.Notification{
		ID:        uuid.New().String(),
		UserID:    body.UserID,
		CompanyID: body.CompanyID,
		Title:     body.Title,
		Body:      body.Body,
		Type:      body.Type,
		RefID:     body.RefID,
		IsRead:    false,
		CreatedAt: time.Now(),
	}

	if err := database.DB.Create(&notif).Error; err != nil {
		c.JSON(500, gin.H{"error": "failed to create notification"})
		return
	}

	c.JSON(200, gin.H{"message": "notification created"})
}
