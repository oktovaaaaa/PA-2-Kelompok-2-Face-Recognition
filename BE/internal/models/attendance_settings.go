// internal/models/attendance_settings.go

package models

import "time"

// AttendanceSettings menyimpan konfigurasi jam absensi per perusahaan.
// CheckInStart/End: rentang waktu boleh check-in  (format "HH:MM")
// CheckOutStart/End: rentang waktu boleh check-out (format "HH:MM")
// AlphaPenalty: nilai potongan gaji (Rp) per hari tidak hadir (alpha)
type AttendanceSettings struct {
	ID        string `gorm:"primaryKey" json:"id"`
	CompanyID string `gorm:"uniqueIndex" json:"company_id"`

	CheckInStart  string `json:"check_in_start"`  // contoh: "07:00"
	CheckInEnd    string `json:"check_in_end"`    // contoh: "09:00"
	CheckOutStart string `json:"check_out_start"` // contoh: "16:00"
	CheckOutEnd   string `json:"check_out_end"`   // contoh: "18:00"

	AlphaPenalty      float64 `json:"alpha_penalty"`      // Potongan gaji per hari alpha (Rp)
	LatePenalty       float64 `json:"late_penalty"`       // Potongan gaji per hari terlambat (Rp) - Default
	LatePenaltyTiers  string  `json:"late_penalty_tiers"` // JSON array: [{"hours": 1, "penalty": 50000}, ...]
	EarlyLeavePenalty float64 `json:"early_leave_penalty"` // Potongan gaji jika pulang sebelum jam operasional (Rp)

	WorkDays         string  `json:"work_days" gorm:"default:'Monday,Tuesday,Wednesday,Thursday,Friday'"`

	// Geofencing
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Radius    float64 `json:"radius"` // in meters

	UpdatedAt time.Time `json:"updated_at"`
}
