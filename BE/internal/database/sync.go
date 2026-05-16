// internal/database/sync.go

package database

import (
	"employee-system/internal/models"
	"fmt"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// SyncUserToAttendance menyalin data user dari Auth ke database Attendance secara manual.
// Ini digunakan untuk menjaga prinsip microservices (DB terpisah) tapi data tetap tersinkron.
func SyncUserToAttendance(user models.User) error {
	// 1. Koneksi ke database Attendance (pa2_attendance)
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		"pa2_attendance", // Paksa ke database attendance
		os.Getenv("DB_PORT"),
	)

	attDB, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("gagal koneksi ke DB Attendance untuk sinkronisasi: %v", err)
	}

	// 2. Simpan atau Update data user di database Attendance
	// Kita hanya perlu data dasar untuk pengingat dan relasi
	err = attDB.Save(&user).Error
	if err != nil {
		return fmt.Errorf("gagal simpan user ke DB Attendance: %v", err)
	}

	fmt.Printf("[Sync] User %s (%s) berhasil disinkronkan ke DB Attendance\n", user.Name, user.ID)
	return nil
}

// SyncUserToPayroll menyalin data user dari Auth ke database Payroll secara manual.
func SyncUserToPayroll(user models.User) error {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_payroll", os.Getenv("DB_PORT"),
	)

	payDB, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("gagal koneksi ke DB Payroll untuk sinkronisasi: %v", err)
	}

	err = payDB.Save(&user).Error
	if err != nil {
		return fmt.Errorf("gagal simpan user ke DB Payroll: %v", err)
	}

	fmt.Printf("[Sync] User %s (%s) berhasil disinkronkan ke DB Payroll\n", user.Name, user.ID)
	return nil
}

func InitialSyncFromAuth() {
	fmt.Println("[Sync] >>> MEMULAI INITIAL SYNC DARI AUTH DB <<<")
	
	host := os.Getenv("DB_HOST")
	user := os.Getenv("DB_USER")
	pass := os.Getenv("DB_PASSWORD")
	port := os.Getenv("DB_PORT")
	
	fmt.Printf("[Sync] Menghubungkan ke %s:%s (DB: pa2_auth)...\n", host, port)

	// Koneksi ke DB Auth
	authDsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		host, user, pass, "pa2_auth", port,
	)
	authDB, err := gorm.Open(postgres.Open(authDsn), &gorm.Config{})
	if err != nil {
		fmt.Printf("[Sync] !!! ERROR KONEKSI DB AUTH: %v\n", err)
		return
	}

	var users []models.User
	if err := authDB.Find(&users).Error; err != nil {
		fmt.Printf("[Sync] !!! ERROR QUERY USER DI AUTH: %v\n", err)
		return
	}

	fmt.Printf("[Sync] Ditemukan %d user di database pa2_auth. Mulai menyalin...\n", len(users))

	for _, u := range users {
		fmt.Printf("[Sync] Menyalin user: %s (Role: %s, Status: %s)\n", u.Name, u.Role, u.Status)
		
		// Sinkronkan ke Attendance
		if err := SyncUserToAttendance(u); err != nil {
			fmt.Printf("[Sync] !!! GAGAL menyalin %s ke Attendance: %v\n", u.Name, err)
		}
		
		// Sinkronkan ke Payroll
		if err := SyncUserToPayroll(u); err != nil {
			fmt.Printf("[Sync] !!! GAGAL menyalin %s ke Payroll: %v\n", u.Name, err)
		}
	}
	fmt.Printf("[Sync] >>> INITIAL SYNC SELESAI. %d user berhasil diproses <<<\n", len(users))
}
