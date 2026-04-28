package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
	"os"
)

func main() {
	// Temporarily override DB_NAME to check old DB
	os.Setenv("DB_NAME", "pa2frkel2")
	config.LoadEnv(".env") // Load monolith env
	database.ConnectDatabase("Old-DB-Check")

	var users []models.User
	database.DB.Find(&users)

	fmt.Printf("\nFound %d users in pa2frkel2\n", len(users))
	for _, u := range users {
		fmt.Printf("ID: %s | Name: %s | Role: %s | Status: %s | CompanyID: %s\n", u.ID, u.Name, u.Role, u.Status, u.CompanyID)
	}
}
