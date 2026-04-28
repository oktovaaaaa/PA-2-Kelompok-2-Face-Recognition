package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
	"os"
)

func main() {
	os.Setenv("DB_NAME", "pa2frkel2")
	config.LoadEnv(".env")
	database.ConnectDatabase("Old-DB-Check")

	var attendance []models.Attendance
	database.DB.Find(&attendance)

	fmt.Printf("\nFound %d records in pa2frkel2\n", len(attendance))
}
