// internal/handlers/profile_handler.go

package handlers

import (
	"bytes"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"

	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func GetMyProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var user models.User
	// [FIX] Tambahkan Preload("Position") agar data jabatan & gaji pokok otomatis terambil
	if err := database.DB.Preload("Company").Preload("Position").Where("id = ?", userID).First(&user).Error; err != nil {
		utils.Error(c, "Profil tidak ditemukan")
		return
	}

	type ProfileResponse struct {
		ID                      string     `json:"id"`
		Name                    string     `json:"name"`
		Email                   string     `json:"email"`
		Phone                   string     `json:"phone"`
		BirthPlace              string     `json:"birth_place"`
		BirthDate               string     `json:"birth_date"`
		Address                 string     `json:"address"`
		PhotoURL                string     `json:"photo_url"`
		Role                    string     `json:"role"`
		Status                  string     `json:"status"`
		PositionID              string     `json:"position_id"`
		PositionName            string     `json:"position_name"`
		Salary                  float64    `json:"salary"`
		CompanyID               string     `json:"company_id"`
		BankName                string     `json:"bank_name"`
		BankAccountNumber       string     `json:"bank_account_number"`
		FaceEmbeddingRegistered bool       `json:"face_embedding_registered"`
		FaceUpdatedAt           *time.Time `json:"face_updated_at"`
	}

	resp := ProfileResponse{
		ID:                      user.ID,
		Name:                    user.Name,
		Email:                   user.Email,
		Phone:                   user.Phone,
		BirthPlace:              user.BirthPlace,
		BirthDate:               user.BirthDate,
		Address:                 user.Address,
		PhotoURL:                user.PhotoURL,
		Role:                    user.Role,
		Status:                  user.Status,
		PositionID:              "",
		CompanyID:               user.CompanyID,
		BankName:                user.BankName,
		BankAccountNumber:       user.BankAccountNumber,
		FaceEmbeddingRegistered: user.FaceEmbedding != "",
		FaceUpdatedAt: func() *time.Time {
			if user.FaceUpdatedAt == nil {
				return nil
			}
			// Jika waktu update wajah terpaut sangat dekat (< 15 detik) dari pembuatan akun (CreatedAt),
			// itu adalah pendaftaran wajah awal bawaan registrasi, bukan pembaruan/reset wajah manual.
			// Kita return nil agar client/UI menampilkan status awal (-) dan tidak memicu cooldown.
			if user.FaceUpdatedAt.Sub(user.CreatedAt) < 15*time.Second {
				return nil
			}
			return user.FaceUpdatedAt
		}(),
	}

	if user.PositionID != nil {
		resp.PositionID = *user.PositionID
		// [FIX] Gunakan data dari hasil Preload agar lebih instan dan akurat
		resp.PositionName = user.Position.Name
		resp.Salary = user.Position.Salary

		// Fallback jika karena suatu alasan Preload gagal tapi ID ada
		if resp.PositionName == "" {
			var pos models.Position
			if err := database.DB.Where("id = ?", *user.PositionID).First(&pos).Error; err == nil {
				resp.PositionName = pos.Name
				resp.Salary = pos.Salary
			}
		}
	}

	utils.Success(c, "Profil berhasil dimuat", resp)
}

// UpdateMyProfile — edit data diri sendiri (admin & karyawan, wajib isi semua field)
func UpdateMyProfile(c *gin.Context) {
	// 1. dapatkan user dari token JWT yang terautentikasi
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	// 2. ikat data request body JSON
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

	// 3. cari user di database auth utama
	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "User tidak ditemukan di database")
		return
	}

	// 4. simpan perubahan data profil ke model
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

	// 5. simpan perubahan data profil ke database
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

	// Fetch full user record to avoid overwriting fields with empty values in DBs
	var fullUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&fullUser).Error; err == nil {
		go database.SyncUserToAttendance(fullUser)
		go database.SyncUserToPayroll(fullUser)
	} else {
		// FALLBACK: If user is missing from pa2_auth (e.g., stale mobile login), directly update fcm_token in pa2_attendance & pa2_payroll
		attDsn := fmt.Sprintf(
			"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
			os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
			"pa2_attendance", os.Getenv("DB_PORT"),
		)
		if attDB, err := gorm.Open(postgres.Open(attDsn), &gorm.Config{}); err == nil {
			attDB.Model(&models.User{}).Where("id = ?", user.ID).Update("fcm_token", body.FcmToken)
		}

		payDsn := fmt.Sprintf(
			"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
			os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
			"pa2_payroll", os.Getenv("DB_PORT"),
		)
		if payDB, err := gorm.Open(postgres.Open(payDsn), &gorm.Config{}); err == nil {
			payDB.Model(&models.User{}).Where("id = ?", user.ID).Update("fcm_token", body.FcmToken)
		}
	}

	utils.Success(c, "FCM token berhasil disimpan", nil)
}

// RequestProfileOTP ditrigger saat pengguna (sudah login) ingin mengubah data sensitif seperti password atau PIN di profil mereka.
// Flow:
// 1. FE mengirim request POST ke `/profile/request-otp` dengan membawa Bearer Token (sudah login).
// 2. BE mendeteksi ID user dari JWT context, mengambil data email lengkap dari database.
// 3. BE men-generate kode OTP verifikasi profil via services.GenerateOTP.
// 4. BE mengirimkan OTP tersebut ke email pengguna via services.SendOTPEmail.
// 5. Kode OTP ini wajib disertakan oleh FE saat memanggil API `/profile/change-password` atau `/profile/change-pin`.
func RequestProfileOTP(c *gin.Context) {
	// 1. Mengambil informasi user dari context JWT yang sedang aktif.
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	// 2. Mengambil data lengkap user dari DB berdasarkan ID untuk mendapatkan alamat email.
	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "User tidak ditemukan")
		return
	}

	// 3. Menghasilkan kode OTP baru berjenis umum di sistem untuk email user tersebut.
	code, err := services.GenerateOTP(dbUser.Email)
	if err != nil {
		utils.Error(c, "Gagal membuat OTP: "+err.Error())
		return
	}

	// 4. Memanggil email service untuk mengirimkan email OTP keamanan ke inbox user.
	services.SendOTPEmail(dbUser.Email, code)
	// 5. Mengembalikan response sukses ke aplikasi mobile (FE) untuk diarahkan ke halaman input OTP.
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

	// Ambil data lengkap user dari DB untuk mendapatkan hash password
	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "Akun tidak ditemukan")
		return
	}

	if !utils.CheckPassword(dbUser.Password, body.Password) {
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
	// 1. ambil user context dari JWT token yang terautentikasi
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	// 2. ikat data konfirmasi penghapusan akun dari request body
	var body struct {
		Password           string `json:"password"`
		ConfirmationPhrase string `json:"confirmation_phrase"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	// 3. validasi 1: cek apakah password lama diinputkan
	if body.Password == "" {
		utils.Error(c, "Password wajib diisi untuk menghapus akun")
		return
	}

	// 4. cari record data user terbaru di database
	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "Akun tidak ditemukan")
		return
	}

	// 5. validasi 2: pastikan password yang dimasukkan cocok dengan hash di database
	if !utils.CheckPassword(dbUser.Password, body.Password) {
		utils.Error(c, "Password salah, penghapusan akun dibatalkan")
		return
	}

	if strings.TrimSpace(dbUser.Name) == "" {
		utils.Error(c, "Nama akun tidak terdeteksi di database. Harap hubungi admin atau lengkapi profil Anda.")
		return
	}

	// 6. validasi 3: pastikan frasa konfirmasi yang diketik sesuai dengan nama pengguna
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

		// 1. Ambil list UserID yang berada di bawah CompanyID ini dari Auth DB
		var userIDs []string
		if err := database.DB.Model(&models.User{}).Where("company_id = ?", companyID).Pluck("id", &userIDs).Error; err != nil {
			utils.Error(c, "Gagal mengambil data karyawan instansi: "+err.Error())
			return
		}

		// 2. Koneksi ke database Payroll (pa2_payroll) untuk penghapusan data payroll
		dsnPay := fmt.Sprintf(
			"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
			os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
			"pa2_payroll", os.Getenv("DB_PORT"),
		)
		payDB, errPay := gorm.Open(postgres.Open(dsnPay), &gorm.Config{})
		if errPay != nil {
			utils.Error(c, "Gagal koneksi ke database payroll untuk penghapusan: "+errPay.Error())
			return
		}

		errPayTx := payDB.Transaction(func(txPay *gorm.DB) error {
			if len(userIDs) > 0 {
				// Hapus salary payments jika ada (harus dijalankan pertama karena constraint foreign key)
				if err := txPay.Exec("DELETE FROM salary_payments WHERE salary_id IN (SELECT id FROM salaries WHERE user_id IN (?))", userIDs).Error; err != nil {
					// Abaikan jika tabel tidak ada
				}
				if err := txPay.Where("user_id IN (?)", userIDs).Delete(&models.Salary{}).Error; err != nil {
					return fmt.Errorf("gagal menghapus salaries: %w", err)
				}
				if err := txPay.Where("user_id IN (?)", userIDs).Delete(&models.Bonus{}).Error; err != nil {
					return fmt.Errorf("gagal menghapus bonuses: %w", err)
				}
				if err := txPay.Where("user_id IN (?)", userIDs).Delete(&models.Penalty{}).Error; err != nil {
					return fmt.Errorf("gagal menghapus penalties: %w", err)
				}
			}
			if err := txPay.Where("company_id = ?", companyID).Unscoped().Delete(&models.User{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus users di payroll: %w", err)
			}
			return nil
		})
		if errPayTx != nil {
			utils.Error(c, "Gagal menghapus data di database payroll: "+errPayTx.Error())
			return
		}

		// 3. Koneksi ke database Attendance (pa2_attendance) untuk penghapusan data absensi
		dsnAtt := fmt.Sprintf(
			"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
			os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
			"pa2_attendance", os.Getenv("DB_PORT"),
		)
		attDB, errAtt := gorm.Open(postgres.Open(dsnAtt), &gorm.Config{})
		if errAtt != nil {
			utils.Error(c, "Gagal koneksi ke database absensi untuk penghapusan: "+errAtt.Error())
			return
		}

		errAttTx := attDB.Transaction(func(txAtt *gorm.DB) error {
			if len(userIDs) > 0 {
				if err := txAtt.Where("user_id IN (?)", userIDs).Delete(&models.Attendance{}).Error; err != nil {
					return fmt.Errorf("gagal menghapus attendances: %w", err)
				}
				if err := txAtt.Where("user_id IN (?)", userIDs).Delete(&models.LeaveRequest{}).Error; err != nil {
					return fmt.Errorf("gagal menghapus leave_requests: %w", err)
				}
			}
			if err := txAtt.Where("company_id = ?", companyID).Delete(&models.AttendanceSettings{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus attendance_settings: %w", err)
			}
			if err := txAtt.Where("company_id = ?", companyID).Delete(&models.CompanyLocation{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus company_locations: %w", err)
			}
			if err := txAtt.Where("company_id = ?", companyID).Delete(&models.Holiday{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus holidays: %w", err)
			}
			if err := txAtt.Where("company_id = ?", companyID).Unscoped().Delete(&models.User{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus users di attendance: %w", err)
			}
			return nil
		})
		if errAttTx != nil {
			utils.Error(c, "Gagal menghapus data di database absensi: "+errAttTx.Error())
			return
		}

		// 4. Terakhir, hapus data di database Auth utama (pa2_auth)
		errAuthTx := database.DB.Transaction(func(tx *gorm.DB) error {
			// Hapus semua User (Admin & semua Karyawannya) dari auth dulu karena positions & companies direferensikan oleh users
			if err := tx.Where("company_id = ?", companyID).Unscoped().Delete(&models.User{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus users: %w", err)
			}
			if err := tx.Where("company_id = ?", companyID).Delete(&models.Position{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus positions: %w", err)
			}
			if err := tx.Where("company_id = ?", companyID).Delete(&models.InviteToken{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus invite_tokens: %w", err)
			}
			if err := tx.Where("company_id = ?", companyID).Delete(&models.CompanyLocation{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus company_locations: %w", err)
			}
			if err := tx.Where("company_id = ?", companyID).Delete(&models.Notification{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus notifications: %w", err)
			}
			// Hapus Company itu sendiri (Hard Delete)
			if err := tx.Where("id = ?", companyID).Unscoped().Delete(&models.Company{}).Error; err != nil {
				return fmt.Errorf("gagal menghapus company: %w", err)
			}
			return nil
		})
		if errAuthTx != nil {
			utils.Error(c, "Gagal menghapus data di database auth: "+errAuthTx.Error())
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

		// Sync resigned status to other microservices databases
		go database.SyncUserToAttendance(dbUser)
		go database.SyncUserToPayroll(dbUser)

		// [NEW] Kirim notifikasi ke Admin bahwa karyawan resigned
		var admin models.User
		if err := database.DB.Where("company_id = ? AND role = ?", dbUser.CompanyID, "ADMIN").First(&admin).Error; err == nil {
			services.CreateNotification(admin.ID, dbUser.CompanyID, "Karyawan Resigned",
				dbUser.Name+" telah menghapus akun dan mengundurkan diri (Resigned).", "EMPLOYEE_RESIGNED", dbUser.ID)
			services.SendPushNotification(admin.ID, "Karyawan Resigned",
				dbUser.Name+" telah mengundurkan diri.")
		}
	}

	utils.Success(c, "Proses Resign dan Hapus Akun Berhasil", nil)
}

// UpdateFaceEmbedding — mendaftarkan atau mengganti data wajah (cooldown 30 hari)
func UpdateFaceEmbedding(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		FaceEmbedding string `json:"face_embedding"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.FaceEmbedding == "" {
		utils.Error(c, "Data wajah tidak valid")
		return
	}

	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "User tidak ditemukan")
		return
	}

	// Cek Cooldown 30 Hari (abaikan jika ini adalah pendaftaran wajah awal bawaan registrasi)
	if dbUser.FaceUpdatedAt != nil {
		isInitialRegistration := dbUser.FaceUpdatedAt.Sub(dbUser.CreatedAt) < 15*time.Second
		if !isInitialRegistration {
			daysPassed := int(time.Since(*dbUser.FaceUpdatedAt).Hours() / 24)
			if daysPassed < 30 {
				remaining := 30 - daysPassed
				utils.Error(c, fmt.Sprintf("Anda baru saja mengganti Face ID. Silakan tunggu %d hari lagi.", remaining))
				return
			}
		}
	}

	now := time.Now()
	dbUser.FaceEmbedding = body.FaceEmbedding
	dbUser.FaceUpdatedAt = &now

	if err := database.DB.Save(&dbUser).Error; err != nil {
		utils.Error(c, "Gagal menyimpan data wajah")
		return
	}

	// Sinkronisasi data user terupdate ke database mikroservis lainnya (Attendance & Payroll)
	go database.SyncUserToAttendance(dbUser)
	go database.SyncUserToPayroll(dbUser)

	utils.Success(c, "Face ID berhasil didaftarkan", nil)
}

func RegisterFace(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var in struct {
		Images []string `json:"images"`
	}
	if err := c.BindJSON(&in); err != nil {
		utils.Error(c, "Input tidak valid")
		return
	}
	if len(in.Images) == 0 {
		utils.Error(c, "Data wajah tidak lengkap")
		return
	}

	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "User tidak ditemukan")
		return
	}

	// Cek Cooldown 30 Hari (abaikan jika ini adalah pendaftaran wajah awal bawaan registrasi)
	if dbUser.FaceUpdatedAt != nil {
		isInitialRegistration := dbUser.FaceUpdatedAt.Sub(dbUser.CreatedAt) < 15*time.Second
		if !isInitialRegistration {
			daysPassed := int(time.Since(*dbUser.FaceUpdatedAt).Hours() / 24)
			if daysPassed < 30 {
				remaining := 30 - daysPassed
				utils.Error(c, fmt.Sprintf("Anda baru saja mengganti Face ID. Silakan tunggu %d hari lagi.", remaining))
				return
			}
		}
	}

	// [NEW] Use face service for processing
	embedding, err := services.ProcessFaceImages(in.Images)
	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	dbUser.FaceEmbedding = embedding
	now := time.Now()
	dbUser.FaceUpdatedAt = &now

	if err := database.DB.Save(&dbUser).Error; err != nil {
		utils.Error(c, "Gagal menyimpan data wajah")
		return
	}

	// Sinkronisasi data user terupdate ke database mikroservis lainnya (Attendance & Payroll)
	go database.SyncUserToAttendance(dbUser)
	go database.SyncUserToPayroll(dbUser)

	utils.Success(c, "Registrasi wajah berhasil", nil)
}

// UpdateBankInfo — khusus update data bank (karyawan sendiri)
func UpdateBankInfo(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		BankName          string `json:"bank_name"`
		BankAccountNumber string `json:"bank_account_number"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	if body.BankName == "" || body.BankAccountNumber == "" {
		utils.Error(c, "Nama Bank dan Nomor Rekening wajib diisi")
		return
	}

	var dbUser models.User
	if err := database.DB.Where("id = ?", user.ID).First(&dbUser).Error; err != nil {
		utils.Error(c, "User tidak ditemukan")
		return
	}

	dbUser.BankName = body.BankName
	dbUser.BankAccountNumber = body.BankAccountNumber

	if err := database.DB.Save(&dbUser).Error; err != nil {
		utils.Error(c, "Gagal memperbarui informasi bank")
		return
	}

	// Sinkronisasi data user terupdate ke database mikroservis lainnya (Attendance & Payroll)
	go database.SyncUserToAttendance(dbUser)
	go database.SyncUserToPayroll(dbUser)

	utils.Success(c, "Informasi bank berhasil diperbarui", nil)
}

// getEmbedding digunakan untuk verifikasi wajah tunggal (saat absen)
func getEmbedding(base64Image string) ([]float32, error) {
	imgData, err := base64.StdEncoding.DecodeString(base64Image)
	if err != nil {
		return nil, err
	}

	// Buat buffer untuk multipart form data
	var b bytes.Buffer
	w := multipart.NewWriter(&b)

	fw, err := w.CreateFormFile("files", "face_verify.jpg")
	if err != nil {
		return nil, fmt.Errorf("gagal membuat form file: %w", err)
	}
	if _, err := io.Copy(fw, bytes.NewReader(imgData)); err != nil {
		return nil, fmt.Errorf("gagal menulis data gambar ke form: %w", err)
	}
	w.Close()

	// Kirim request ke Python API
	client := &http.Client{Timeout: 30 * time.Second}
	req, err := http.NewRequest("POST", "http://localhost:5000/extract-embeddings", &b) //extract-embeddings
	if err != nil {
		return nil, fmt.Errorf("gagal membuat request HTTP ke AI engine: %w", err)
	}
	req.Header.Set("Content-Type", w.FormDataContentType())

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("gagal menghubungi AI Engine: %w. Pastikan Python service sudah berjalan.", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("AI Engine mengembalikan status error: %d, body: %s", resp.StatusCode, string(bodyBytes))
	}

	// Parse respon JSON
	var results []interface{}
	if err := json.NewDecoder(resp.Body).Decode(&results); err != nil {
		return nil, fmt.Errorf("gagal mengurai respon dari AI Engine: %w", err)
	}

	if len(results) == 0 {
		return nil, fmt.Errorf("wajah tidak terdeteksi")
	}

	// Hasil batch mode mengembalikan array of array
	if emb, ok := results[0].([]interface{}); ok {
		var floatEmb []float32
		for _, v := range emb {
			floatEmb = append(floatEmb, float32(v.(float64)))
		}
		return floatEmb, nil
	}

	// Jika Python mengembalikan error object di elemen pertama
	if errMap, ok := results[0].(map[string]interface{}); ok {
		if errMsg, exists := errMap["error"]; exists {
			return nil, fmt.Errorf("%v", errMsg)
		}
	}

	return nil, fmt.Errorf("gagal memproses embedding")
}
