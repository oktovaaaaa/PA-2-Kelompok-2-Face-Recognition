package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
)

func main() {
	config.LoadEnv(".env.attendance")
	database.ConnectDatabase("Attendance-Check")

	var attendance []models.Attendance
	database.DB.Find(&attendance)

	fmt.Printf("\nFound %d records in pa2_attendance\n", len(attendance))
	for _, a := range attendance {
		fmt.Printf("ID: %s | UserID: %s | Date: %s | Status: %s\n", a.ID, a.UserID, a.Date, a.Status)
	}
}
