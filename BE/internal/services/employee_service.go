package services

import (
	"errors"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/google/uuid"
)

func RegisterEmployee(user models.User, inviteToken string) error {

	var invite models.InviteToken

	err := database.DB.Where("token = ?", inviteToken).First(&invite).Error

	if err != nil {
		return errors.New("Barcode tidak valid")
	}

	if invite.Status == "USED" {
		return errors.New("Barcode sudah pernah digunakan")
	}

	if time.Now().After(invite.ExpiresAt) {
		invite.Status = "EXPIRED"
		database.DB.Save(&invite)
		return errors.New("Barcode sudah kedaluwarsa")
	}

	var existing models.User
	database.DB.Where("email = ?", user.Email).First(&existing)
	if existing.ID != "" {
		return errors.New("Email sudah terdaftar")
	}

	hashPassword, _ := utils.HashPassword(user.Password)
	hashPin, _ := utils.HashPin(user.Pin)

	user.ID = uuid.New().String()
	user.CompanyID = invite.CompanyID
	user.Password = hashPassword
	user.Pin = hashPin
	user.Status = "PENDING"
	user.Role = "EMPLOYEE"

	err = database.DB.Create(&user).Error

	if err != nil {
		return err
	}

	invite.Status = "USED"
	database.DB.Save(&invite)

	// Kirim Notifikasi ke Admin
	var admin models.User
	if err := database.DB.Where("company_id = ? AND role = ?", invite.CompanyID, "ADMIN").First(&admin).Error; err == nil {
		CreateNotification(admin.ID, invite.CompanyID, "Pendaftaran Karyawan Baru", 
			user.Name + " telah mendaftar dan menunggu persetujuan.", "EMPLOYEE_REGISTERED", user.ID)
		SendPushNotification(admin.ID, "Pendaftaran Karyawan Baru", 
			user.Name + " telah mendaftar. Silakan cek di daftar karyawan pending.")
	}

	return nil
}
