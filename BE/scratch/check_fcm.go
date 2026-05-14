package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
)

func main() {
	config.LoadEnv(".env.auth")
	database.ConnectDatabase("Auth-Check")

	var users []models.User
	database.DB.Select("name, email, fcm_token, status").Find(&users)

	fmt.Println("\n=== DAFTAR USER & FCM TOKEN ===")
	for _, u := range users {
		tokenStatus := "KOSONG"
		if u.FcmToken != "" {
			tokenStatus = "TERSEDIA"
		}
		fmt.Printf("Nama: %-15s | Status: %-10s | FCM Token: %s\n", u.Name, u.Status, tokenStatus)
	}
	fmt.Println("===============================\n")
}
