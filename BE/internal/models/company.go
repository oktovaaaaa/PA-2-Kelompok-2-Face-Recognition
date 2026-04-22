// internal/models/company.go

package models

import "time"

type Company struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	Name      string    `json:"name"`
	Address   string    `json:"address"`
	Email     string    `json:"email"`
	Phone     string    `json:"phone"`
	LogoURL   string    `json:"logo_url"`
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	Status    string    `json:"status" gorm:"default:ACTIVE"`
	CreatedAt time.Time `json:"created_at"`
}