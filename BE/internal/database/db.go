// internal/database/db.go

package database

import (
	"fmt"
	"os"

	"employee-system/internal/models"
	"employee-system/internal/utils"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase(serviceName string) {

	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		os.Getenv("DB_PORT"),
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})

	if err != nil {
		panic("Gagal koneksi database " + serviceName)
	}

	DB = db

	fmt.Printf("[%s] Database %s berhasil terkoneksi\n", serviceName, os.Getenv("DB_NAME"))
}

func AutoMigrate(models ...interface{}) {
	if len(models) > 0 {
		DB.AutoMigrate(models...)
	}
}

func SeedSuperAdmin(db *gorm.DB) {
	fmt.Println("Memulai seeding Super Admin...")

	// 1. Pastikan Perusahaan SYSTEM ada
	var systemCompany models.Company
	err := db.Where("id = ?", "SYSTEM").First(&systemCompany).Error
	if err != nil {
		systemCompany = models.Company{
			ID:      "SYSTEM",
			Name:    "System Administration",
			Address: "System",
			Email:   "videntiiii@gmail.com",
			Phone:   "000",
		}
		db.Create(&systemCompany)
		fmt.Println("System company created.")
	}

	email := "videntiiii@gmail.com"
	password := "Videnti@2026"

	var user models.User
	err = db.Where("email = ?", email).First(&user).Error

	if err != nil {
		hashPassword, _ := utils.HashPassword(password)
		
		superAdmin := models.User{
			ID:        "SUPER-ADMIN-ID",
			CompanyID: "SYSTEM",
			Name:      "Super Admin",
			Email:     email,
			Password:  hashPassword,
			Role:      "SUPER_ADMIN",
			Status:    "ACTIVE",
		}

		if err := db.Create(&superAdmin).Error; err != nil {
			fmt.Printf("Error seeding Super Admin: %v\n", err)
		} else {
			fmt.Println("Super Admin seeded successfully: videntiiii@gmail.com / Videnti@2026")
		}
	} else {
		// Update existing superadmin to ensure it has the right company and role
		user.CompanyID = "SYSTEM"
		user.Role = "SUPER_ADMIN"
		user.Status = "ACTIVE"
		db.Save(&user)
		fmt.Println("Super Admin already exists. Updated CompanyID to SYSTEM.")
	}
}
