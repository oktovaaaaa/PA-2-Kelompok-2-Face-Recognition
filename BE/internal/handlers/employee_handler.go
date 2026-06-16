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

	// periksa validitas format data pendaftaran yang dikirim frontend
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	// bersihkan email dari spasi kosong dan ubah ke huruf kecil semua
	cleanEmail := strings.ToLower(strings.TrimSpace(body.Email))

	// buat objek user baru dengan menyalin isian data dari frontend
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

	// jika mendaftar menggunakan tombol google sign-in, validasikan token google oauth
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
		// pastikan pengisian otp tidak kosong untuk pendaftaran email biasa
		if body.OTPCode == "" {
			utils.Error(c, "Kode OTP wajib diisi")
			return
		}
	}

	// jalankan proses registrasi karyawan di layanan employee service
	err := services.RegisterEmployee(user, body.InviteToken, body.FaceImages)

	if err != nil {
		utils.Error(c, err.Error())
		return
	}

	// verifikasi otp diletakkan di akhir agar kode otp tidak hangus jika registrasi wajah gagal
	if body.GoogleIDToken == "" {
		if err := services.VerifyOTP(cleanEmail, body.OTPCode); err != nil {
			utils.Error(c, err.Error())
			return
		}
	}

	// kembalikan status sukses pendaftaran ke frontend dengan tanda menunggu persetujuan admin
	utils.Success(c, "Registrasi karyawan berhasil, menunggu persetujuan admin", nil)
}
