package services

import (
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"

	"github.com/google/uuid"
)

func GenerateInvite(companyID string) (models.InviteToken, error) {
	token := uuid.New().String()

	invite := models.InviteToken{
		ID:        uuid.New().String(),
		Token:     token,
		CompanyID: companyID,
		Status:    "UNUSED",
		ExpiresAt: time.Now().Add(3 * time.Hour),
	}

	err := database.DB.Create(&invite).Error
	return invite, err
}