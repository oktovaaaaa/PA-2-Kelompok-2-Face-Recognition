package models

import (
	"time"
)

type Testimonial struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	Name        string    `gorm:"not null" json:"name"`
	Rating      int       `gorm:"not null" json:"rating"` // 1-5
	Description string    `gorm:"type:text;not null" json:"description"`
	PhotoURL    string    `json:"photo_url"`
	IsApproved  bool      `gorm:"default:false" json:"is_approved"`
	CreatedAt   time.Time `json:"created_at"`
}
