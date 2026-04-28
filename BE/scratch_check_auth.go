package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
)

func main() {
	config.LoadEnv(".env.auth")
	database.ConnectDatabase("Auth-Check")

	var users []models.User
	database.DB.Find(&users)

	fmt.Printf("\nFound %d users in pa2_auth\n", len(users))
	for _, u := range users {
		fmt.Printf("ID: %s | Name: %s | CreatedAt: %s\n", u.ID, u.Name, u.CreatedAt)
	}
}
