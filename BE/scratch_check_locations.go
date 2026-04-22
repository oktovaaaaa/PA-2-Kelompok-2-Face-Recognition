package main

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load(".env")

	database.ConnectDatabase()
	var locations []models.CompanyLocation
	database.DB.Find(&locations)

	fmt.Println("\nID | CompanyID | Name | Lat | Long")
	fmt.Println("--------------------------------------")
	for _, l := range locations {
		fmt.Printf("%s | %s | %s | %f | %f\n", l.ID, l.CompanyID, l.Name, l.Latitude, l.Longitude)
	}
}
