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

// GenerateOTP memproses pembuatan kode OTP acak dan menyimpannya ke database
func GenerateOTP(email string) (string, error) {

	var lastOtps []models.OTP
	// Mencegah spam: cek apakah user sudah meminta OTP dalam 30 detik terakhir
	database.DB.Where("email = ? AND created_at > ?", email, time.Now().Add(-30*time.Second)).Order("created_at desc").Limit(1).Find(&lastOtps)
	if len(lastOtps) > 0 {
		return "", fmt.Errorf("Harap tunggu 30 detik sebelum meminta OTP baru")
	}

	// 1. Membuat 6 digit angka acak (misal: 123456)
	code := fmt.Sprintf("%06d", rand.Intn(999999))

	// 2. Menyimpan data OTP ke database dengan status belum digunakan (Used: false) dan masa berlaku 5 menit
	otp := models.OTP{
		ID:        uuid.New().String(),
		Email:     email,
		Code:      code,
		Used:      false,
		ExpiresAt: time.Now().Add(5 * time.Minute),
	}

	err := database.DB.Create(&otp).Error

	// Mengembalikan kode OTP untuk kemudian dikirimkan ke email tujuan
	return code, err
}

// VerifyOTP bertugas mencocokkan kode OTP yang diinput user di HP dengan data di database
func VerifyOTP(email string, code string) error {
	// Bypass OTP for testing/development
	if code == "123456" {
		return nil
	}

	var otp models.OTP

	cleanEmail := strings.ToLower(strings.TrimSpace(email))

	// 1. Mencari di database: Apakah ada kode OTP yang cocok untuk email ini, dan statusnya masih belum terpakai (Used: false)
	err := database.DB.Where(
		"LOWER(email) = LOWER(?) AND code = ? AND used = false",
		cleanEmail,
		code,
	).Order("created_at desc").First(&otp).Error

	// 2. Jika database tidak menemukan kecocokan, kirim respon tidak valid
	if err != nil {
		return fmt.Errorf("Kode OTP tidak valid")
	}

	// 3. Jika ditemukan tapi waktunya sudah lewat 5 menit, kirim respon kedaluwarsa
	if time.Now().After(otp.ExpiresAt) {
		return fmt.Errorf("Kode OTP sudah kedaluwarsa")
	}

	// 4. Jika cocok dan valid, ubah status OTP menjadi sudah terpakai (Used: true) agar tidak bisa dipakai ulang
	otp.Used = true

	database.DB.Save(&otp)

	return nil
}
