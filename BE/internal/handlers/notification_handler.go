// internal/handlers/notification_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

// GetNotifications — list notifikasi milik user yang login
func GetNotifications(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var notifications = []models.Notification{}
	database.DB.Where("user_id = ?", user.ID).
		Order("created_at desc").
		Limit(50).
		Find(&notifications)

	// Hitung unread
	var unreadCount int64
	database.DB.Model(&models.Notification{}).Where("user_id = ? AND is_read = ?", user.ID, false).Count(&unreadCount)

	utils.Success(c, "Notifikasi", gin.H{
		"notifications": notifications,
		"unread_count":  unreadCount,
	})
}

// MarkNotificationRead — tandai notifikasi sudah dibaca
func MarkNotificationRead(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	id := c.Param("id")

	var notif models.Notification
	if err := database.DB.Where("id = ? AND user_id = ?", id, user.ID).First(&notif).Error; err != nil {
		utils.Error(c, "Notifikasi tidak ditemukan")
		return
	}

	notif.IsRead = true
	database.DB.Save(&notif)
	utils.Success(c, "Notifikasi ditandai sudah dibaca", nil)
}

// MarkAllNotificationsRead — tandai semua notifikasi sudah dibaca
func MarkAllNotificationsRead(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	database.DB.Model(&models.Notification{}).
		Where("user_id = ? AND is_read = ?", user.ID, false).
		Update("is_read", true)

	utils.Success(c, "Semua notifikasi ditandai sudah dibaca", nil)
}
