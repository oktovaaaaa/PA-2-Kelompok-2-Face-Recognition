package services

import (
	"errors"
	"fmt"
	"math/rand"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/google/uuid"
)

func RegisterAdmin(user models.User, company models.Company) error {
	var existing models.User

	database.DB.Where("email = ?", user.Email).First(&existing)
	if existing.ID != "" {
		return errors.New("Email sudah terdaftar")
	}

	hashPassword, _ := utils.HashPassword(user.Password)
	hashPin, _ := utils.HashPin(user.Pin)

	// 1. Create Company
	company.ID = uuid.New().String()
	if err := database.DB.Create(&company).Error; err != nil {
		return err
	}

	// 2. Create Default Position (Owner) for this company
	ownerPosition := models.Position{
		ID:        uuid.New().String(),
		CompanyID: company.ID,
		Name:      "Owner",
		Salary:    0,
	}
	if err := database.DB.Create(&ownerPosition).Error; err != nil {
		return err
	}

	// 3. Create Admin User
	user.ID = uuid.New().String()
	user.CompanyID = company.ID
	user.PositionID = &ownerPosition.ID // Assign the address of the ID
	user.Password = hashPassword
	user.Pin = hashPin
	user.Role = "ADMIN"
	user.Status = "ACTIVE"

	if err := database.DB.Create(&user).Error; err != nil {
		return err
	}

	return nil
}

func Login(email string, password string) error {
	var user models.User

	err := database.DB.Where("email = ?", email).First(&user).Error
	if err != nil {
		return errors.New("Email tidak ditemukan")
	}

	if user.Status != "ACTIVE" {
		return errors.New("Akun belum aktif")
	}

	if !utils.CheckPassword(user.Password, password) {
		return errors.New("Password salah")
	}

	return nil
}

func GenerateLoginOTP(email string) (string, error) {
	code := fmt.Sprintf("%06d", rand.Intn(999999))

	otp := models.OTP{
		ID:        uuid.New().String(),
		Email:     email,
		Code:      code,
		Type:      "LOGIN",
		Used:      false,
		ExpiresAt: time.Now().Add(5 * time.Minute),
	}

	err := database.DB.Create(&otp).Error
	return code, err
}

func SeedSuperAdmin() {
	var systemCompany models.Company
	err := database.DB.Where("id = ?", "SYSTEM").First(&systemCompany).Error
	if err != nil {
		systemCompany = models.Company{
			ID:        "SYSTEM",
			Name:      "System Administration",
			Address:   "System",
			Email:     "system@example.com",
			Phone:     "000",
			CreatedAt: time.Now(),
		}
		if err := database.DB.Create(&systemCompany).Error; err != nil {
			fmt.Println("Error creating system company:", err)
			return
		}
		fmt.Println("System company created.")
	}

	var user models.User
	// Check for the new email instead of the old one
	err = database.DB.Where("email = ?", "videntiiii@gmail.com").First(&user).Error

	if err != nil {
		// Cleanup old superadmin account if it exists
		database.DB.Where("email = ?", "superadmin@example.com").Delete(&models.User{})

		hashedPassword, _ := utils.HashPassword("Videnti@2026")
		superAdmin := models.User{
			ID:        "SUPER-ADMIN-ID",
			CompanyID: "SYSTEM",
			Name:      "Super Admin",
			Email:     "videntiiii@gmail.com",
			Password:  hashedPassword,
			Role:      "SUPER_ADMIN",
			Status:    "ACTIVE",
			CreatedAt: time.Now(),
		}
		if err := database.DB.Create(&superAdmin).Error; err != nil {
			fmt.Println("Error seeding Super Admin:", err)
			return
		}
		fmt.Println("Super admin seeded: videntiiii@gmail.com / Videnti@2026")
	} else {
		fmt.Println("Super admin (videntiiii@gmail.com) already exists.")
	}
}

func GoogleAuth(email string, name string, googleID string) (models.User, error) {
	var user models.User

	err := database.DB.Where("email = ?", email).First(&user).Error
	if err == nil {
		return user, nil
	}

	user = models.User{
		ID:       uuid.New().String(),
		Name:     name,
		Email:    email,
		GoogleID: googleID,
		Status:   "ACTIVE",
		Role:     "EMPLOYEE",
	}

	err = database.DB.Create(&user).Error
	return user, err
}

func LoginWithDevice(email string, password string, deviceID string) (models.User, error) {
	var user models.User

	err := database.DB.Where("email = ?", email).First(&user).Error
	if err != nil {
		return user, errors.New("User tidak ditemukan")
	}

	if user.Status != "ACTIVE" {
		return user, errors.New("Akun belum aktif")
	}

	if !utils.CheckPassword(user.Password, password) {
		return user, errors.New("Password salah")
	}

	if user.DeviceID != "" && user.DeviceID != deviceID {
		return user, errors.New("Akun sudah aktif di perangkat lain")
	}

	if user.DeviceID == "" {
		user.DeviceID = deviceID
		database.DB.Save(&user)
	}

	return user, nil
}

func GenerateResetOTP(email string) (string, error) {
	var user models.User
	if err := database.DB.Where("email = ?", email).First(&user).Error; err != nil {
		return "", errors.New("Email tidak terdaftar")
	}

	code := fmt.Sprintf("%06d", rand.Intn(999999))

	otp := models.OTP{
		ID:        uuid.New().String(),
		Email:     email,
		Code:      code,
		Type:      "RESET",
		Used:      false,
		ExpiresAt: time.Now().Add(5 * time.Minute),
	}

	err := database.DB.Create(&otp).Error
	return code, err
}

func ResetPassword(email string, newPassword string) error {
	var user models.User
	if err := database.DB.Where("email = ?", email).First(&user).Error; err != nil {
		return errors.New("Pengguna tidak ditemukan")
	}

	hashPassword, _ := utils.HashPassword(newPassword)
	user.Password = hashPassword

	return database.DB.Save(&user).Error
}
