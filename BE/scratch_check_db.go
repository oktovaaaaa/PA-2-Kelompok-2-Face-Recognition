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
	var companies []models.Company
	database.DB.Find(&companies)

	fmt.Println("\nID | Name | Lat | Long | Status")
	fmt.Println("---------------------------------")
	for _, c := range companies {
		fmt.Printf("%s | %s | %f | %f | %s\n", c.ID, c.Name, c.Latitude, c.Longitude, c.Status)
	}
}
