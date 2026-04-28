// internal/models/bonus.go

package models

import "time"

type Bonus struct {
	ID          string    `gorm:"primaryKey" json:"id"`
	UserID      string    `gorm:"index" json:"user_id"`
	User        User      `gorm:"-" json:"user"`
	
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Amount      float64   `json:"amount"`
	
	Date        string    `json:"date"` // format: YYYY-MM-DD
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
