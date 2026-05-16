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

	// [DEBUG] Log setiap menit untuk memastikan scheduler jalan dan cek waktunya
	fmt.Printf("[Scheduler] Heartbeat: %s %s\n", today, currentTime)

	var settings []models.AttendanceSettings
	// Ambil semua pengaturan absensi perusahaan
	if err := database.DB.Find(&settings).Error; err != nil {
		return
	}

	for _, s := range settings {
		// Pengecekan Waktu
		isCheckInStart := currentTime == s.CheckInStart
		isCheckInLimit10 := currentTime == offsetMinutes(s.CheckInEnd, -10)
		
		isCheckOutStart := currentTime == s.CheckOutStart
		isCheckOutLimit10 := currentTime == offsetMinutes(s.CheckOutEnd, -10)

		// Jika tidak ada yang cocok dengan waktu sekarang, lewati perusahaan ini
		if !isCheckInStart && !isCheckInLimit10 && !isCheckOutStart && !isCheckOutLimit10 {
			continue
		}

		fmt.Printf("[Scheduler] Memproses pengingat untuk Company: %s pada jam %s\n", s.CompanyID, currentTime)

		// [DEBUG] Cek semua user di company ini tanpa filter role/status untuk debug
		var allUsers []models.User
		database.DB.Where("company_id = ?", s.CompanyID).Find(&allUsers)
		fmt.Printf("[Scheduler] Debug Company %s: Total %d user ditemukan di DB\n", s.CompanyID, len(allUsers))
		for _, u := range allUsers {
			fmt.Printf("  - User: %s, Role: %s, Status: %s\n", u.Name, u.Role, u.Status)
		}

		// Ambil semua karyawan aktif di perusahaan ini
		var employees []models.User
		database.DB.Where("company_id = ? AND role = ? AND status = ?", s.CompanyID, "EMPLOYEE", "ACTIVE").Find(&employees)
		
		fmt.Printf("[Scheduler] Ditemukan %d karyawan aktif (Role: EMPLOYEE, Status: ACTIVE) untuk company %s\n", len(employees), s.CompanyID)

		isWorkingDay, _ := checkWorkingStatus(s.CompanyID, today)
		if !isWorkingDay {
			fmt.Printf("[Scheduler] Skip: Bukan hari kerja/libur untuk company %s\n", s.CompanyID)
			continue
		}

		for _, emp := range employees {
			// 1. Pengingat Masuk (Mulai & 10 Menit Sebelum Batas)
			if isCheckInStart || isCheckInLimit10 {
				var att models.Attendance
				err := database.DB.Where("user_id = ? AND date = ?", emp.ID, today).First(&att).Error
				if err != nil || att.CheckInTime == nil {
					title := "⏰ Waktunya Presensi Masuk"
					msg := "Jam kerja telah dimulai. Mohon segera melakukan presensi kehadiran Anda untuk memastikan ketepatan waktu."
					
					if isCheckInLimit10 {
						title = "⚠️ Batas Presensi Masuk Segera Berakhir"
						msg = "Batas waktu presensi masuk akan segera berakhir dalam 10 menit. Mohon segera menyelesaikan presensi Anda."
					}
					fmt.Printf("[Scheduler] Mengirim pengingat masuk ke User: %s (%s)\n", emp.Name, emp.ID)
					SendPushNotification(emp.ID, title, msg)
				} else {
					fmt.Printf("[Scheduler] User %s sudah absen masuk hari ini, skip pengingat.\n", emp.Name)
				}
			}

			// 2. Pengingat Pulang (Mulai & 10 Menit Sebelum Batas)
			if isCheckOutStart || isCheckOutLimit10 {
				var att models.Attendance
				err := database.DB.Where("user_id = ? AND date = ?", emp.ID, today).First(&att).Error
				// Kirim jika sudah CheckIn tapi belum CheckOut
				if err == nil && att.CheckInTime != nil && att.CheckOutTime == nil {
					title := "🏠 Waktunya Presensi Pulang"
					msg := "Jam kerja telah selesai. Mohon pastikan Anda melakukan presensi pulang sebelum meninggalkan area kerja."
					
					if isCheckOutLimit10 {
						title = "🕒 10 Menit Lagi Batas Pulang Berakhir"
						msg = "Batas waktu presensi pulang akan segera berakhir dalam 10 menit. Mohon segera menyelesaikan presensi pulang Anda."
					}
					
					fmt.Printf("[Scheduler] Mengirim pengingat pulang ke User: %s (%s)\n", emp.Name, emp.ID)
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
