package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

// GetTestimonials returns approved testimonials
func GetTestimonials(c *gin.Context) {
	var testimonials []models.Testimonial
	database.DB.Order("created_at desc").Find(&testimonials)
	utils.Success(c, "Success", testimonials)
}

// CreateTestimonial handles guest submission
func CreateTestimonial(c *gin.Context) {
	var input struct {
		Name        string `json:"name" binding:"required"`
		Rating      int    `json:"rating" binding:"required,min=1,max=5"`
		Description string `json:"description" binding:"required"`
		PhotoURL    string `json:"photo_url"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		utils.Error(c, "Invalid input")
		return
	}

	testimonial := models.Testimonial{
		Name:        input.Name,
		Rating:      input.Rating,
		Description: input.Description,
		PhotoURL:    input.PhotoURL,
		IsApproved:  true, 
	}

	if err := database.DB.Create(&testimonial).Error; err != nil {
		utils.Error(c, "Gagal membuat testimoni")
		return
	}

	utils.Success(c, "Testimoni berhasil dikirim", testimonial)
}

// Admin handlers for later
func AdminGetTestimonials(c *gin.Context) {
	var testimonials []models.Testimonial
	database.DB.Order("created_at desc").Find(&testimonials)
	utils.Success(c, "Success", testimonials)
}

func ApproveTestimonial(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Model(&models.Testimonial{}).Where("id = ?", id).Update("is_approved", true).Error; err != nil {
		utils.Error(c, "Gagal menyetujui testimoni")
		return
	}
	utils.Success(c, "Testimoni disetujui", nil)
}

func DeleteTestimonial(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Delete(&models.Testimonial{}, id).Error; err != nil {
		utils.Error(c, "Gagal menghapus testimoni")
		return
	}
	utils.Success(c, "Testimoni dihapus", nil)
}
