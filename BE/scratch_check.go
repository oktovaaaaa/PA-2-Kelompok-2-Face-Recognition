package main

import (
	"fmt"
	"employee-system/internal/database"
	"employee-system/internal/config"
	"employee-system/internal/models"
)

func main() {
	config.LoadEnv(".env.attendance")
	database.ConnectDatabase("Diagnostic-Check")
	
	result := database.DB.Where("date = ?", "2026-06-22").Delete(&models.Attendance{})
	if result.Error != nil {
		fmt.Printf("--> Error deleting attendance: %v\n", result.Error)
	} else {
		fmt.Printf("--> SUCCESS: Deleted %d attendance records for today (2026-06-22)\n", result.RowsAffected)
	}
}
