// internal/models/invite_token.go

package models

import "time"

type InviteToken struct {
	ID        string `gorm:"primaryKey"`
	Token     string
	CompanyID string
	Company   Company `gorm:"foreignKey:CompanyID"`
	Status    string
	ExpiresAt time.Time
	CreatedAt time.Time
}