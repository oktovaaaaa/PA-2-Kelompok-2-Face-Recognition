// internal/models/leave_request.go

package models

import "time"

// LeaveRequest adalah pengajuan izin atau sakit dari karyawan.
// Soft-delete: karyawan dan admin masing-masing punya flag hapus.
// Data baru benar-benar terhapus dari DB hanya jika kedua flag true.
type LeaveRequest struct {
	ID        string `gorm:"primaryKey" json:"id"`
	UserID    string `gorm:"index" json:"user_id"`
	CompanyID string `gorm:"index" json:"company_id"`

	// IZIN | SAKIT
	Type string `json:"type"`

	Title       string `json:"title"`
	Description string `json:"description"`
	PhotoURL    string `json:"photo_url"`

	// PENDING | APPROVED | REJECTED
	Status    string `json:"status"`
	AdminNote string `json:"admin_note"`

	// Karyawan menyatakan tidak memalsukan data
	ConfirmedHonest bool `json:"confirmed_honest"`

	// Soft-delete per pihak: data benar-benar terhapus hanya jika keduanya true
	IsDeletedByEmployee bool `json:"is_deleted_by_employee"`
	IsDeletedByAdmin    bool   `json:"is_deleted_by_admin"`
	Dates               string `json:"dates"` // Daftar tanggal terpilih (JSON string)

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

