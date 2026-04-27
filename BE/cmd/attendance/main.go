package main

import (
	"fmt"
	"os"

	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/routes"
)

func main() {
	// 1. Load specific env for Attendance Service
	config.LoadEnv(".env.attendance")

	// 2. Connect to Attendance Database
	database.ConnectDatabase("Attendance-Service")

	// 3. AutoMigrate only Attendance related tables
	database.AutoMigrate(
		&models.Attendance{},
		&models.AttendanceSettings{},
		&models.LeaveRequest{},
		&models.Holiday{},
	)

	// 4. Setup Router (Only Attendance Routes)
	r := routes.SetupAttendanceRouter()

	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8082"
	}

	fmt.Println("Attendance Service running on port", port)
	r.Run(":" + port)
}
