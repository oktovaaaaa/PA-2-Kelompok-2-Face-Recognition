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
	var companies []models.Company
	database.DB.Find(&companies)
	fmt.Printf("Total Companies in DB: %d\n", len(companies))
	for _, c := range companies {
		fmt.Printf("ID: %v | Name: %s | Email: %s\n", c.ID, c.Name, c.Email)
	}
}
