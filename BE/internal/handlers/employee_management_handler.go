// internal/handlers/employee_management_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"
	"fmt"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// GetEmployees — admin melihat semua karyawan perusahaannya
// Query param: status=ACTIVE|RESIGNED|PENDING (opsional)
func GetEmployees(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	status := c.Query("status")

	type EmployeeWithPosition struct {
		ID           string  `json:"id"`
		Name         string  `json:"name"`
		Email        string  `json:"email"`
		Phone        string  `json:"phone"`
		BirthPlace   string  `json:"birth_place"`
		BirthDate    string  `json:"birth_date"`
		Address      string  `json:"address"`
		PhotoURL     string  `json:"photo_url"`
		Role         string  `json:"role"`
		Status       string  `json:"status"`
		DeviceID     string  `json:"device_id"`
		PositionID   string  `json:"position_id"`
		PositionName string  `json:"position_name"`
		Salary       float64 `json:"salary"`
	}

	var users []models.User
	query := database.DB.Where("company_id = ? AND role = ?", adminUser.CompanyID, "EMPLOYEE")
	if status != "" {
		query = query.Where("status = ?", status)
	}
	query.Find(&users)

	result := []EmployeeWithPosition{}
	for _, u := range users {
		ep := EmployeeWithPosition{
			ID:         u.ID,
			Name:       u.Name,
			Email:      u.Email,
			Phone:      u.Phone,
			BirthPlace: u.BirthPlace,
			BirthDate:  u.BirthDate,
			Address:    u.Address,
			PhotoURL:   u.PhotoURL,
			Role:       u.Role,
			Status:     u.Status,
			DeviceID:   u.DeviceID,
			PositionID: "",
		}
		if u.PositionID != nil {
			ep.PositionID = *u.PositionID
			var pos models.Position
			if err := database.DB.Where("id = ?", *u.PositionID).First(&pos).Error; err == nil {
				ep.PositionName = pos.Name
				ep.Salary = pos.Salary
			}
		}
		result = append(result, ep)
	}

	utils.Success(c, "Daftar karyawan", result)
}

// FireEmployee — admin memecat/meresign karyawan (soft-delete: status RESIGNED)
func FireEmployee(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		UserID string `json:"user_id"`
		Reason string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.UserID == "" {
		utils.Error(c, "Data tidak valid")
		return
	}

	var user models.User
	if err := database.DB.Where("id = ? AND company_id = ? AND role = ?", body.UserID, adminUser.CompanyID, "EMPLOYEE").First(&user).Error; err != nil {
		utils.Error(c, "Karyawan tidak ditemukan")
		return
	}
	if user.Status == "RESIGNED" {
		utils.Error(c, "Karyawan sudah dalam status RESIGNED")
		return
	}

	user.Status = "RESIGNED"
	// Hapus device ID agar tidak bisa login lagi
	user.DeviceID = ""
	
	// Lepaskan email dan phone agar bisa digunakan mendaftar lagi (Email Release)
	timestamp := time.Now().Unix()
	user.Email = fmt.Sprintf("%s_EX_%d", user.Email, timestamp)
	if user.Phone != "" {
		user.Phone = fmt.Sprintf("%s_EX_%d", user.Phone, timestamp)
	}

	database.DB.Save(&user)

	utils.Success(c, "Karyawan berhasil diberhentikan", gin.H{
		"user_id": user.ID,
		"name":    user.Name,
		"reason":  body.Reason,
	})
}

// ReactivateEmployee — admin mengaktifkan kembali karyawan yang RESIGNED
func ReactivateEmployee(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		UserID string `json:"user_id"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.UserID == "" {
		utils.Error(c, "Data tidak valid")
		return
	}

	var user models.User
	if err := database.DB.Where("id = ? AND company_id = ? AND role = ?", body.UserID, adminUser.CompanyID, "EMPLOYEE").First(&user).Error; err != nil {
		utils.Error(c, "Karyawan tidak ditemukan")
		return
	}
	if user.Status != "RESIGNED" {
		utils.Error(c, "Karyawan bukan dalam status RESIGNED")
		return
	}

	user.Status = "ACTIVE"
	
	// Bersihkan suffix _EX_[timestamp] jika ada untuk mengembalikan email asli
	if strings.Contains(user.Email, "_EX_") {
		parts := strings.Split(user.Email, "_EX_")
		user.Email = parts[0]
	}
	if strings.Contains(user.Phone, "_EX_") {
		parts := strings.Split(user.Phone, "_EX_")
		user.Phone = parts[0]
	}

	database.DB.Save(&user)
	utils.Success(c, "Karyawan berhasil diaktifkan kembali", nil)
}
