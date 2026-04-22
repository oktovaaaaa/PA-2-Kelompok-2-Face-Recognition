package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

func GetSuperAdminStats(c *gin.Context) {
	var topCompanies []models.Company
	database.DB.Where("name != ?", "SYSTEM ADMINISTRATION").Order("created_at desc").Limit(5).Find(&topCompanies)

	// Sync coordinates for Top Companies
	for i, comp := range topCompanies {
		if comp.Latitude == 0 && comp.Longitude == 0 {
			var loc models.CompanyLocation
			if err := database.DB.Where("company_id = ?", comp.ID).First(&loc).Error; err == nil {
				topCompanies[i].Latitude = loc.Latitude
				topCompanies[i].Longitude = loc.Longitude
			}
		}
	}

	// Recent Users
	var recentUsers []models.User
	database.DB.Preload("Company").Where("role != ?", "SUPER_ADMIN").Order("created_at desc").Limit(5).Find(&recentUsers)

	// Sync coordinates for Recent Users' Companies
	for i, user := range recentUsers {
		if user.Company.Latitude == 0 && user.Company.Longitude == 0 {
			var loc models.CompanyLocation
			if err := database.DB.Where("company_id = ?", user.CompanyID).First(&loc).Error; err == nil {
				recentUsers[i].Company.Latitude = loc.Latitude
				recentUsers[i].Company.Longitude = loc.Longitude
			}
		}
	}

	var stats struct {
		TotalActiveEmployees int64            `json:"total_active_employees"`
		TotalCompanies       int64            `json:"total_companies"`
		RoleDistribution     map[string]int64 `json:"role_distribution"`
	}

	database.DB.Model(&models.User{}).Where("status = ? AND role != ?", "ACTIVE", "SUPER_ADMIN").Count(&stats.TotalActiveEmployees)
	database.DB.Model(&models.Company{}).Where("name != ?", "SYSTEM ADMINISTRATION").Count(&stats.TotalCompanies)

	// Role distribution
	var roleResults []struct {
		Role  string
		Count int64
	}
	database.DB.Model(&models.User{}).Where("role != ?", "SUPER_ADMIN").Select("role, count(*) as count").Group("role").Scan(&roleResults)
	roleStats := make(map[string]int64)
	for _, r := range roleResults {
		roleStats[r.Role] = r.Count
	}
	stats.RoleDistribution = roleStats

	utils.Success(c, "Data Super Admin berhasil diambil", gin.H{
		"recent_companies": topCompanies,
		"recent_users":     recentUsers,
		"stats":            stats,
	})
}

func GetRegistrationTrend(c *gin.Context) {
	yearStr := c.Query("year")
	year, err := strconv.Atoi(yearStr)
	if err != nil {
		year = time.Now().Year()
	}

	var results []struct {
		Month int
		Count int
	}

	// PostgreSQL query to group by month
	query := `
		SELECT EXTRACT(MONTH FROM created_at) as month, count(*) as count
		FROM users
		WHERE EXTRACT(YEAR FROM created_at) = ? AND role != 'SUPER_ADMIN'
		GROUP BY month
		ORDER BY month
	`
	database.DB.Raw(query, year).Scan(&results)

	// Format into a 12-month array
	counts := make([]int, 12)
	for _, r := range results {
		if r.Month >= 1 && r.Month <= 12 {
			counts[r.Month-1] = r.Count
		}
	}

	utils.Success(c, "Data tren pendaftaran berhasil diambil", counts)
}

func GetAllSystemUsers(c *gin.Context) {
	status := c.Query("status")
	var users []models.User

	db := database.DB.Preload("Company").Preload("Position")

	db = db.Where("role != ?", "SUPER_ADMIN")

	if status != "" {
		db = db.Where("status = ?", status)
	}

	if err := db.Find(&users).Error; err != nil {
		utils.Error(c, "Gagal mengambil daftar seluruh user")
		return
	}

	// Sync coordinates from company_locations if companies table has 0
	for i, user := range users {
		if user.Company.Latitude == 0 && user.Company.Longitude == 0 {
			var loc models.CompanyLocation
			if err := database.DB.Where("company_id = ?", user.CompanyID).First(&loc).Error; err == nil {
				users[i].Company.Latitude = loc.Latitude
				users[i].Company.Longitude = loc.Longitude
			}
		}
	}

	utils.Success(c, "Seluruh user berhasil diambil", users)
}

func GetRegistrationYears(c *gin.Context) {
	var years []int
	query := `SELECT DISTINCT EXTRACT(YEAR FROM created_at) as year FROM users ORDER BY year DESC`
	database.DB.Raw(query).Scan(&years)

	// If no years found, at least return current year
	if len(years) == 0 {
		years = append(years, time.Now().Year())
	}

	utils.Success(c, "Daftar tahun pendaftaran berhasil diambil", years)
}

func GetAllCompanies(c *gin.Context) {
	var companies []models.Company
	if err := database.DB.Where("name != ?", "SYSTEM ADMINISTRATION").Order("name asc").Find(&companies).Error; err != nil {
		utils.Error(c, "Gagal mengambil daftar perusahaan")
		return
	}

	// Sync coordinates from company_locations if companies table has 0
	for i, comp := range companies {
		if comp.Latitude == 0 && comp.Longitude == 0 {
			var loc models.CompanyLocation
			if err := database.DB.Where("company_id = ?", comp.ID).First(&loc).Error; err == nil {
				companies[i].Latitude = loc.Latitude
				companies[i].Longitude = loc.Longitude
			}
		}
	}

	utils.Success(c, "Daftar seluruh perusahaan berhasil diambil", companies)
}

func UpdateCompanyStatus(c *gin.Context) {
	companyID := c.Param("id")
	var body struct {
		Status string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var company models.Company
	if err := database.DB.Where("id = ?", companyID).First(&company).Error; err != nil {
		utils.Error(c, "Perusahaan tidak ditemukan")
		return
	}

	company.Status = body.Status
	if err := database.DB.Save(&company).Error; err != nil {
		utils.Error(c, "Gagal memperbarui status perusahaan")
		return
	}

	utils.Success(c, "Status perusahaan berhasil diperbarui", company)
}
