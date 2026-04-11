// internal / services / pin_service
package services

import (
	"errors"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"
)

func LoginWithPin(userID string, pin string) (models.User, error) {

	var user models.User

	err := database.DB.Where("id = ?", userID).First(&user).Error

	if err != nil {
		return user, errors.New("User tidak ditemukan")
	}

	if user.PinLockedUntil != nil && time.Now().Before(*user.PinLockedUntil) {
		return user, errors.New("PIN sedang terkunci, silakan coba lagi nanti")
	}

	if !utils.CheckPin(user.Pin, pin) {
		user.InvalidPinAttempts++
		if user.InvalidPinAttempts >= 5 {
			lockedUntil := time.Now().Add(5 * time.Minute)
			user.PinLockedUntil = &lockedUntil
		}
		database.DB.Save(&user)
		return user, errors.New("PIN yang Anda masukkan salah")
	}

	// Reset attempts on successful PIN
	user.InvalidPinAttempts = 0
	user.PinLockedUntil = nil
	database.DB.Save(&user)

	return user, nil
}
