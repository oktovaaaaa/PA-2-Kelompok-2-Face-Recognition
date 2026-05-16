package main

import (
	"employee-system/internal/models"
	"fmt"
	"os"

	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		fmt.Println("Error loading .env file")
		return
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Jakarta",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_attendance", os.Getenv("DB_PORT"))

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		fmt.Println("failed to connect database")
		return
	}

	var users []models.User
	err = db.Find(&users).Error
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	for _, u := range users {
		fmt.Printf("ID: %s, Name: %s, FCM: %s\n", u.ID, u.Name, u.FcmToken)
	}
}
