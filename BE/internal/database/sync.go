// internal/database/sync.go

package database

import (
	"employee-system/internal/models"
	"fmt"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

/*
pemetaan sinkronisasi database (sumber ke target):

sumber database utama:
- dbname: pa2_auth

database target sinkronisasi:
1. dbname: pa2_attendance (absensi)
2. dbname: pa2_payroll (penggajian)

skema duplikasi tabel:
- tabel 'companies' (pa2_auth) ----> diduplikasi ke tabel 'companies' (pa2_attendance & pa2_payroll)
- tabel 'positions' (pa2_auth) ----> diduplikasi ke tabel 'positions' (pa2_attendance & pa2_payroll)
- tabel 'users'     (pa2_auth) ----> diduplikasi ke tabel 'users'     (pa2_attendance & pa2_payroll)

patokan utama sinkronisasi adalah id (uuid) dari masing-masing record pada database pa2_auth.
*/

// SyncCompanyToAttendance menyalin data company dari Auth ke database Attendance secara manual.
func SyncCompanyToAttendance(company models.Company) error {
	// 1. buka koneksi gorm langsung ke database absensi (pa2_attendance)
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_attendance", os.Getenv("DB_PORT"),
	)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}
	// 2. simpan/duplikasi record data company ke database absensi
	return db.Save(&company).Error
}

// SyncCompanyToPayroll menyalin data company dari Auth ke database Payroll secara manual.
func SyncCompanyToPayroll(company models.Company) error {
	// 1. buka koneksi gorm langsung ke database payroll (pa2_payroll)
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_payroll", os.Getenv("DB_PORT"),
	)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}
	// 2. simpan/duplikasi record data company ke database payroll
	return db.Save(&company).Error
}

// SyncPositionToAttendance menyalin data position dari Auth ke database Attendance secara manual.
func SyncPositionToAttendance(position models.Position) error {
	// 1. buka koneksi gorm langsung ke database absensi (pa2_attendance)
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_attendance", os.Getenv("DB_PORT"),
	)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}
	// 2. simpan/duplikasi record data jabatan ke database absensi
	return db.Save(&position).Error
}

// SyncPositionToPayroll menyalin data position dari Auth ke database Payroll secara manual.
func SyncPositionToPayroll(position models.Position) error {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_payroll", os.Getenv("DB_PORT"),
	)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}
	return db.Save(&position).Error
}

// DeleteCompanyToAttendance menghapus data company dari database Attendance.
func DeleteCompanyToAttendance(id string) error {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_attendance", os.Getenv("DB_PORT"),
	)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}
	return db.Delete(&models.Company{}, "id = ?", id).Error
}

// DeleteCompanyToPayroll menghapus data company dari database Payroll.
func DeleteCompanyToPayroll(id string) error {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_payroll", os.Getenv("DB_PORT"),
	)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}
	return db.Delete(&models.Company{}, "id = ?", id).Error
}

// DeletePositionToAttendance menghapus data position dari database Attendance.
func DeletePositionToAttendance(id string) error {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_attendance", os.Getenv("DB_PORT"),
	)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}
	return db.Delete(&models.Position{}, "id = ?", id).Error
}

// DeletePositionToPayroll menghapus data position dari database Payroll.
func DeletePositionToPayroll(id string) error {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_payroll", os.Getenv("DB_PORT"),
	)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}
	return db.Delete(&models.Position{}, "id = ?", id).Error
}

// SyncUserToAttendance menyalin data user dari Auth ke database Attendance secara manual.
// Ini digunakan untuk menjaga prinsip microservices (DB terpisah) tapi data tetap tersinkron.
func SyncUserToAttendance(user models.User) error {
	// 1. Koneksi ke database Attendance (pa2_attendance)
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		"pa2_attendance", // Paksa ke database attendance
		os.Getenv("DB_PORT"),
	)

	attDB, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("gagal koneksi ke DB Attendance untuk sinkronisasi: %v", err)
	}

	// 2. Simpan atau Update data user di database Attendance
	// Kita hanya perlu data dasar untuk pengingat dan relasi
	err = attDB.Save(&user).Error
	if err != nil {
		return fmt.Errorf("gagal simpan user ke DB Attendance: %v", err)
	}

	fmt.Printf("[Sync] User %s (%s) berhasil disinkronkan ke DB Attendance\n", user.Name, user.ID)
	return nil
}

// SyncUserToPayroll menyalin data user dari Auth ke database Payroll secara manual.
func SyncUserToPayroll(user models.User) error {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		"pa2_payroll", os.Getenv("DB_PORT"),
	)

	payDB, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("gagal koneksi ke DB Payroll untuk sinkronisasi: %v", err)
	}

	err = payDB.Save(&user).Error
	if err != nil {
		return fmt.Errorf("gagal simpan user ke DB Payroll: %v", err)
	}

	fmt.Printf("[Sync] User %s (%s) berhasil disinkronkan ke DB Payroll\n", user.Name, user.ID)
	return nil
}

func InitialSyncFromAuth() {
	fmt.Println("[Sync] >>> MEMULAI INITIAL SYNC DARI AUTH DB <<<")

	host := os.Getenv("DB_HOST")
	user := os.Getenv("DB_USER")
	pass := os.Getenv("DB_PASSWORD")
	port := os.Getenv("DB_PORT")

	fmt.Printf("[Sync] Menghubungkan ke %s:%s (DB: pa2_auth)...\n", host, port)

	// Koneksi ke DB Auth
	authDsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		host, user, pass, "pa2_auth", port,
	)
	authDB, err := gorm.Open(postgres.Open(authDsn), &gorm.Config{})
	if err != nil {
		fmt.Printf("[Sync] !!! ERROR KONEKSI DB AUTH: %v\n", err)
		return
	}

	// 1. Sync Companies
	var companies []models.Company
	if err := authDB.Find(&companies).Error; err != nil {
		fmt.Printf("[Sync] !!! ERROR QUERY COMPANY DI AUTH: %v\n", err)
	} else {
		fmt.Printf("[Sync] Ditemukan %d company di database pa2_auth. Mulai menyalin...\n", len(companies))
		for _, c := range companies {
			if err := SyncCompanyToAttendance(c); err != nil {
				fmt.Printf("[Sync] !!! GAGAL menyalin company %s ke Attendance: %v\n", c.Name, err)
			}
			if err := SyncCompanyToPayroll(c); err != nil {
				fmt.Printf("[Sync] !!! GAGAL menyalin company %s ke Payroll: %v\n", c.Name, err)
			}
		}
	}

	// 2. Sync Positions
	var positions []models.Position
	if err := authDB.Find(&positions).Error; err != nil {
		fmt.Printf("[Sync] !!! ERROR QUERY POSITION DI AUTH: %v\n", err)
	} else {
		fmt.Printf("[Sync] Ditemukan %d position di database pa2_auth. Mulai menyalin...\n", len(positions))
		for _, p := range positions {
			if err := SyncPositionToAttendance(p); err != nil {
				fmt.Printf("[Sync] !!! GAGAL menyalin position %s ke Attendance: %v\n", p.Name, err)
			}
			if err := SyncPositionToPayroll(p); err != nil {
				fmt.Printf("[Sync] !!! GAGAL menyalin position %s ke Payroll: %v\n", p.Name, err)
			}
		}
	}

	// 3. Sync Users
	var users []models.User
	if err := authDB.Find(&users).Error; err != nil {
		fmt.Printf("[Sync] !!! ERROR QUERY USER DI AUTH: %v\n", err)
		return
	}

	fmt.Printf("[Sync] Ditemukan %d user di database pa2_auth. Mulai menyalin...\n", len(users))

	for _, u := range users {
		fmt.Printf("[Sync] Menyalin user: %s (Role: %s, Status: %s)\n", u.Name, u.Role, u.Status)

		// Sinkronkan ke Attendance
		if err := SyncUserToAttendance(u); err != nil {
			fmt.Printf("[Sync] !!! GAGAL menyalin %s ke Attendance: %v\n", u.Name, err)
		}

		// Sinkronkan ke Payroll
		if err := SyncUserToPayroll(u); err != nil {
			fmt.Printf("[Sync] !!! GAGAL menyalin %s ke Payroll: %v\n", u.Name, err)
		}
	}
	fmt.Printf("[Sync] >>> INITIAL SYNC SELESAI. %d user berhasil diproses <<<\n", len(users))
}
