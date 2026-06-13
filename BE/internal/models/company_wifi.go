package models

import "time"

// CompanyWifi menyimpan data Wi-Fi resmi yang diperbolehkan untuk absensi karyawan
type CompanyWifi struct {
	ID         string    `gorm:"primaryKey" json:"id"`
	CompanyID  string    `gorm:"index;not null" json:"company_id"`
	Company    Company   `gorm:"foreignKey:CompanyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"company,omitempty"`
	LocationID string    `gorm:"index" json:"location_id"`    // Terkait dengan lokasi kantor tertentu (opsional)
	Location   CompanyLocation `gorm:"foreignKey:LocationID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"location,omitempty"`
	Name       string    `json:"name"`                        // SSID (Nama Wi-Fi)
	BSSID      string    `gorm:"index;not null" json:"bssid"` // MAC Address router
	IsActive   bool      `gorm:"default:true" json:"is_active"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}
