// internal/handlers/profile_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"
	"fmt"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func GetMyProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	
	var user models.User
	if err := database.DB.Preload("Company").Where("id = ?", userID).First(&user).Error; err != nil {
		utils.Error(c, "Profil tidak ditemukan")
		return
	}

	type ProfileResponse struct {
		ID                string  `json:"id"`
		Name              string  `json:"name"`
		Email             string  `json:"email"`
		Phone             string  `json:"phone"`
		BirthPlace        string  `json:"birth_place"`
		BirthDate         string  `json:"birth_date"`
		Address           string  `json:"address"`
		PhotoURL          string  `json:"photo_url"`
		Role              string  `json:"role"`
		Status            string  `json:"status"`
		PositionID        string  `json:"position_id"`
		PositionName      string  `json:"position_name"`
		Salary            float64 `json:"salary"`
		CompanyID         string  `json:"company_id"`
		BankName          string  `json:"bank_name"`
		BankAccountNumber string  `json:"bank_account_number"`
	}

	resp := ProfileResponse{
		ID:                user.ID,
		Name:              user.Name,
		Email:             user.Email,
		Phone:             user.Phone,
		BirthPlace:        user.BirthPlace,
		BirthDate:         user.BirthDate,
		Address:           user.Address,
		PhotoURL:          user.PhotoURL,
		Role:              user.Role,
		Status:            user.Status,
		PositionID:        "",
		CompanyID:         user.CompanyID,
		BankName:          user.BankName,
		BankAccountNumber: user.BankAccountNumber,
	}

	if user.PositionID != nil {
		resp.PositionID = *user.PositionID
		var pos models.Position
		if err := database.DB.Where("id = ?", *user.PositionID).First(&pos).Error; err == nil {
			resp.PositionName = pos.Name
			resp.Salary = pos.Salary
		}
	}

	utils.Success(c, "Profil berhasil dimuat", resp)
}

// UpdateMyProfile — edit data diri sendiri (admin & karyawan, wajib isi semua field)
func UpdateMyProfile(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		Name              string `json:"name"`
		Phone             string `json:"phone"`
		BirthPlace        string `json:"birth_place"`
		BirthDate         string `json:"birth_date"`
		Address           string `json:"address"`
		PhotoURL          string `json:"photo_url"`
		BankName          string `json:"bank_name"`
		BankAccountNumber string `json:"bank_account_number"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}
	if body.Name == "" {
		utils.Error(c, "Nama lengkap wajib diisi")
		return
	}
	if body.Phone == "" {
		utils.Error(c, "Nomor telepon wajib diisi")
		return
	}
	// Opsional: Alamat bisa dikosongkan untuk Super Admin atau jika memang belum ada


	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "User tidak ditemukan di database")
		return
	}

	dbUser.Name = body.Name
	dbUser.Phone = body.Phone
	dbUser.BirthPlace = body.BirthPlace
	dbUser.BirthDate = body.BirthDate
	dbUser.Address = body.Address
	if body.PhotoURL != "" {
		dbUser.PhotoURL = body.PhotoURL
	}
	dbUser.BankName = body.BankName
	dbUser.BankAccountNumber = body.BankAccountNumber

	database.DB.Save(&dbUser)
	utils.Success(c, "Profil berhasil diperbarui", gin.H{
		"name":                dbUser.Name,
		"phone":               dbUser.Phone,
		"birth_place":         dbUser.BirthPlace,
		"birth_date":          dbUser.BirthDate,
		"address":             dbUser.Address,
		"photo_url":           dbUser.PhotoURL,
		"bank_name":           dbUser.BankName,
		"bank_account_number": dbUser.BankAccountNumber,
	})
}

// UpdateFcmToken — simpan FCM token karyawan/admin agar bisa terima push notification
func UpdateFcmToken(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		FcmToken string `json:"fcm_token"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.FcmToken == "" {
		utils.Error(c, "FCM token tidak valid")
		return
	}

	database.DB.Model(&models.User{}).Where("id = ?", user.ID).Update("fcm_token", body.FcmToken)
	utils.Success(c, "FCM token berhasil disimpan", nil)
}

// RequestProfileOTP — kirim OTP ke email user yang sedang login untuk verifikasi ubah password/pin
func RequestProfileOTP(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	// Ambil data lengkap user dari DB untuk mendapatkan Email
	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "User tidak ditemukan")
		return
	}

	code, err := services.GenerateOTP(dbUser.Email)
	if err != nil {
		utils.Error(c, "Gagal membuat OTP: "+err.Error())
		return
	}

	services.SendOTPEmail(dbUser.Email, code)
	utils.Success(c, "OTP berhasil dikirim ke email Anda", nil)
}

// ChangePassword — ubah password sendiri (verifikasi Password Lama ATAU OTP)
func ChangePassword(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	// Ambil data lengkap user dari DB
	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "User tidak ditemukan")
		return
	}

	var body struct {
		OldPassword string `json:"old_password"`
		OtpCode     string `json:"otp_code"`
		NewPassword string `json:"new_password"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	if body.NewPassword == "" {
		utils.Error(c, "Password baru wajib diisi")
		return
	}

	// 1. Verifikasi Identitas (Wajib PIN Lama + OTP)
	if body.OldPassword == "" || body.OtpCode == "" {
		utils.Error(c, "Harap masukkan password lama DAN kode OTP untuk verifikasi")
		return
	}

	// Cek Password Lama
	if !utils.CheckPassword(dbUser.Password, body.OldPassword) {
		utils.Error(c, "Password lama salah")
		return
	}

	// Cek OTP
	if err := services.VerifyOTP(dbUser.Email, body.OtpCode); err != nil {
		utils.Error(c, "Kode OTP tidak valid atau kedaluwarsa")
		return
	}

	// 2. Update Password Baru
	hash, _ := utils.HashPassword(body.NewPassword)
	if err := database.DB.Model(&models.User{}).Where("id = ?", user.ID).Update("password", hash).Error; err != nil {
		utils.Error(c, "Gagal memperbarui password")
		return
	}

	utils.Success(c, "Password berhasil diperbarui", nil)
}

// VerifyPassword — hanya verifikasi apakah password yang dimasukkan benar
func VerifyPassword(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		Password string `json:"password"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	if !utils.CheckPassword(user.Password, body.Password) {
		utils.Error(c, "Password yang Anda masukkan salah")
		return
	}

	utils.Success(c, "Password sesuai", nil)
}

// ChangePin — ubah PIN sendiri (verifikasi PIN Lama ATAU OTP)
func ChangePin(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	// Ambil data lengkap user dari DB
	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "User tidak ditemukan")
		return
	}

	var body struct {
		OldPin  string `json:"old_pin"`
		OtpCode string `json:"otp_code"`
		NewPin  string `json:"new_pin"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	if body.NewPin == "" || len(body.NewPin) != 6 {
		utils.Error(c, "PIN baru harus 6 digit angka")
		return
	}

	// 1. Verifikasi Identitas (Wajib PIN Lama + OTP)
	if body.OldPin == "" || body.OtpCode == "" {
		utils.Error(c, "Harap masukkan PIN lama DAN kode OTP untuk verifikasi")
		return
	}

	// Cek PIN Lama
	if !utils.CheckPin(dbUser.Pin, body.OldPin) {
		utils.Error(c, "PIN lama salah")
		return
	}

	// Cek OTP
	if err := services.VerifyOTP(dbUser.Email, body.OtpCode); err != nil {
		utils.Error(c, "Kode OTP tidak valid atau kedaluwarsa")
		return
	}

	// 2. Update PIN Baru
	hash, _ := utils.HashPin(body.NewPin)
	if err := database.DB.Model(&models.User{}).Where("id = ?", user.ID).Update("pin", hash).Error; err != nil {
		utils.Error(c, "Gagal memperbarui PIN")
		return
	}

	utils.Success(c, "PIN berhasil diperbarui", nil)
}

// DeleteAccount — hapus akun sendiri secara permanen (3 lapis keamanan)
func DeleteAccount(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		Password           string `json:"password"`
		ConfirmationPhrase string `json:"confirmation_phrase"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	// Validasi 1: Cek password
	if body.Password == "" {
		utils.Error(c, "Password wajib diisi untuk menghapus akun")
		return
	}

	// Ambil user terbaru dari database
	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "Akun tidak ditemukan")
		return
	}

	if !utils.CheckPassword(dbUser.Password, body.Password) {
		utils.Error(c, "Password salah, penghapusan akun dibatalkan")
		return
	}

	// Validasi tambahan: Nama user harus ada agar frasa bisa dibuat
	if strings.TrimSpace(dbUser.Name) == "" {
		utils.Error(c, "Nama akun tidak terdeteksi di database. Harap hubungi admin atau lengkapi profil Anda.")
		return
	}

	// Validasi 2: Cek frasa konfirmasi
	expectedPhrase := fmt.Sprintf("SAYA YAKIN MENGHAPUS AKUN %s", strings.ToUpper(dbUser.Name))
	if body.ConfirmationPhrase != expectedPhrase {
		utils.Error(c, fmt.Sprintf("Frasa konfirmasi tidak sesuai. Ketik \"%s\" untuk melanjutkan", expectedPhrase))
		return
	}

	// Hapus data berdasarkan role
	// Notifikasi selalu dihapus
	database.DB.Where("user_id = ?", user.ID).Delete(&models.Notification{})

	if dbUser.Role == "ADMIN" {
		// Admin: Hapus TOTAL semua data instansi (Cascade Delete manual)
		companyID := dbUser.CompanyID

		err := database.DB.Transaction(func(tx *gorm.DB) error {
			// 1. Hapus data transaksional yang terikat UserID (Absensi, Denda, Gaji, Bonus, dll)
			userIDsSubQuery := tx.Model(&models.User{}).Select("id").Where("company_id = ?", companyID)

			if err := tx.Where("user_id IN (?)", userIDsSubQuery).Delete(&models.Attendance{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus attendances: %w", err)
			}
			if err := tx.Where("user_id IN (?)", userIDsSubQuery).Delete(&models.Penalty{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus penalties: %w", err)
			}
			if err := tx.Where("user_id IN (?)", userIDsSubQuery).Delete(&models.LeaveRequest{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus leave_requests: %w", err)
			}
			if err := tx.Where("user_id IN (?)", userIDsSubQuery).Delete(&models.Salary{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus salaries: %w", err)
			}
			if err := tx.Where("user_id IN (?)", userIDsSubQuery).Delete(&models.Bonus{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus bonuses: %w", err)
			}

			// 2. Hapus semua User (Admin & semua Karyawannya)
			// Menggunakan Unscoped() agar data benar-benar terhapus fisik (Hard Delete)
			if err := tx.Where("company_id = ?", companyID).Unscoped().Delete(&models.User{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus users: %w", err)
			}

			// 3. Hapus data master yang terikat CompanyID (Lokasi, Pengaturan, Hari Libur, dll)
			if err := tx.Where("company_id = ?", companyID).Delete(&models.Notification{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus notifications: %w", err)
			}
			if err := tx.Where("company_id = ?", companyID).Delete(&models.AttendanceSettings{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus attendance_settings: %w", err)
			}
			if err := tx.Where("company_id = ?", companyID).Delete(&models.CompanyLocation{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus company_locations: %w", err)
			}
			if err := tx.Where("company_id = ?", companyID).Delete(&models.Holiday{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus holidays: %w", err)
			}
			if err := tx.Where("company_id = ?", companyID).Delete(&models.InviteToken{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus invite_tokens: %w", err)
			}
			if err := tx.Where("company_id = ?", companyID).Delete(&models.Position{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus positions: %w", err)
			}

			// 4. Terakhir, hapus data Company itu sendiri (Hard Delete)
			if err := tx.Where("id = ?", companyID).Unscoped().Delete(&models.Company{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus company: %w", err)
			}

			return nil
		})

		if err != nil {
			utils.Error(c, "Gagal menghapus total data instansi: "+err.Error())
			return
		}
	} else {
		// Karyawan: Soft Delete (Anonymization) untuk menjaga riwayat (absensi, denda, gaji)
		timestamp := time.Now().Unix()
		dbUser.Status = "RESIGNED"
		dbUser.DeviceID = ""
		dbUser.FcmToken = ""
		dbUser.Password = "" // Kosongkan password agar tidak bisa login sama sekali

		// Lepaskan email dan phone (Email Release)
		dbUser.Email = fmt.Sprintf("%s_DELETED_%d", dbUser.Email, timestamp)
		if dbUser.Phone != "" {
			dbUser.Phone = fmt.Sprintf("%s_DELETED_%d", dbUser.Phone, timestamp)
		}

		if err := database.DB.Save(&dbUser).Error; err != nil {
			utils.Error(c, "Gagal memproses penghapusan akun: "+err.Error())
			return
		}
	}

	utils.Success(c, "Proses Resign dan Hapus Akun Berhasil", nil)
}
