package main

import (
	"employee-system/internal/models"
	"fmt"
	"os"

	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	godotenv.Load()
	host := os.Getenv("DB_HOST")
	user := os.Getenv("DB_USER")
	pass := os.Getenv("DB_PASSWORD")
	port := os.Getenv("DB_PORT")

	// 1. Connect to Attendance DB (Source of existing users for now)
	attDsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable", host, user, pass, "pa2_attendance", port)
	attDB, err := gorm.Open(postgres.Open(attDsn), &gorm.Config{})
	if err != nil {
		fmt.Printf("Gagal koneksi Attendance DB: %v\n", err)
		return
	}

	// 2. Connect to Payroll DB (Destination)
	payDsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable", host, user, pass, "pa2_payroll", port)
	payDB, err := gorm.Open(postgres.Open(payDsn), &gorm.Config{})
	if err != nil {
		fmt.Printf("Gagal koneksi Payroll DB: %v\n", err)
		return
	}

	// Drop constraints because Company/Position tables might be empty in Payroll DB
	payDB.Exec("ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_company;")
	payDB.Exec("ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_position;")

	// 3. Fetch all users from Attendance
	var users []models.User
	attDB.Find(&users)
	fmt.Printf("Ditemukan %d user di Attendance DB. Memulai sync ke Payroll...\n", len(users))

	for _, u := range users {
		err := payDB.Save(&u).Error
		if err != nil {
			fmt.Printf("Gagal sync user %s: %v\n", u.Name, err)
		} else {
			fmt.Printf("Berhasil sync user %s (%s)\n", u.Name, u.ID)
		}
	}
	fmt.Println("Sync Selesai!")
}
