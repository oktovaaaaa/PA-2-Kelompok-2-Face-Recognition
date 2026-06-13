package models

import "time"

// Position merepresentasikan jabatan dalam perusahaan.
// Satu jabatan bisa dipegang oleh banyak karyawan.
// Gaji di sini adalah gaji POKOK jabatan.
// Pengurangan gaji per individu disimpan di tabel Attendance.SalaryDeduction.
type Position struct {
	ID        string  `gorm:"primaryKey" json:"id"`
	CompanyID string  `gorm:"index" json:"company_id"`
	Company   Company `gorm:"foreignKey:CompanyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"company,omitempty"`

	Name   string  `json:"name"`
	Salary      float64 `json:"salary"`
	Description string  `json:"description" gorm:"type:text"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
