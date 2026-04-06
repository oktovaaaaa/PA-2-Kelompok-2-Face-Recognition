// internal/database/db.go

package database

import (
	"fmt"
	"os"

	"employee-system/internal/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() {

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
		panic("Gagal koneksi database")
	}

	DB = db

	AutoMigrate()

	fmt.Println("Database berhasil terkoneksi")
}

func AutoMigrate() {

	DB.AutoMigrate(
		&models.Company{},
		&models.Position{},
		&models.User{},
		&models.Salary{},
		&models.InviteToken{},
		&models.OTP{},
		&models.Session{},
		&models.Attendance{},
		&models.AttendanceSettings{},
		&models.LeaveRequest{},
		&models.Notification{},
		&models.SalaryPayment{},
		&models.Holiday{},
		&models.Penalty{},
		&models.Testimonial{},
	)
}
