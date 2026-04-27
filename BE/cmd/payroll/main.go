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
	// 1. Load specific env for Payroll Service
	config.LoadEnv(".env.payroll")

	// 2. Connect to Payroll Database
	database.ConnectDatabase("Payroll-Service")

	// 3. AutoMigrate only Payroll related tables
	database.AutoMigrate(
		&models.Salary{},
		&models.SalaryPayment{},
		&models.Bonus{},
		&models.Penalty{},
	)

	// 4. Setup Router (Only Payroll Routes)
	r := routes.SetupPayrollRouter()

	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8083"
	}

	fmt.Println("Payroll Service running on port", port)
	r.Run(":" + port)
}
