package handlers

import (
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"

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
		FcmToken      string `json:"fcm_token"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {

		utils.Error(c, "Data tidak valid")
		return
	}

	user := models.User{
		Name:              body.Name,
		Email:             body.Email,
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
		if err := services.VerifyOTP(body.Email, body.OTPCode); err != nil {
			utils.Error(c, "Kode OTP tidak valid atau kedaluwarsa")
			return
		}
	}

	err := services.RegisterEmployee(user, body.InviteToken)

	if err != nil {

		utils.Error(c, err.Error())
		return
	}

	utils.Success(c, "Registrasi karyawan berhasil, menunggu persetujuan admin", nil)
}
