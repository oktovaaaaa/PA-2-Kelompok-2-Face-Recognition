package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
)

func main() {
	config.LoadEnv(".env.auth")
	database.ConnectDatabase("Auth-Check-Face")

	var user models.User
	err := database.DB.Where("email = ?", "osvaldind04@gmail.com").First(&user).Error
	if err != nil {
		fmt.Println("User Osvald tidak ditemukan")
		return
	}

	fmt.Printf("\n=== DATA WAJAH OSVALD ===\n")
	fmt.Printf("Nama           : %s\n", user.Name)
	fmt.Printf("Face Embedding : %d karakter\n", len(user.FaceEmbedding))
	if user.FaceEmbedding == "" {
		fmt.Println("STATUS: DATA WAJAH KOSONG!")
	} else {
		fmt.Println("STATUS: DATA WAJAH ADA")
		// Print bit of the embedding for verification
		if len(user.FaceEmbedding) > 50 {
			fmt.Printf("Preview        : %s...\n", user.FaceEmbedding[:50])
		}
	}
	fmt.Println("=========================\n")
}
