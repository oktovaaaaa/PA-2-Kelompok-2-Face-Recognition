package models

import "time"

// Attendance menyimpan data kehadiran harian karyawan.
// SalaryDeduction menyimpan potongan gaji per individu saat alpha — tidak mengubah gaji pokok jabatan.
type Attendance struct {
	ID        string `gorm:"primaryKey" json:"id"`
	UserID    string `gorm:"index" json:"user_id"`
	User      User   `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"user,omitempty"`

	CompanyID string `gorm:"index" json:"company_id"`
	Company   Company `gorm:"foreignKey:CompanyID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"company,omitempty"`

	Date string `json:"date"` // format "YYYY-MM-DD"
	
	// Geofencing Audit info (Check-In)
	CheckInLatitude   float64 `json:"check_in_latitude"`
	CheckInLongitude  float64 `json:"check_in_longitude"`
	CheckInLocationID string  `json:"check_in_location_id"`
	CheckInLocation   CompanyLocation `gorm:"foreignKey:CheckInLocationID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"check_in_location,omitempty"`
	CheckInDistance   float64 `json:"check_in_distance"`

	// Geofencing Audit info (Check-Out)
	CheckOutLatitude   float64 `json:"check_out_latitude"`
	CheckOutLongitude  float64 `json:"check_out_longitude"`
	CheckOutLocationID string  `json:"check_out_location_id"`
	CheckOutLocation   CompanyLocation `gorm:"foreignKey:CheckOutLocationID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"check_out_location,omitempty"`
	CheckOutDistance   float64 `json:"check_out_distance"`

	CheckInTime  *time.Time `json:"check_in_time"`
	CheckOutTime *time.Time `json:"check_out_time"`

	// PRESENT | ABSENT | LEAVE | SICK
	Status string `json:"status"`

	// Potongan gaji untuk karyawan ini pada hari ini (jika alpha)
	SalaryDeduction float64 `json:"salary_deduction"`

	Notes string `json:"notes"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

