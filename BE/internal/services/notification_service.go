// internal/services/notification_service.go

package services

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"
	"os"

	"github.com/google/uuid"
)

// CreateNotification menyimpan notifikasi in-app ke database
func CreateNotification(userID, companyID, title, body, notifType, refID string) {
	port := os.Getenv("APP_PORT")

	// Jika bukan Auth Service (8081), kirim ke Auth Service via internal API
	// agar notifikasi tersimpan di database utama (Identity DB) yang dibaca oleh aplikasi mobile.
	if port != "8081" && port != "" {
		payload := map[string]string{
			"user_id":    userID,
			"company_id": companyID,
			"title":      title,
			"body":       body,
			"type":       notifType,
			"ref_id":     refID,
		}
		go utils.PostInternalAPI("http://localhost:8081/api/internal/notifications", payload)
	}

	notif := models.Notification{
		ID:        uuid.New().String(),
		UserID:    userID,
		CompanyID: companyID,
		Title:     title,
		Body:      body,
		Type:      notifType,
		RefID:     refID,
		IsRead:    false,
	}
	database.DB.Create(&notif)
}

// DeleteNotificationsByRefID menghapus notifikasi berdasarkan RefID (misal: ID izin)
func DeleteNotificationsByRefID(refID string) {
	database.DB.Where("ref_id = ?", refID).Delete(&models.Notification{})
}
