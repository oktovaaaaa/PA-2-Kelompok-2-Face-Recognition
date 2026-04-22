package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func SuperAdminDashboard(c *gin.Context) {
	var companies []models.Company
	database.DB.Find(&companies)

	var stats struct {
		TotalActiveEmployees int64
		TotalPendingEmployees int64
		TotalCompanies       int64
	}

	database.DB.Model(&models.User{}).Where("status = ?", "ACTIVE").Count(&stats.TotalActiveEmployees)
	database.DB.Model(&models.User{}).Where("status = ?", "PENDING").Count(&stats.TotalPendingEmployees)
	database.DB.Model(&models.Company{}).Count(&stats.TotalCompanies)

	c.HTML(http.StatusOK, "super_admin_dashboard.html", gin.H{
		"Companies": companies,
		"Stats":     stats,
	})
}
