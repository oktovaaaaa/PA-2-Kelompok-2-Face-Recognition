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
		&models.User{}, // [FIX] Add User table structure to allow foreign keys
		&models.Salary{},
		&models.SalaryPayment{},
		&models.Bonus{},
		&models.Penalty{},
		&models.Notification{},
	)

	// [FIX] Hapus constraint foreign key di database Payroll karena tabel Company/Position tidak ada isinya
	database.DB.Exec("ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_company;")
	database.DB.Exec("ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_position;")

	// 4. Setup Router (Only Payroll Routes)
	r := routes.SetupPayrollRouter()

	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8083"
	}

	fmt.Println("Payroll Service running on port", port)
	r.Run(":" + port)
}
