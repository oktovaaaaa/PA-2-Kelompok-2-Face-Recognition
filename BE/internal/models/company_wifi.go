// internal/models/company_wifi.go

package models

import "time"

// CompanyWifi menyimpan data Wi-Fi resmi yang diperbolehkan untuk absensi karyawan
type CompanyWifi struct {
	ID         string    `gorm:"primaryKey" json:"id"`
	CompanyID  string    `gorm:"index;not null" json:"company_id"`
	LocationID string    `gorm:"index" json:"location_id"`    // Terkait dengan lokasi kantor tertentu (opsional)
	Name       string    `json:"name"`                        // SSID (Nama Wi-Fi)
	BSSID      string    `gorm:"index;not null" json:"bssid"` // MAC Address router
	IsActive   bool      `gorm:"default:true" json:"is_active"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}
