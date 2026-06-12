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
	
	var users []models.User
	database.DB.Order("created_at asc").Find(&users)
	fmt.Printf("--> DIAGNOSTIC: Found %d users:\n", len(users))
	for _, u := range users {
		fmt.Printf("Name=%s, Email=%s, Role=%s, Status=%s, CreatedAt=%s\n", u.Name, u.Email, u.Role, u.Status, u.CreatedAt.Format("2006-01-02 15:04:05"))
	}
}


