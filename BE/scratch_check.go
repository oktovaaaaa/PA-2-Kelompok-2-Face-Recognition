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
	
	var settings []models.AttendanceSettings
	database.DB.Find(&settings)
	fmt.Printf("--> DIAGNOSTIC: Found %d settings:\n", len(settings))
	for _, s := range settings {
		fmt.Printf("CompanyID=%s, LatePenalty=%f, AlphaPenalty=%f, EarlyLeavePenalty=%f\n", s.CompanyID, s.LatePenalty, s.AlphaPenalty, s.EarlyLeavePenalty)
	}
}


