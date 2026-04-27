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
	// 1. Load specific env for Auth Service
	config.LoadEnv(".env.auth")

	// 2. Connect to Identity Database
	database.ConnectDatabase("Auth-Service")

	// 3. AutoMigrate only Identity related tables
	database.AutoMigrate(
		&models.Company{},
		&models.Position{},
		&models.User{},
		&models.InviteToken{},
		&models.OTP{},
		&models.Session{},
		&models.CompanyLocation{},
		&models.Notification{},
		&models.Testimonial{},
	)

	// 4. Seed Super Admin (only in Auth Service)
	database.SeedSuperAdmin(database.DB)

	// 5. Setup Router (Only Auth Routes)
	r := routes.SetupAuthRouter()

	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8081"
	}

	fmt.Println("Auth Service running on port", port)
	r.Run(":" + port)
}
