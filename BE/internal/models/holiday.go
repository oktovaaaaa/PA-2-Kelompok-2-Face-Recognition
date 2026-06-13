package models

import "time"

type Holiday struct {
	ID          string    `gorm:"primaryKey" json:"id"`
	CompanyID   string    `gorm:"index" json:"company_id"`
	Company     Company   `gorm:"foreignKey:CompanyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"company,omitempty"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	StartDate   time.Time `json:"start_date"`
	EndDate     time.Time `json:"end_date"`
	CreatedAt   time.Time `json:"created_at"`
}
