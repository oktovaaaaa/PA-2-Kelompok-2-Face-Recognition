package main

import (
	"fmt"
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
)

func main() {
	config.LoadEnv(".env.auth")
	database.ConnectDatabase("Check")

	var company models.Company
	err := database.DB.Where("id = ?", "SYSTEM").First(&company).Error
	if err != nil {
		fmt.Println("Company SYSTEM NOT FOUND:", err)
	} else {
		fmt.Println("Company SYSTEM FOUND:", company.Name)
	}

	var user models.User
	err = database.DB.Where("email = ?", "videntiiii@gmail.com").First(&user).Error
	if err != nil {
		fmt.Println("User videntiiii@gmail.com NOT FOUND:", err)
	} else {
		fmt.Printf("User videntiiii@gmail.com FOUND: ID=%s, CompanyID=%s, Role=%s\n", user.ID, user.CompanyID, user.Role)
	}
}
