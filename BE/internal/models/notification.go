package models

import "time"

// Notification menyimpan notifikasi in-app.
// UserID adalah penerima notifikasi.
// RefID adalah ID entitas terkait (misal ID LeaveRequest).
// Type: LEAVE_REQUEST | LEAVE_APPROVED | LEAVE_REJECTED
type Notification struct {
	ID        string `gorm:"primaryKey" json:"id"`
	UserID    string `gorm:"index" json:"user_id"`
	User      User   `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"user,omitempty"`
	
	CompanyID string `gorm:"index" json:"company_id"`
	Company   Company `gorm:"foreignKey:CompanyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"company,omitempty"`

	Title string `json:"title"`
	Body  string `json:"body"`

	// LEAVE_REQUEST | LEAVE_APPROVED | LEAVE_REJECTED
	Type string `json:"type"`

	// ID entitas terkait (misal ID izin)
	RefID string `json:"ref_id"`

	IsRead bool `json:"is_read"`

	CreatedAt time.Time `json:"created_at"`
}

