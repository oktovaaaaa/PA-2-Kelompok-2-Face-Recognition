// internal/models/user.go

package models

import "time"

type User struct {
	ID        string `gorm:"primaryKey" json:"id"`

	CompanyID string  `json:"company_id"`
	Company   Company `gorm:"foreignKey:CompanyID" json:"company"`

	PositionID *string   `json:"position_id"`
	Position   Position `gorm:"foreignKey:PositionID" json:"position"`

	Name     string `json:"name"`
	Email    string `gorm:"unique" json:"email"`
	Password string `json:"-"`

	Pin string `json:"-"`

	Phone string `json:"phone"`

	BirthPlace string `json:"birth_place"`
	BirthDate  string `json:"birth_date"`
	Address    string `json:"address"`

	PhotoURL string `json:"photo_url"`
	FcmToken string `json:"fcm_token"`

	Role   string `json:"role"`
	Status string `json:"status"` // PENDING | ACTIVE | REJECTED | RESIGNED

	GoogleID string `json:"google_id"`

	DeviceID string `json:"device_id"`

	BankName          string `json:"bank_name"`
	BankAccountNumber string `json:"bank_account_number"`

	// Face Recognition
	FaceEmbedding string     `gorm:"type:text" json:"face_embedding"`
	FaceUpdatedAt *time.Time `json:"face_updated_at"`

	// For PIN lockout system
	InvalidPinAttempts int        `json:"invalid_pin_attempts"`
	PinLockedUntil     *time.Time `json:"pin_locked_until"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}