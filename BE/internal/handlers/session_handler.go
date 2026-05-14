package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

// GetMySessions returns all active sessions for the logged in user
func GetMySessions(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var sessions []models.Session
	err := database.DB.Where("user_id = ?", user.ID).Order("created_at desc").Find(&sessions).Error
	if err != nil {
		utils.Error(c, "Gagal mengambil data sesi")
		return
	}

	utils.Success(c, "Daftar sesi aktif", sessions)
}

// DeleteSession removes a specific session (Force Logout)
func DeleteSession(c *gin.Context) {
	sessionID := c.Param("id")
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	// Security: Ensure the session belongs to the user or user is Super Admin
	var session models.Session
	err := database.DB.Where("id = ? AND user_id = ?", sessionID, user.ID).First(&session).Error
	if err != nil {
		utils.Error(c, "Sesi tidak ditemukan atau akses ditolak")
		return
	}

	if err := database.DB.Delete(&session).Error; err != nil {
		utils.Error(c, "Gagal menghapus sesi")
		return
	}

	utils.Success(c, "Perangkat berhasil dikeluarkan", nil)
}
