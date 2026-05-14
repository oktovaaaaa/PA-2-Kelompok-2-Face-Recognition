package main

import (
	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"fmt"
)

func main() {
	config.LoadEnv(".env.auth")
	database.ConnectDatabase("FCM-Test")

	// Ambil user "Osvald" atau user terakhir yang aktif
	var user models.User
	err := database.DB.Where("fcm_token != ''").Order("updated_at desc").First(&user).Error
	if err != nil {
		fmt.Println("Gagal menemukan user dengan FCM Token")
		return
	}

	fmt.Printf("Mencoba kirim notifikasi tes ke: %s (Email: %s)\n", user.Name, user.Email)
	
	// Inisialisasi FCM
	if err := services.InitFCM(); err != nil {
		fmt.Printf("Gagal inisialisasi FCM: %v\n", err)
		return
	}

	services.SendPushNotification(user.ID, "Tes Notifikasi", "Ini adalah pesan tes dari sistem.")
	
	fmt.Println("Selesai. Cek output di atas untuk status pengiriman.")
}
