package middleware

import (
	"strings"

	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			utils.Error(c, "Sesi Anda tidak valid, silakan login kembali")
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := services.ParseToken(tokenString)
		if err != nil {
			utils.Error(c, "Sesi Anda telah berakhir, silakan login kembali")
			c.Abort()
			return
		}

		userID, _ := claims["user_id"].(string)
		role, _ := claims["role"].(string)
		companyID, _ := claims["company_id"].(string)

		// Buat objek user minimal dari data Token (Microservices style)
		user := models.User{
			ID:        userID,
			Role:      role,
			CompanyID: companyID,
			Status:    "ACTIVE", // Kita anggap aktif jika token masih berlaku
		}

		c.Set("user_id", userID)
		c.Set("user", user)
		c.Next()
	}
}

func AdminOnlyMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		user, exists := c.Get("user")
		if !exists {
			utils.Error(c, "Sesi tidak ditemukan, silakan login kembali")
			c.Abort()
			return
		}

		u := user.(models.User)
		if u.Role != "ADMIN" && u.Role != "OWNER" && u.Role != "SUPER_ADMIN" {
			utils.Error(c, "Akses ditolak: Hanya Admin yang diperbolehkan")
			c.Abort()
			return
		}

		c.Next()
	}
}

func SuperAdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		user, exists := c.Get("user")
		if !exists {
			utils.Error(c, "Sesi tidak ditemukan, silakan login kembali")
			c.Abort()
			return
		}

		u := user.(models.User)
		if u.Role != "SUPER_ADMIN" {
			utils.Error(c, "Akses ditolak: Hanya Super Admin yang diperbolehkan")
			c.Abort()
			return
		}

		c.Next()
	}
}
