// internal/services/fcm_service.go
//
// Implementasi Firebase Cloud Messaging (FCM) HTTP v1 API menggunakan Firebase Admin SDK.

package services

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"

	"employee-system/internal/database"
	"employee-system/internal/models"
)

var fcmClient *messaging.Client

// InitFCM menginisialisasi Firebase Admin App dan FCM Client.
func InitFCM() error {
	configPath := os.Getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
	if configPath == "" {
		return fmt.Errorf("FIREBASE_SERVICE_ACCOUNT_JSON tidak diset di .env")
	}

	// Pastikan path absolut atau relatif terhadap root
	absPath, err := filepath.Abs(configPath)
	if err != nil {
		return fmt.Errorf("gagal mendapatkan path absolut config: %v", err)
	}

	opt := option.WithCredentialsFile(absPath)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return fmt.Errorf("error initializing firebase app: %v", err)
	}

	client, err := app.Messaging(context.Background())
	if err != nil {
		return fmt.Errorf("error getting messaging client: %v", err)
	}

	fcmClient = client
	fmt.Println("[FCM] Firebase Admin SDK berhasil diinisialisasi")
	return nil
}

// SendPushNotification mengirim push notification ke karyawan/admin berdasarkan userID.
// Menggunakan FCM HTTP v1 API melalui Firebase Admin SDK.
func SendPushNotification(userID, title, body string) {
	if fcmClient == nil {
		// Coba inisialisasi jika belum
		if err := InitFCM(); err != nil {
			fmt.Printf("[FCM] Skip notifikasi: %v\n", err)
			return
		}
	}

	// Ambil FCM token dari database
	var user models.User
	if err := database.DB.Select("fcm_token").Where("id = ?", userID).First(&user).Error; err != nil {
		fmt.Printf("[FCM] User %s tidak ditemukan di DB\n", userID)
		return
	}

	if user.FcmToken == "" {
		fmt.Printf("[FCM] User %s tidak memiliki FCM token, skipping\n", userID)
		return
	}

	// Buat pesan FCM
	message := &messaging.Message{
		Token: user.FcmToken,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: map[string]string{
			"click_action": "FLUTTER_NOTIFICATION_CLICK",
			"user_id":      userID,
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Sound:     "default",
				ChannelID: "high_importance_channel",
			},
		},
	}

	// Kirim pesan
	response, err := fcmClient.Send(context.Background(), message)
	if err != nil {
		log.Printf("[FCM] Gagal mengirim notifikasi ke %s: %v\n", userID, err)
		return
	}

	fmt.Printf("[FCM] Notifikasi berhasil dikirim ke %s. MessageID: %s\n", userID, response)
}

