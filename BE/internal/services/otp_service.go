// internal / services otp+_service.go

package services

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
	"math/rand"
	"strings"
	"time"

	"github.com/google/uuid"
)

func GenerateOTP(email string) (string, error) {

	var lastOtps []models.OTP
	database.DB.Where("email = ? AND created_at > ?", email, time.Now().Add(-30*time.Second)).Order("created_at desc").Limit(1).Find(&lastOtps)
	if len(lastOtps) > 0 {
		return "", fmt.Errorf("Harap tunggu 30 detik sebelum meminta OTP baru")
	}


	code := fmt.Sprintf("%06d", rand.Intn(999999))

	otp := models.OTP{
		ID:        uuid.New().String(),
		Email:     email,
		Code:      code,
		Used:      false,
		ExpiresAt: time.Now().Add(5 * time.Minute),
	}

	err := database.DB.Create(&otp).Error

	return code, err
}

func VerifyOTP(email string, code string) error {

	var otp models.OTP

	cleanEmail := strings.ToLower(strings.TrimSpace(email))

	err := database.DB.Where(
		"LOWER(email) = LOWER(?) AND code = ? AND used = false",
		cleanEmail,
		code,
	).Order("created_at desc").First(&otp).Error

	if err != nil {
		return fmt.Errorf("Kode OTP tidak valid")
	}

	if time.Now().After(otp.ExpiresAt) {
		return fmt.Errorf("Kode OTP sudah kedaluwarsa")
	}

	otp.Used = true

	database.DB.Save(&otp)

	return nil
}
