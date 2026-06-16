package services

import (
	"errors"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/google/uuid"
)

func RegisterEmployee(user models.User, inviteToken string, faceImages []string) error {

	var invite models.InviteToken

	// 1. cari token barcode undangan di database
	err := database.DB.Where("token = ?", inviteToken).First(&invite).Error

	if err != nil {
		return errors.New("Barcode tidak valid")
	}

	// 2. pastikan token undangan belum pernah digunakan sebelumnya
	if invite.Status == "USED" {
		return errors.New("Barcode sudah pernah digunakan")
	}

	// 3. pastikan waktu kedaluwarsa token undangan belum lewat
	if time.Now().After(invite.ExpiresAt) {
		invite.Status = "EXPIRED"
		database.DB.Save(&invite)
		return errors.New("Barcode sudah kedaluwarsa")
	}

	// 4. pastikan email calon karyawan belum terdaftar di database
	var existing models.User
	database.DB.Where("email = ?", user.Email).First(&existing)
	if existing.ID != "" {
		return errors.New("Email sudah terdaftar")
	}

	// 5. enkripsi password dan pin yang didaftarkan
	hashPassword, _ := utils.HashPassword(user.Password)
	hashPin, _ := utils.HashPin(user.Pin)

	// 6. set status awal akun karyawan menjadi PENDING agar tidak langsung aktif
	user.ID = uuid.New().String()
	user.CompanyID = invite.CompanyID
	user.Password = hashPassword
	user.Pin = hashPin
	user.Status = "PENDING"
	user.Role = "EMPLOYEE"

	// 7. proses ekstraksi wajah karyawan jika ada foto yang diunggah
	if len(faceImages) > 0 {
		embedding, err := ProcessFaceImages(faceImages)
		if err != nil {
			return errors.New("Gagal mendaftarkan wajah: " + err.Error())
		}
		user.FaceEmbedding = embedding
		user.FaceUpdatedAt = nil
	}

	// 8. simpan data akun karyawan baru ke database utama (auth)
	err = database.DB.Create(&user).Error

	if err != nil {
		return err
	}

	// 9. sinkronisasi data akun pending ini ke database attendance (absensi) secara asinkron
	go database.SyncUserToAttendance(user)

	// 10. ubah status token undangan menjadi USED (terpakai) agar tidak bisa disalahgunakan lagi
	invite.Status = "USED"
	database.DB.Save(&invite)

	// 11. cari admin perusahaan, lalu kirim push notification & notifikasi in-app
	var admin models.User
	if err := database.DB.Where("company_id = ? AND role = ?", invite.CompanyID, "ADMIN").First(&admin).Error; err == nil {
		// simpan notifikasi in-app ke database
		CreateNotification(admin.ID, invite.CompanyID, "Pendaftaran Karyawan Baru", 
			user.Name + " telah mendaftar dan sedang menunggu persetujuan Anda.", "EMPLOYEE_REGISTERED", user.ID)
		// kirimkan push notification firebase cloud messaging ke hp admin
		SendPushNotification(admin.ID, "Pendaftaran Karyawan Baru", 
			user.Name + " telah mendaftar. Mohon periksa daftar karyawan yang menunggu persetujuan.")
	}

	return nil
}
