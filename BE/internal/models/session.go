package models

import "time"

type Session struct {
	ID        string `gorm:"primaryKey"`
	UserID    string `gorm:"type:varchar(36);index"`
	User      User   `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"user,omitempty"`
	Token     string
	DeviceID  string
	DeviceName string
	IsLocked     bool
	LastActiveAt time.Time
	ExpiresAt    time.Time
	CreatedAt    time.Time
}