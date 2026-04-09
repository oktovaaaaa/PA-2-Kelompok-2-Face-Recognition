// internal/models/company_location.go

package models

import (
	"time"
)

// CompanyLocation menyimpan titik lokasi absensi perusahaan dengan radius tertentu.
type CompanyLocation struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	CompanyID string    `gorm:"index" json:"company_id"`
	Name      string    `json:"name"` // Contoh: "Kantor Pusat", "Gudang"
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	Radius    float64   `json:"radius"`    // Radius dalam meter
	IsActive  bool      `json:"is_active" gorm:"default:true"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
