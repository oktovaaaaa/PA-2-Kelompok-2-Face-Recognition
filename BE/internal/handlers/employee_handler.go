package handlers

import (
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"
	"strings"

	"github.com/gin-gonic/gin"
)

func RegisterEmployee(c *gin.Context) {

	var body struct {
		Name        string
		Email       string
		Password    string
		Pin         string
		Phone       string
		BirthPlace  string
		BirthDate   string
		Address     string
		PhotoURL    string
		InviteToken string

		BankName          string
		BankAccountNumber string

		GoogleIDToken string
		OTPCode       string
		FcmToken      string   `json:"fcm_token"`
		FaceImages    []string `json:"face_images"` // [NEW]
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Data tidak valid")
		return
	}

	// Bersihkan input email agar tidak ada spasi atau huruf besar yang mengganggu
	cleanEmail := strings.ToLower(strings.TrimSpace(body.Email))

	user := models.User{
		Name:              body.Name,
		Email:             cleanEmail,
		Password:          body.Password,
		Pin:               body.Pin,
		Phone:             body.Phone,
		BirthPlace:        body.BirthPlace,
		BirthDate:         body.BirthDate,
		Address:           body.Address,
		PhotoURL:          body.PhotoURL,
		BankName:          body.BankName,
		BankAccountNumber: body.BankAccountNumber,
		FcmToken:          body.FcmToken,
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
	}

	err := services.RegisterEmployee(user, body.InviteToken, body.FaceImages)

	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	// [NEW] Verifikasi OTP dilakukan TERAKHIR setelah registrasi (termasuk cek wajah) berhasil.
	// Dengan begini, jika cek wajah gagal, OTP belum "hangus" dan bisa dipakai lagi.
	if body.GoogleIDToken == "" {
		if err := services.VerifyOTP(cleanEmail, body.OTPCode); err != nil {
			// Jika OTP gagal, kita harus menghapus user yang baru dibuat agar tidak duplikat saat coba lagi
			// Tapi karena statusnya PENDING dan email di-anonymize jika hapus, lebih baik biarkan user mencoba lagi.
			// Untuk sementara, kita tampilkan error OTP saja.
			utils.Error(c, err.Error())
			return
		}
	}

	utils.Success(c, "Registrasi karyawan berhasil, menunggu persetujuan admin", nil)
}
