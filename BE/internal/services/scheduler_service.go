// internal/services/scheduler_service.go

package services

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"fmt"
	"strings"
	"time"

	"github.com/robfig/cron/v3"
)

// StartScheduler menginisialisasi dan menjalankan background jobs
func StartScheduler() {
	c := cron.New()

	// Jalankan setiap menit untuk mengecek pengingat presensi
	c.AddFunc("* * * * *", func() {
		processAttendanceReminders()
	})

	c.Start()
	fmt.Println("[Scheduler] Background scheduler berhasil dijalankan")
}

func processAttendanceReminders() {
	now := time.Now()
	currentTime := now.Format("15:04")
	today := now.Format("2006-01-02")

	var settings []models.AttendanceSettings
	// Ambil semua pengaturan absensi perusahaan
	if err := database.DB.Find(&settings).Error; err != nil {
		return
	}

	for _, s := range settings {
		// Pengecekan Waktu
		isCheckInTime := currentTime == s.CheckInStart
		isCheckInTime5 := currentTime == offsetMinutes(s.CheckInStart, 5)
		isCheckOutTime := currentTime == s.CheckOutStart
		isCheckOutTime5 := currentTime == offsetMinutes(s.CheckOutStart, 5)

		// Jika tidak ada yang cocok dengan waktu sekarang, lewati perusahaan ini
		if !isCheckInTime && !isCheckInTime5 && !isCheckOutTime && !isCheckOutTime5 {
			continue
		}

		// Ambil semua karyawan aktif di perusahaan ini
		var employees []models.User
		database.DB.Where("company_id = ? AND role = ? AND status = ?", s.CompanyID, "EMPLOYEE", "ACTIVE").Find(&employees)

		// Cek apakah hari ini hari kerja/libur (pindahkan ke luar loop karyawan untuk efisiensi)
		isWorkingDay, _ := checkWorkingStatus(s.CompanyID, today)
		if !isWorkingDay {
			continue
		}

		for _, emp := range employees {
			// Pengingat Masuk
			if isCheckInTime || isCheckInTime5 {
				var att models.Attendance
				err := database.DB.Where("user_id = ? AND date = ?", emp.ID, today).First(&att).Error
				// Kirim jika belum ada record absensi atau belum CheckIn
				if err != nil || att.CheckInTime == nil {
					title := "⏰ Waktunya Presensi Masuk"
					msg := "Kantor sudah dimulai! Yuk segera lakukan presensi agar tetap tepat waktu."
					if isCheckInTime5 {
						msg = "Sudah lewat 5 menit dari jam masuk. Jangan lupa presensi ya!"
					}
					SendPushNotification(emp.ID, title, msg)
				}
			}

			// Pengingat Pulang
			if isCheckOutTime || isCheckOutTime5 {
				var att models.Attendance
				err := database.DB.Where("user_id = ? AND date = ?", emp.ID, today).First(&att).Error
				// Kirim jika sudah CheckIn tapi belum CheckOut
				if err == nil && att.CheckInTime != nil && att.CheckOutTime == nil {
					title := "🏠 Waktunya Presensi Keluar"
					msg := "Sudah jam pulang kantor! Jangan lupa presensi keluar sebelum meninggalkan area ya."
					if isCheckOutTime5 {
						msg = "Kamu belum melakukan presensi keluar. Segera presensi ya agar data kehadiranmu lengkap!"
					}
					SendPushNotification(emp.ID, title, msg)
				}
			}
		}
	}
}

// offsetMinutes menambahkan atau mengurangi menit dari string format "HH:MM"
func offsetMinutes(timeStr string, mins int) string {
	t, err := time.Parse("15:04", timeStr)
	if err != nil {
		return ""
	}
	return t.Add(time.Duration(mins) * time.Minute).Format("15:04")
}

func checkWorkingStatus(companyID string, dateStr string) (bool, string) {
	t, _ := time.Parse("2006-01-02", dateStr)
	dayName := t.Weekday().String()

	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", companyID).First(&settings)

	workDays := settings.WorkDays
	if workDays == "" {
		workDays = "Monday,Tuesday,Wednesday,Thursday,Friday"
	}

	if !strings.Contains(workDays, dayName) {
		return false, dayName + " (Bukan Hari Kerja)"
	}

	var holidays []models.Holiday
	err := database.DB.Where("company_id = ? AND ? >= start_date AND ? <= end_date",
		companyID, dateStr, dateStr).Limit(1).Find(&holidays).Error

	if err == nil && len(holidays) > 0 {
		return false, holidays[0].Name
	}

	return true, ""
}
