package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
)

func main() {
	config.LoadEnv(".env.payroll")
	database.ConnectDatabase("Payroll-Check")

	var bonuses []models.Bonus
	database.DB.Find(&bonuses)

	fmt.Printf("\nFound %d records in pa2_payroll\n", len(bonuses))
}
