package models

import "time"

type InviteToken struct {
	ID        string `gorm:"primaryKey"`
	Token     string
	CompanyID string
	Company   Company `gorm:"foreignKey:CompanyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"company,omitempty"`
	Status    string
	ExpiresAt time.Time
	CreatedAt time.Time
}