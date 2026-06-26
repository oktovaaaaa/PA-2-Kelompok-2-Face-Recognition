package models

import (
	"employee-system/internal/utils"
	"strings"
	"time"

	"gorm.io/gorm"
)

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

// EncryptPrefix digunakan sebagai penanda/marker di database.
// Jika sebuah kolom bernilai teks yang diawali "enc:", artinya data tersebut terenkripsi.
// Ini sangat penting untuk menjaga backward compatibility dengan data lama yang belum terenkripsi.
const EncryptPrefix = "enc:"

// encryptFields mendeteksi jika field sensitif (Nomor Rekening & Face Embedding) berupa teks biasa (plain text),
// lalu mengenkripsinya dengan AES-256-GCM dan menambahkan prefix "enc:".
func (u *User) encryptFields() {
	// 1. Enkripsi Nomor Rekening Bank jika tidak kosong dan belum terenkripsi (tidak diawali "enc:")
	if u.BankAccountNumber != "" && !strings.HasPrefix(u.BankAccountNumber, EncryptPrefix) {
		if encrypted, err := utils.Encrypt(u.BankAccountNumber); err == nil {
			u.BankAccountNumber = EncryptPrefix + encrypted
		}
	}

	// 2. Enkripsi Face Embedding jika tidak kosong dan belum terenkripsi (tidak diawali "enc:")
	if u.FaceEmbedding != "" && !strings.HasPrefix(u.FaceEmbedding, EncryptPrefix) {
		if encrypted, err := utils.Encrypt(u.FaceEmbedding); err == nil {
			u.FaceEmbedding = EncryptPrefix + encrypted
		}
	}
}

// decryptFields mendeteksi jika field sensitif (Nomor Rekening & Face Embedding) diawali penanda "enc:",
// lalu mendekripsinya kembali menjadi teks biasa (plain text).
func (u *User) decryptFields() {
	// 1. Dekripsi Nomor Rekening Bank jika diawali prefix "enc:"
	if strings.HasPrefix(u.BankAccountNumber, EncryptPrefix) {
		cipherText := strings.TrimPrefix(u.BankAccountNumber, EncryptPrefix)
		if decrypted, err := utils.Decrypt(cipherText); err == nil {
			u.BankAccountNumber = decrypted
		}
	}

	// 2. Dekripsi Face Embedding jika diawali prefix "enc:"
	if strings.HasPrefix(u.FaceEmbedding, EncryptPrefix) {
		cipherText := strings.TrimPrefix(u.FaceEmbedding, EncryptPrefix)
		if decrypted, err := utils.Decrypt(cipherText); err == nil {
			u.FaceEmbedding = decrypted
		}
	}
}

// BeforeSave adalah hook GORM yang dipanggil otomatis sebelum data disimpan ke database (Create/Update).
// Fungsi ini memastikan data sensitif diubah menjadi bentuk enkripsi sebelum masuk ke query database.
func (u *User) BeforeSave(tx *gorm.DB) (err error) {
	u.encryptFields()
	return nil
}

// AfterSave adalah hook GORM yang dipanggil otomatis setelah data sukses disimpan ke database.
// Fungsi ini mendekripsikan kembali objek User yang berada di memory ke bentuk teks biasa (plain text).
// Hal ini krusial karena objek User yang sama mungkin akan dikirimkan kembali sebagai JSON response ke Frontend.
func (u *User) AfterSave(tx *gorm.DB) (err error) {
	u.decryptFields()
	return nil
}

// AfterFind adalah hook GORM yang dipanggil otomatis setelah data berhasil dibaca/diambil dari database.
// Fungsi ini secara otomatis mendekripsi data terenkripsi (AES-256-GCM) ke plain text agar siap dipakai
// oleh seluruh fungsi bisnis backend maupun frontend.
func (u *User) AfterFind(tx *gorm.DB) (err error) {
	u.decryptFields()
	return nil
}