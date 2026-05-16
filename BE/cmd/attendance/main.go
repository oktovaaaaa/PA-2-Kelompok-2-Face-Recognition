package main

import (
	"fmt"
	"os"

	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/routes"
)

func main() {
	// 1. Load specific env for Attendance Service
	config.LoadEnv(".env.attendance")

	// 2. Connect to Attendance Database
	database.ConnectDatabase("Attendance-Service")

	// 3. AutoMigrate only Attendance related tables
	database.AutoMigrate(
		&models.User{}, // [FIX] Add User table structure to allow foreign keys
		&models.Attendance{},
		&models.AttendanceSettings{},
		&models.LeaveRequest{},
		&models.Holiday{},
		&models.CompanyLocation{},
	)

	// [FIX] Hapus constraint foreign key di database Attendance karena tabel Company/Position tidak ada isinya
	database.DB.Exec("ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_company;")
	database.DB.Exec("ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_position;")

	// [NEW] Sinkronisasi awal data user dari DB Auth (karena DB terpisah)
	database.InitialSyncFromAuth()

	// 4. Setup Router (Only Attendance Routes)
	r := routes.SetupAttendanceRouter()

	// 5. Start Background Scheduler (Reminders)
	go services.StartScheduler()

	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8082"
	}

	fmt.Println("Attendance Service running on port", port)
	r.Run(":" + port)
}
