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
	
	var user models.User
	database.DB.Where("name = ?", "Oktovaaaaa").First(&user)
	fmt.Printf("--> DIAGNOSTIC: User Name=%s, CompanyID=%s, Role=%s\n", user.Name, user.CompanyID, user.Role)
}


