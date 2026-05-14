// internal/models/session.go

package models

import "time"

type Session struct {
	ID        string `gorm:"primaryKey"`
	UserID    string
	Token     string
	DeviceID  string
	DeviceName string
	IsLocked     bool
	LastActiveAt time.Time
	ExpiresAt    time.Time
	CreatedAt    time.Time
}