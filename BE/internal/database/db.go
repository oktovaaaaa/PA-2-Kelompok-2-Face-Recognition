// internal/database/db.go

package database

import (
	"fmt"
	"os"

	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/google/uuid"
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

	email := "videntiiii@gmail.com"
	password := "Videntiiii@2026"

	var count int64
	db.Model(&models.User{}).Where("email = ?", email).Count(&count)

	if count == 0 {
		hashPassword, _ := utils.HashPassword(password)
		
		superAdmin := models.User{
			ID:       uuid.New().String(),
			Name:     "Super Admin",
			Email:    email,
			Password: hashPassword,
			Role:     "SUPER_ADMIN",
			Status:   "ACTIVE",
		}

		if err := db.Create(&superAdmin).Error; err != nil {
			fmt.Printf("Error seeding Super Admin: %v\n", err)
		} else {
			fmt.Println("Super Admin seeded successfully!")
		}
	} else {
		fmt.Println("Super Admin already exists.")
	}
}
