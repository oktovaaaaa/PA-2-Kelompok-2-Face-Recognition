// internal/models/penalty.go

package models

import "time"

type Penalty struct {
	ID          string    `gorm:"primaryKey" json:"id"`
	UserID      string    `gorm:"index" json:"user_id"`
	User        User      `gorm:"-" json:"user"`
	
	Type        string    `json:"type"` // e.g. DAMAGE, CONDUCT, OTHER
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Amount      float64   `json:"amount"`
	Attachment  string    `json:"attachment"` // Optional photo URL
	
	Date        string    `json:"date"` // format: YYYY-MM-DD
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
