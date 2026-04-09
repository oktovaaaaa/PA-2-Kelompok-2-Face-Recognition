// internal/models/salary.go

package models

import "time"

type Salary struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	UserID    string    `gorm:"uniqueIndex:idx_user_month_year" json:"user_id"`
	User      User      `gorm:"foreignKey:UserID" json:"user"`
	
	Month     int       `gorm:"uniqueIndex:idx_user_month_year" json:"month"` // 1-12
	Year      int       `gorm:"uniqueIndex:idx_user_month_year" json:"year"`
	
	BaseSalary   float64 `json:"base_salary"`
	Deductions   float64 `json:"deductions"`
	Bonuses      float64 `json:"bonuses"`
	TotalSalary  float64 `json:"total_salary"`
	PaidAmount   float64 `json:"paid_amount"`
	DeductionsDetail string `json:"deductions_detail"`
	BonusesDetail    string `json:"bonuses_detail"`
	
	Status       string    `json:"status"` // PENDING | PARTIAL | PAID
	PaymentProof string    `json:"payment_proof"` // URL/Path foto bukti terbaru (Opsional)
	PaidAt       *time.Time `json:"paid_at"`
	
	Payments     []SalaryPayment `gorm:"foreignKey:SalaryID" json:"payments"`
	
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type SalaryPayment struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	SalaryID  string    `gorm:"index" json:"salary_id"`
	Amount    float64   `json:"amount"`
	Proof     string    `json:"proof"`
	PaidAt    time.Time `json:"paid_at"`
	CreatedAt time.Time `json:"created_at"`
}
