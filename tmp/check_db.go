package main

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
	"log"
)

func main() {
	// Initialize DB (this depends on how it's initialized in your project)
    // I specify the path relative to workspace root if needed, but the internal/database normally handles DSN
	database.InitDB() 

	var leaves []models.LeaveRequest
	database.DB.Order("created_at desc").Limit(10).Find(&leaves)

	fmt.Println("Recent Leave Requests:")
	for _, l := range leaves {
		fmt.Printf("ID: %s | Title: %s | PhotoURL: [%s]\n", l.ID, l.Title, l.PhotoURL)
	}
}
