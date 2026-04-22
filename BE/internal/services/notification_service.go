// internal/services/notification_service.go

package services

import (
	"employee-system/internal/database"
	"employee-system/internal/models"

	"github.com/google/uuid"
)

// CreateNotification menyimpan notifikasi in-app ke database
func CreateNotification(userID, companyID, title, body, notifType, refID string) {
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
