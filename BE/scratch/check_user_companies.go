package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
)

func main() {
	config.LoadEnv()
	database.ConnectDatabase()
	var users []models.User
	database.DB.Preload("Company").Find(&users)
	fmt.Printf("Total Users in DB: %d\n", len(users))
	for _, u := range users {
		compName := "NULL"
		if u.Company.ID != "" {
			compName = u.Company.Name
		}
		fmt.Printf("User: %s | Company ID: %s | Company Name: %s\n", u.Name, u.CompanyID, compName)
	}
}
