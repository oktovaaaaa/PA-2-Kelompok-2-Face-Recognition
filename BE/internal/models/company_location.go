package models

import (
	"time"
)

// CompanyLocation menyimpan titik lokasi absensi perusahaan dengan radius tertentu.
type CompanyLocation struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	CompanyID string    `gorm:"index" json:"company_id"`
	Company   Company   `gorm:"foreignKey:CompanyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"company,omitempty"`
	Name      string    `json:"name"` // Contoh: "Kantor Pusat", "Gudang"
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	Radius    float64   `json:"radius"`    // Radius dalam meter
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
