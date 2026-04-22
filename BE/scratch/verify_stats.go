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

	var stats struct {
		TotalActiveEmployees int64
		TotalPendingEmployees int64
		TotalCompanies       int64
	}

	database.DB.Model(&models.User{}).Where("status = ?", "ACTIVE").Count(&stats.TotalActiveEmployees)
	database.DB.Model(&models.User{}).Where("status = ?", "PENDING").Count(&stats.TotalPendingEmployees)
	database.DB.Model(&models.Company{}).Count(&stats.TotalCompanies)

	fmt.Printf("Active Users: %d\n", stats.TotalActiveEmployees)
	fmt.Printf("Pending Users: %d\n", stats.TotalPendingEmployees)
	fmt.Printf("Total Companies: %d\n", stats.TotalCompanies)
}
