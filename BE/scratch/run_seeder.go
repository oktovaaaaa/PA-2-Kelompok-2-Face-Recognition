package main

import (
	"fmt"
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
)

func main() {
	config.LoadEnv(".env.auth")
	database.ConnectDatabase("SeederFix")
	
	database.AutoMigrate(&models.Company{}, &models.User{})
	database.SeedSuperAdmin(database.DB)
	
	fmt.Println("Seeder executed successfully!")
}
