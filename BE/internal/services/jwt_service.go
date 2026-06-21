// internal / services / jwt_services.go

package services

import (
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// GenerateToken membuat token autentikasi yang dibubuhi tanda tangan digital agar aman
func GenerateToken(userID, role, companyID string) (string, error) {

	claims := jwt.MapClaims{
		"user_id":    userID,
		"role":       role,
		"company_id": companyID,
		"exp":        time.Now().Add(24 * time.Hour).Unix(),
	}

	// Menginisialisasi token dengan algoritma tanda tangan digital HMAC-SHA256 (HS256)
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Membuat string token akhir yang ditandatangani secara digital menggunakan kunci rahasia server (JWT_SECRET)
	return token.SignedString([]byte(os.Getenv("JWT_SECRET")))
}

// ParseToken membaca token dan memverifikasi keabsahan tanda tangan digitalnya
func ParseToken(tokenString string) (jwt.MapClaims, error) {
	// Memverifikasi tanda tangan digital token menggunakan kunci rahasia server
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return []byte(os.Getenv("JWT_SECRET")), nil
	})

	if err != nil {
		return nil, err
	}

	// Jika token valid dan tanda tangannya cocok, kembalikan data klaim di dalamnya
	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		return claims, nil
	}

	// Mengembalikan error jika tanda tangan digital terbukti tidak valid (telah dimanipulasi)
	return nil, jwt.ErrSignatureInvalid
}

