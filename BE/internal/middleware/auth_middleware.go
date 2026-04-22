package middleware

import (
	"strings"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			utils.Error(c, "Unauthorized")
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := services.ParseToken(tokenString)
		if err != nil {
			utils.Error(c, "Invalid token")
			c.Abort()
			return
		}

		userID, ok := claims["user_id"].(string)
		if !ok {
			utils.Error(c, "Invalid token claims")
			c.Abort()
			return
		}

		var user models.User
		if err := database.DB.Preload("Company").Where("id = ?", userID).First(&user).Error; err != nil {
			utils.Error(c, "User not found")
			c.Abort()
			return
		}

		if user.Status != "ACTIVE" {
			utils.Error(c, "Account inactive")
			c.Abort()
			return
		}

		// Check Company Status (If not Super Admin)
		if user.Role != "SUPER_ADMIN" && user.Company.Status == "INACTIVE" {
			utils.Error(c, "Organization deactivated by system administrator")
			c.Abort()
			return
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
			utils.Error(c, "Unauthorized")
			c.Abort()
			return
		}

		u := user.(models.User)
		if u.Role != "ADMIN" && u.Role != "OWNER" && u.Role != "SUPER_ADMIN" {
			utils.Error(c, "Access denied: Admin only")
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
			utils.Error(c, "Unauthorized")
			c.Abort()
			return
		}

		u := user.(models.User)
		if u.Role != "SUPER_ADMIN" {
			utils.Error(c, "Access denied: Super Admin only")
			c.Abort()
			return
		}

		c.Next()
	}
}
