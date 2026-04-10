// internal/handlers/attendance_handler.go

package handlers

import (
	"fmt"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"strconv"
	"strings"

	"encoding/json"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"sort"
	"math"
)

// LateTier representasi denda keterlambatan berjenjang (sudah didefinisikan di payroll_handler.go)

// calculateLatePenalty menghitung denda berdasarkan durasi keterlambatan dan tiers
func calculateLatePenalty(now, checkInEnd time.Time, basePenalty float64, tiersJSON string) float64 {
	lateDuration := now.Sub(checkInEnd)
	if lateDuration <= 0 {
		return 0
	}

	// Default ke denda dasar
	penalty := basePenalty

	if tiersJSON != "" {
		var tiers []LateTier
		if err := json.Unmarshal([]byte(tiersJSON), &tiers); err == nil && len(tiers) > 0 {
			// Sort tiers berdasarkan jam (terbesar ke terkecil) untuk cari tier tertinggi yang masuk
			sort.Slice(tiers, func(i, j int) bool {
				return tiers[i].Hours > tiers[j].Hours
			})

			// Hitung jam keterlambatan (pembulatan ke atas: 1 menit telat = jam ke-1)
			lateMinutes := lateDuration.Minutes()
			lateHours := int(lateMinutes / 60)
			if int(lateMinutes)%60 > 0 {
				lateHours++
			}

			// Cari denda yang sesuai
			for _, tier := range tiers {
				if lateHours >= tier.Hours {
					penalty = tier.Penalty
					break
				}
			}
		}
	}

	return penalty
}

// calculateDistance menghitung jarak antara dua titik koordinat (meter) menggunakan rumus Haversine
func calculateDistance(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371000 // Radius bumi dalam meter
	phi1 := lat1 * math.Pi / 180
	phi2 := lat2 * math.Pi / 180
	deltaPhi := (lat2 - lat1) * math.Pi / 180
	deltaLambda := (lon2 - lon1) * math.Pi / 180

	a := math.Sin(deltaPhi/2)*math.Sin(deltaPhi/2) +
		math.Cos(phi1)*math.Cos(phi2)*
			math.Sin(deltaLambda/2)*math.Sin(deltaLambda/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return R * c
}

// isHoliday mengecek apakah tanggal tertentu adalah hari libur (manual atau akhir pekan)
func isHoliday(companyID string, t time.Time) (bool, string) {
	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", companyID).Limit(1).Find(&settings)

	// Cek Hari Kerja (WorkDays)
	// Format: "Monday,Tuesday,Wednesday,Thursday,Friday"
	dayName := t.Weekday().String()
	workDays := settings.WorkDays
	if workDays == "" {
		// Default: Senin - Jumat
		workDays = "Monday,Tuesday,Wednesday,Thursday,Friday"
	}

	if !strings.Contains(workDays, dayName) {
		return true, fmt.Sprintf("%s (Bukan Hari Kerja)", dayName)
	}

	// Cek Tabel Hari Libur
	var holidays []models.Holiday
	// Cari libur yang mencakup tanggal t (Start <= t <= End)
	err := database.DB.Where("company_id = ? AND ? >= start_date AND ? <= end_date",
		companyID, t.Format("2006-01-02"), t.Format("2006-01-02")).Limit(1).Find(&holidays).Error

	if err == nil && len(holidays) > 0 {
		return true, holidays[0].Name
	}

	return false, ""
}

// CheckIn — karyawan melakukan absensi masuk
func CheckIn(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	var req struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, "Koordinat lokasi diperlukan")
		return
	}

	// Cek Geofencing
	var locations []models.CompanyLocation
	database.DB.Where("company_id = ? AND is_active = ?", emp.CompanyID, true).Find(&locations)
	
	if len(locations) == 0 {
		utils.Error(c, "Lokasi absensi belum ditentukan oleh admin")
		return
	}

	var validLoc *models.CompanyLocation
	var minDistance float64 = -1

	for i, loc := range locations {
		dist := calculateDistance(req.Latitude, req.Longitude, loc.Latitude, loc.Longitude)
		if dist <= loc.Radius {
			validLoc = &locations[i]
			minDistance = dist
			break // Berhasil menemukan lokasi yang valid
		}
		if minDistance == -1 || dist < minDistance {
			minDistance = dist
		}
	}

	if validLoc == nil {
		utils.Error(c, fmt.Sprintf("Anda berada di luar radius absensi. Jarak terdekat: %.0f meter.", minDistance))
		return
	}

	// Cek Hari Libur
	if holiday, msg := isHoliday(emp.CompanyID, time.Now()); holiday {
		utils.Error(c, "Hari ini libur: "+msg)
		return
	}

	now := time.Now()
	today := now.Format("2006-01-02")

	// Ambil pengaturan jam absensi
	var settingsList []models.AttendanceSettings
	database.DB.Where("company_id = ?", emp.CompanyID).Limit(1).Find(&settingsList)
	if len(settingsList) == 0 {
		utils.Error(c, "Pengaturan waktu absensi belum dikonfigurasi")
		return
	}
	settings := settingsList[0]

	// Validasi waktu check-in
	if now.Before(parseT(today, settings.CheckInStart, now.Location())) {
		utils.Error(c, fmt.Sprintf("Absensi masuk belum dibuka. Mulai jam %s", settings.CheckInStart))
		return
	}
	if now.After(parseT(today, settings.CheckOutEnd, now.Location())) {
		utils.Error(c, "Batas waktu absensi untuk hari ini sudah berakhir (Alpha)")
		return
	}

	// Tentukan Status: LATE jika lewat dari CheckInEnd
	status := "PRESENT"
	var deduction float64 = 0
	checkInEndT := parseT(today, settings.CheckInEnd, now.Location())

	if now.After(checkInEndT) {
		status = "LATE"
		deduction = calculateLatePenalty(now, checkInEndT, settings.LatePenalty, settings.LatePenaltyTiers)
	}

	// Cek apakah sudah check-in hari ini
	var existingList []models.Attendance
	database.DB.Where("user_id = ? AND date = ?", emp.ID, today).Limit(1).Find(&existingList)
	if len(existingList) > 0 {
		if existingList[0].CheckInTime != nil {
			utils.Error(c, "Kamu sudah melakukan check-in hari ini")
			return
		}
	}

	upsertCheckIn(emp.ID, emp.CompanyID, today, now, status, deduction, req.Latitude, req.Longitude, validLoc.ID, minDistance)
	utils.Success(c, "Check-in berhasil", gin.H{
		"check_in_time": now.Format("15:04:05"),
		"date":          today,
		"location":      validLoc.Name,
		"distance":      fmt.Sprintf("%.0f m", minDistance),
	})
}

// CheckOut — karyawan melakukan absensi pulang
func CheckOut(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	var req struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error(c, "Koordinat lokasi diperlukan")
		return
	}

	// Cek Geofencing
	var locations []models.CompanyLocation
	database.DB.Where("company_id = ? AND is_active = ?", emp.CompanyID, true).Find(&locations)
	
	if len(locations) == 0 {
		utils.Error(c, "Lokasi absensi belum ditentukan oleh admin")
		return
	}

	var validLoc *models.CompanyLocation
	var minDistance float64 = -1

	for i, loc := range locations {
		dist := calculateDistance(req.Latitude, req.Longitude, loc.Latitude, loc.Longitude)
		if dist <= loc.Radius {
			validLoc = &locations[i]
			minDistance = dist
			break
		}
		if minDistance == -1 || dist < minDistance {
			minDistance = dist
		}
	}

	if validLoc == nil {
		utils.Error(c, fmt.Sprintf("Anda berada di luar radius absensi. Jarak terdekat: %.0f meter.", minDistance))
		return
	}

	now := time.Now()
	today := now.Format("2006-01-02")

	// Cek Hari Libur
	if holiday, msg := isHoliday(emp.CompanyID, now); holiday {
		utils.Error(c, "Hari ini libur: "+msg)
		return
	}

	// Ambil pengaturan jam absensi
	var settingsList []models.AttendanceSettings
	database.DB.Where("company_id = ?", emp.CompanyID).Limit(1).Find(&settingsList)
	
	var settings models.AttendanceSettings
	if len(settingsList) > 0 {
		settings = settingsList[0]
	} else {
		settings = models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
		}
	}

	// Validasi waktu check-out
	checkOutStartT := parseT(today, settings.CheckOutStart, now.Location())
	checkOutEndT := parseT(today, settings.CheckOutEnd, now.Location())

	isEarlyLeave := false
	if now.Before(checkOutStartT) {
		isEarlyLeave = true
	}

	if now.After(checkOutEndT) {
		utils.Error(c, "Batas waktu absensi untuk hari ini sudah berakhir (Alpha)")
		return
	}

	// Pastikan sudah check-in
	var att models.Attendance
	if err := database.DB.Where("user_id = ? AND date = ?", emp.ID, today).First(&att).Error; err != nil {
		utils.Error(c, "Kamu belum melakukan check-in hari ini")
		return
	}
	if att.CheckInTime == nil {
		utils.Error(c, "Kamu belum melakukan check-in hari ini")
		return
	}
	if att.CheckOutTime != nil {
		utils.Error(c, "Kamu sudah melakukan check-out hari ini")
		return
	}

	att.CheckOutTime = &now
	if isEarlyLeave {
		if att.Status == "LATE" {
			att.Status = "LATE_EARLY_LEAVE"
		} else {
			att.Status = "EARLY_LEAVE"
		}
		att.SalaryDeduction += settings.EarlyLeavePenalty
	}

	// Update audit fields for check-out
	att.CheckOutLatitude = req.Latitude
	att.CheckOutLongitude = req.Longitude
	att.CheckOutLocationID = validLoc.ID
	att.CheckOutDistance = minDistance

	database.DB.Save(&att)

	utils.Success(c, "Check-out berhasil", gin.H{
		"check_out_time": now.Format("15:04:05"),
		"date":           today,
		"location":       validLoc.Name,
		"distance":       fmt.Sprintf("%.0f m", minDistance),
	})
}

// GetTodayAttendance — status absensi karyawan hari ini
func GetTodayAttendance(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	today := time.Now().Format("2006-01-02")
	var attList []models.Attendance
	database.DB.Where("user_id = ? AND date = ?", emp.ID, today).Limit(1).Find(&attList)
	
	var att models.Attendance
	if len(attList) > 0 {
		att = attList[0]
	}

	// Ambil pengaturan jam absensi (dengan fallback)
	var settingsList []models.AttendanceSettings
	database.DB.Where("company_id = ?", emp.CompanyID).Limit(1).Find(&settingsList)
	
	var settings models.AttendanceSettings
	if len(settingsList) > 0 {
		settings = settingsList[0]
	} else {
		settings = models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
		}
	}

	// Hitung status tampilan dinamis
	displayStatus := att.Status
	now := time.Now()
	loc := now.Location()

	// Cek Hari Libur
	if holiday, msg := isHoliday(emp.CompanyID, now); holiday {
		utils.Success(c, "Hari ini libur", gin.H{
			"status":       "HOLIDAY",
			"holiday_name": msg,
		})
		return
	}

	if len(attList) == 0 { // Belum ada record absensi hari ini
		if now.Before(parseT(today, settings.CheckInStart, loc)) {
			displayStatus = "NOT_STARTED" // Label: Belum Mulai
		} else if now.After(parseT(today, settings.CheckOutEnd, loc)) {
			displayStatus = "ABSENT" // Label: Alpha (Hanya jika benar-benar lewat hari/jam pulang)
		} else if now.After(parseT(today, settings.CheckInEnd, loc)) {
			displayStatus = "LATE" // Label: Terlambat
		} else {
			displayStatus = "READY" // Siap Absen
		}
	} else if att.CheckOutTime == nil { // Sudah check-in tapi belum check-out
		if now.After(parseT(today, settings.CheckOutEnd, loc)) {
			if att.Status == "LATE" {
				displayStatus = "LATE_EARLY_LEAVE"
			} else {
				displayStatus = "EARLY_LEAVE"
			}
		}
	}

	// Hitung total denda dan bonus bulan ini untuk estimasi gaji
	var totalDeductionMonth float64
	var totalBonusMonth float64

	// Gunakan logika bersama agar sinkron dengan tab Gaji
	// Ini akan menghitung semua denda absensi + denda manual + denda Alpha otomatis + Bonus
	totalDeductionMonth, totalBonusMonth, _, _ = CalculateAdjustments(emp.ID, int(now.Month()), now.Year())

	// [NEW] Terakhir, ambil TotalSalary final dari tabel salaries agar dashboard 100% konsisten
	var salary models.Salary
	database.DB.Where("user_id = ? AND month = ? AND year = ?", emp.ID, int(now.Month()), now.Year()).First(&salary)
	estimatedTotalSalary := salary.TotalSalary

	utils.Success(c, "Status absensi hari ini", gin.H{
		"date":                   today,
		"attendance":             att,
		"has_record":             len(attList) > 0,
		"settings":               settings,
		"current_time":           now.Format("15:04:05"),
		"display_status":         displayStatus,
		"total_deduction_month":  totalDeductionMonth,
		"total_bonus_month":      totalBonusMonth,
		"estimated_total_salary": estimatedTotalSalary,
	})
}

// GetMyAttendanceHistory — riwayat absensi karyawan sendiri
// Query params: filter=week|month|year
func GetMyAttendanceHistory(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)
	// Refresh from DB agar data CreatedAt 100% akurat
	database.DB.First(&emp, "id = ?", emp.ID)

	filter := c.Query("filter")
	month := c.Query("month")
	year := c.Query("year")

	query := database.DB.Where("user_id = ?", emp.ID)

	if year != "" {
		if month != "" {
			mInt, _ := strconv.Atoi(month)
			pattern := fmt.Sprintf("%s-%02d%%", year, mInt)
			query = query.Where("date LIKE ?", pattern)
		} else {
			pattern := fmt.Sprintf("%s-%%", year)
			query = query.Where("date LIKE ?", pattern)
		}
	} else {
		if filter == "" {
			filter = "month"
		}
		start := getFilterStart(filter)
		query = query.Where("date >= ?", start)
	}

	var records []models.Attendance
	query.Order("date desc").Find(&records)

	// --- Dinamis: Tambahkan record ALPHA untuk hari kerja yang terlewat ---
	// 1. Tentukan tanggal awal & akhir untuk pengecekan
	var startT, endT time.Time
	now := time.Now()

	if year != "" {
		yInt, _ := strconv.Atoi(year)
		if month != "" {
			mInt, _ := strconv.Atoi(month)
			startT = time.Date(yInt, time.Month(mInt), 1, 0, 0, 0, 0, time.Local)
			endT = startT.AddDate(0, 1, -1)
		} else {
			startT = time.Date(yInt, 1, 1, 0, 0, 0, 0, time.Local)
			endT = time.Date(yInt, 12, 31, 0, 0, 0, 0, time.Local)
		}
	} else {
		startS := getFilterStart(filter)
		startT, _ = time.Parse("2006-01-02", startS)
		endT = now
	}

	if endT.After(now) {
		endT = now // Jangan cek masa depan
	}

	// 2. Map record yang ada untuk lookup cepat
	existingDates := make(map[string]bool)
	for _, r := range records {
		existingDates[r.Date] = true
	}

	// 3. Ambil pengaturan untuk denda Alpha
	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", emp.CompanyID).First(&settings)

	// 4. Loop setiap tanggal dalam range
	for d := startT; !d.After(endT); d = d.AddDate(0, 0, 1) {
		dateStr := d.Format("2006-01-02")

		// Jangan denda Alpha jika tanggalnya sebelum user bergabung/dibuat
		if dateStr < emp.CreatedAt.Format("2006-01-02") {
			continue
		}

		// Jika belum ada record dan bukan hari ini yang belum selesai
		if !existingDates[dateStr] {
			// Cek apakah hari libur/akhir pekan
			holiday, _ := isHoliday(emp.CompanyID, d)
			if !holiday {
				// Cek jam operasional jika itu hari ini
				if dateStr == now.Format("2006-01-02") {
					loc := now.Location()
					checkOutEnd := parseT(dateStr, settings.CheckOutEnd, loc)
					if now.Before(checkOutEnd) {
						continue // Masih bisa absen, jangan dianggap alpha dulu
					}
				}

				// Tambahkan record Alpha virtual
				records = append(records, models.Attendance{
					Date:            dateStr,
					Status:          "ABSENT",
					SalaryDeduction: settings.AlphaPenalty,
				})
			}
		}
	}

	// Urutkan kembali berdasarkan tanggal terbaru (descending)
	sort.Slice(records, func(i, j int) bool {
		return records[i].Date > records[j].Date
	})

	// Hitung statistik & Sinkronisasi detail record (Telat & Pulang Awal)
	var present, absent, leave, sick, late, earlyLeave int
	for i := range records {
		r := &records[i]

		// 1. Sinkronisasi Status & Denda Dinamis untuk Record (Jika lupa Check-Out atau Pulang Awal)
		if r.CheckInTime != nil {
			// Hitung Denda Keterlambatan (Jika belum tercatat di DB atau untuk memastikan akurasi)
			checkInEnd := parseT(r.Date, settings.CheckInEnd, now.Location())
			lateDeduction := 0.0
			if r.CheckInTime.After(checkInEnd) {
				lateDeduction = calculateLatePenalty(*r.CheckInTime, checkInEnd, settings.LatePenalty, settings.LatePenaltyTiers)
			}

			// Deteksi Pulang Awal (Lupa Check-out atau Check-out terlalu cepat)
			isEarly := false
			if r.CheckOutTime == nil {
				// Lupa check-out: Cek apakah sudah lewat jam operasional
				if r.Date < now.Format("2006-01-02") || (r.Date == now.Format("2006-01-02") && now.After(parseT(r.Date, settings.CheckOutEnd, now.Location()))) {
					isEarly = true
				}
			} else {
				// Sudah check-out: Cek apakah sebelum waktu yang ditentukan
				if r.CheckOutTime.Before(parseT(r.Date, settings.CheckOutStart, now.Location())) {
					isEarly = true
				}
			}

			// Update Status & Gabungkan Denda (Telat + Pulang Awal)
			if isEarly {
				if r.Status == "LATE" || lateDeduction > 0 {
					r.Status = "LATE_EARLY_LEAVE"
					r.SalaryDeduction = lateDeduction + settings.EarlyLeavePenalty
				} else {
					r.Status = "EARLY_LEAVE"
					r.SalaryDeduction = settings.EarlyLeavePenalty
				}
			} else if lateDeduction > 0 {
				r.Status = "LATE"
				r.SalaryDeduction = lateDeduction
			}
		}

		// 2. Hitung Statistik berdasarkan status akhir
		switch r.Status {
		case "PRESENT":
			present++
		case "ABSENT":
			absent++
		case "LEAVE":
			leave++
		case "SICK":
			sick++
		case "LATE":
			late++
		case "EARLY_LEAVE":
			earlyLeave++
		case "LATE_EARLY_LEAVE":
			late++
			earlyLeave++
		}
	}

	utils.Success(c, "Riwayat kehadiran", gin.H{
		"records": records,
		"stats": gin.H{
			"present": present,
			"absent":  absent,
			"leave":   leave,
			"sick":    sick,
			"late":    late,
			"early_leave": earlyLeave,
			"total":   len(records),
		},
	})
}

// AdminGetAttendanceHistory — admin melihat riwayat semua karyawan
func AdminGetAttendanceHistory(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	startDate := c.Query("start_date")
	endDate := c.Query("end_date")
	filter := c.DefaultQuery("filter", "month")
	userID := c.Query("user_id")
	statusFilter := c.Query("status") // Misal: PRESENT, LATE, ABSENT, LEAVE, SICK

	now := time.Now()
	loc := now.Location()
	today := now.Format("2006-01-02")

	// Ambil Pengaturan (dengan fallback default agar tidak Alpha prematur)
	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", adminUser.CompanyID).First(&settings).Error; err != nil {
		settings = models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
		}
	}
	checkOutEndT := parseT(today, settings.CheckOutEnd, loc)

	// Cari tanggal absensi pertama kali di perusahaan ini sebagai batas awal "System Active"
	var firstRecordDate string
	database.DB.Model(&models.Attendance{}).Where("company_id = ?", adminUser.CompanyID).Order("date asc").Limit(1).Select("date").Scan(&firstRecordDate)

	// 1. Ambil Semua Karyawan Aktif Perusahaan ini
	var employees []models.User
	empQuery := database.DB.Where("company_id = ? AND role = ? AND status = ?", adminUser.CompanyID, "EMPLOYEE", "ACTIVE")
	if userID != "" {
		empQuery = empQuery.Where("id = ?", userID)
	}
	empQuery.Find(&employees)

	// 2. Tentukan Rentang Tanggal
	var start, end string
	specificMonth := c.Query("month") // 1-12
	specificYear := c.Query("year")   // e.g. 2024

	if startDate != "" && endDate != "" {
		start = startDate
		end = endDate
	} else if filter == "year" && specificYear != "" {
		start = fmt.Sprintf("%s-01-01", specificYear)
		end = fmt.Sprintf("%s-12-31", specificYear)
	} else if filter == "month" && specificMonth != "" {
		yearStr := specificYear
		if yearStr == "" {
			yearStr = fmt.Sprintf("%d", now.Year())
		}
		monthInt, _ := strconv.Atoi(specificMonth)
		// Cari tanggal terakhir dari bulan tersebut
		firstDay := time.Date(now.Year(), time.Month(monthInt), 1, 0, 0, 0, 0, loc)
		if specificYear != "" {
			y, _ := strconv.Atoi(specificYear)
			firstDay = time.Date(y, time.Month(monthInt), 1, 0, 0, 0, 0, loc)
		}
		lastDay := firstDay.AddDate(0, 1, -1)

		start = firstDay.Format("2006-01-02")
		end = lastDay.Format("2006-01-02")
	} else {
		start = getFilterStart(filter)
		end = today
	}

	// 3. Ambil Data Absensi yang Ada dari DB
	query := database.DB.Where("company_id = ? AND date >= ? AND date <= ?", adminUser.CompanyID, start, end)
	if userID != "" {
		query = query.Where("user_id = ?", userID)
	}
	var records []models.Attendance
	query.Order("date desc").Find(&records)

	// Buat map untuk memudahkan pengecekan: date -> user_id -> record
	recordMap := make(map[string]map[string]models.Attendance)
	for _, r := range records {
		if recordMap[r.Date] == nil {
			recordMap[r.Date] = make(map[string]models.Attendance)
		}
		recordMap[r.Date][r.UserID] = r
	}

	// 4. Struktur Hasil
	type AttendanceResult struct {
		models.Attendance
		UserName  string `json:"user_name"`
		UserEmail string `json:"user_email"`
		PhotoURL  string `json:"photo_url"`
		IsVirtual bool   `json:"is_virtual"` // Penanda data ini Alpha otomatis
	}
	var finalResult []AttendanceResult

	// Iterasi Hari dari 'end' ke 'start' (Terbaru ke Terlama)
	curr, _ := time.ParseInLocation("2006-01-02", end, loc)
	limit, _ := time.ParseInLocation("2006-01-02", start, loc)

	for !curr.Before(limit) {
		dateStr := curr.Format("2006-01-02")

		// Lewati jika sebelum sistem aktif (absen pertama perusahaan)
		if firstRecordDate != "" && dateStr < firstRecordDate {
			curr = curr.AddDate(0, 0, -1)
			continue
		}

		for _, emp := range employees {
			att, exists := recordMap[dateStr][emp.ID]

			if exists {
				// Deteksi status dinamis untuk riwayat (WORKING / EARLY_LEAVE)
				displayStatus := att.Status
				isPastTime := dateStr < today || (dateStr == today && now.After(checkOutEndT))

				if att.CheckInTime != nil {
					// Hitung denda telat secara dinamis
					checkInEnd := parseT(att.Date, settings.CheckInEnd, loc)
					lateDeduction := 0.0
					if att.CheckInTime.After(checkInEnd) {
						lateDeduction = calculateLatePenalty(*att.CheckInTime, checkInEnd, settings.LatePenalty, settings.LatePenaltyTiers)
					}

					// Deteksi Pulang Awal (Lupa Check-out atau Check-out dini)
					isEarly := false
					if att.CheckOutTime == nil {
						if isPastTime {
							isEarly = true
						}
					} else {
						if att.CheckOutTime.Before(parseT(att.Date, settings.CheckOutStart, loc)) {
							isEarly = true
						}
					}

					// Sinkronisasi status & denda gabungan
					if isEarly {
						if att.Status == "LATE" || lateDeduction > 0 {
							displayStatus = "LATE_EARLY_LEAVE"
							att.SalaryDeduction = lateDeduction + settings.EarlyLeavePenalty
						} else {
							displayStatus = "EARLY_LEAVE"
							att.SalaryDeduction = settings.EarlyLeavePenalty
						}
					} else if lateDeduction > 0 {
						displayStatus = "LATE"
						att.SalaryDeduction = lateDeduction
					} else if att.CheckOutTime == nil {
						displayStatus = "WORKING"
					}
				}

				if statusFilter == "" || displayStatus == statusFilter {
					// Copy record agar tidak merubah data asli di Map
					newAtt := att
					newAtt.Status = displayStatus

					finalResult = append(finalResult, AttendanceResult{
						Attendance: newAtt,
						UserName:   emp.Name,
						UserEmail:  emp.Email,
						PhotoURL:   emp.PhotoURL,
						IsVirtual:  false,
					})
				}
			} else {
				// Cegah Alpha untuk tanggal sebelum karyawan didaftarkan (Gunakan Zona Waktu Lokal)
				registrationDate := emp.CreatedAt.In(loc).Format("2006-01-02")
				if dateStr < registrationDate {
					continue
				}

				// Cek apakah hari ini Alpha (Sudah lewat jam pulang / Hari sudah lewat)
				isAlpha := false
				if dateStr < today {
					isAlpha = true
				} else if dateStr == today && now.After(checkOutEndT) {
					isAlpha = true
				}

				if isAlpha && (statusFilter == "" || statusFilter == "ABSENT") {
					finalResult = append(finalResult, AttendanceResult{
						Attendance: models.Attendance{
							ID:        "virtual-" + emp.ID + "-" + dateStr,
							UserID:    emp.ID,
							CompanyID: emp.CompanyID,
							Date:      dateStr,
							Status:    "ABSENT",
							SalaryDeduction: settings.AlphaPenalty,
						},
						UserName:  emp.Name,
						UserEmail: emp.Email,
						PhotoURL:  emp.PhotoURL,
						IsVirtual: true,
					})
				} else if !isAlpha && dateStr == today && (statusFilter == "" || statusFilter == "ALL") {
					// Tambahkan entri "Belum Absen" untuk hari ini
					finalResult = append(finalResult, AttendanceResult{
						Attendance: models.Attendance{
							ID:        "yet-" + emp.ID + "-" + dateStr,
							UserID:    emp.ID,
							CompanyID: emp.CompanyID,
							Date:      dateStr,
							Status:    "NOT_YET",
						},
						UserName:  emp.Name,
						UserEmail: emp.Email,
						PhotoURL:  emp.PhotoURL,
						IsVirtual: true,
					})
				}
			}
		}
		curr = curr.AddDate(0, 0, -1)
	}

	utils.Success(c, "Riwayat kehadiran karyawan", finalResult)
}

// GetAttendanceSettings — admin mendapatkan pengaturan jam absensi
func GetAttendanceSettings(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", adminUser.CompanyID).First(&settings).Error; err != nil {
		// Kembalikan default jika belum ada
		utils.Success(c, "Pengaturan absensi (default)", models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
			AlphaPenalty:  0,
			LatePenalty:   0,
			Latitude:      0,
			Longitude:     0,
			Radius:        100, // Default 100 meter
		})
		return
	}
	utils.Success(c, "Pengaturan absensi", settings)
}

// AdminBulkDeleteAttendance — admin menghapus riwayat absensi massal berdasarkan filter
func AdminBulkDeleteAttendance(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	filter := c.Query("filter")
	year := c.Query("year")
	month := c.Query("month")
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	query := database.DB.Where("company_id = ?", adminUser.CompanyID)

	switch filter {
	case "month":
		if month != "" && year != "" {
			query = query.Where("date LIKE ?", year+"-"+fmt.Sprintf("%02s", month)+"-%")
		}
	case "year":
		if year != "" {
			query = query.Where("date LIKE ?", year+"-%")
		}
	case "custom":
		if startDate != "" && endDate != "" {
			query = query.Where("date BETWEEN ? AND ?", startDate, endDate)
		}
	}

	if err := query.Delete(&models.Attendance{}).Error; err != nil {
		utils.Error(c, "Gagal menghapus riwayat kehadiran")
		return
	}

	utils.Success(c, "Riwayat kehadiran berhasil dihapus", nil)
}

// UpdateAttendanceSettings — admin mengubah pengaturan jam absensi & denda alpha
func UpdateAttendanceSettings(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		CheckInStart     string      `json:"check_in_start"`
		CheckInEnd       string      `json:"check_in_end"`
		CheckOutStart    string      `json:"check_out_start"`
		CheckOutEnd      string      `json:"check_out_end"`
		AlphaPenalty      float64     `json:"alpha_penalty"`
		LatePenalty       float64     `json:"late_penalty"`
		LatePenaltyTiers  interface{} `json:"late_penalty_tiers"`
		EarlyLeavePenalty float64     `json:"early_leave_penalty"`
		WorkDays          string      `json:"work_days"`
		Latitude         float64     `json:"latitude"`
		Longitude        float64     `json:"longitude"`
		Radius           float64     `json:"radius"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid: "+err.Error())
		return
	}

	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", adminUser.CompanyID).First(&settings)

	if settings.ID == "" {
		settings.ID = uuid.New().String()
		settings.CompanyID = adminUser.CompanyID
	}
	settings.CheckInStart = body.CheckInStart
	settings.CheckInEnd = body.CheckInEnd
	settings.CheckOutStart = body.CheckOutStart
	settings.CheckOutEnd = body.CheckOutEnd
	settings.AlphaPenalty = body.AlphaPenalty
	settings.LatePenalty = body.LatePenalty
	settings.EarlyLeavePenalty = body.EarlyLeavePenalty
	settings.WorkDays = body.WorkDays
	settings.Latitude = body.Latitude
	settings.Longitude = body.Longitude
	settings.Radius = body.Radius
	settings.Latitude = body.Latitude
	settings.Longitude = body.Longitude
	settings.Radius = body.Radius

	// Handle LatePenaltyTiers flexibly (string or array)
	switch v := body.LatePenaltyTiers.(type) {
	case string:
		settings.LatePenaltyTiers = v
	default:
		tiersJSON, _ := json.Marshal(v)
		settings.LatePenaltyTiers = string(tiersJSON)
	}

	if err := database.DB.Save(&settings).Error; err != nil {
		utils.Error(c, "Gagal menyimpan pengaturan: "+err.Error())
		return
	}
	utils.Success(c, "Pengaturan absensi berhasil diperbarui", settings)
}

// AdminGetDashboardSummary — ringkasan status absensi hari ini untuk dashboard admin
func AdminGetDashboardSummary(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)
	now := time.Now()
	loc := now.Location()
	today := now.Format("2006-01-02")

	// Cek Hari Libur
	isHold, holdName := isHoliday(admin.CompanyID, now)

	// Ambil pengaturan jam absensi (dengan fallback default)
	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", admin.CompanyID).First(&settings).Error; err != nil {
		settings = models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
		}
	}
	checkOutEndT := parseT(today, settings.CheckOutEnd, loc)

	var present, late, leave, sick, working, lateEarlyLeave, earlyLeave int64

	// 1. Hitung yang sudah SELESAI (sudah check-out)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ? AND check_out_time IS NOT NULL", admin.CompanyID, today, "PRESENT").Count(&present)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ? AND check_out_time IS NOT NULL", admin.CompanyID, today, "LATE").Count(&late)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ? AND check_out_time IS NOT NULL", admin.CompanyID, today, "EARLY_LEAVE").Count(&earlyLeave)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ? AND check_out_time IS NOT NULL", admin.CompanyID, today, "LATE_EARLY_LEAVE").Count(&lateEarlyLeave)

	// 2. Hitung yang SEDANG BEKERJA (sudah check-in tapi belum check-out)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND (status = ? OR status = ?) AND check_out_time IS NULL", admin.CompanyID, today, "PRESENT", "LATE").Count(&working)

	// 3. Izin & Sakit
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ?", admin.CompanyID, today, "LEAVE").Count(&leave)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ?", admin.CompanyID, today, "SICK").Count(&sick)

	// 4. Total Karyawan Aktif
	var totalEmployees int64
	database.DB.Model(&models.User{}).Where("company_id = ? AND status = ? AND role = ?", admin.CompanyID, "ACTIVE", "EMPLOYEE").Count(&totalEmployees)

	// 5. Logika Alpha vs Belum Absen vs Pulang di Jam Kerja
	var absentCount, notYetCount, earlyLeaveCount, lateEarlyLeaveCount, displayWorking int64
	totalCheckedIn := present + late + working + leave + sick + lateEarlyLeave + earlyLeave
	notCheckedInYet := totalEmployees - totalCheckedIn
	if notCheckedInYet < 0 {
		notCheckedInYet = 0
	}

	lateEarlyLeaveCount = lateEarlyLeave

	if now.After(checkOutEndT) {
		// Jika sudah lewat jam pulang:
		if isHold {
			absentCount = 0
		} else {
			absentCount = notCheckedInYet
		}
		// Dinamis: Yang masih 'working' dianggap Pulang di Jam Kerja (karena jam operasional sudah habis)
		var workingLate int64
		database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ? AND check_out_time IS NULL", admin.CompanyID, today, "LATE").Count(&workingLate)
		
		earlyLeaveCount = earlyLeave + (working - workingLate)
		lateEarlyLeaveCount = lateEarlyLeave + workingLate
		
		displayWorking = 0
		notYetCount = 0
	} else {
		// Jika masih dalam jam kerja:
		absentCount = 0
		earlyLeaveCount = earlyLeave
		displayWorking = working
		notYetCount = notCheckedInYet
		if isHold {
			notYetCount = 0
		}
		lateEarlyLeaveCount = lateEarlyLeave
	}

	utils.Success(c, "Dashboard summary", gin.H{
		"present":            present,
		"late":               late,
		"absent":             absentCount,
		"leave":              leave,
		"sick":               sick,
		"working":            displayWorking,
		"not_yet":            notYetCount,
		"early_leave":        earlyLeaveCount,
		"late_early_leave":   lateEarlyLeaveCount,
		"late_early_leave_label": "Terlambat & Pulang di Jam Kerja",
		"total":              totalEmployees,
		"is_after_work_hour": now.After(checkOutEndT),
		"is_holiday":         isHold,
		"holiday_name":       holdName,
	})
}

// ===== HELPER FUNCTIONS =====

// isTimeInRange mengecek apakah waktu now berada di antara start dan end (format "HH:MM")
func isTimeInRange(now time.Time, start, end string) bool {
	loc := now.Location()
	todayStr := now.Format("2006-01-02")

	s := parseT(todayStr, start, loc)
	e := parseT(todayStr, end, loc)
	return (now.Equal(s) || now.After(s)) && (now.Equal(e) || now.Before(e))
}

// getFilterStart mengembalikan tanggal awal berdasarkan filter
func getFilterStart(filter string) string {
	now := time.Now()
	switch filter {
	case "today":
		return now.Format("2006-01-02")
	case "week":
		weekday := int(now.Weekday())
		if weekday == 0 {
			weekday = 7
		}
		start := now.AddDate(0, 0, -(weekday - 1))
		return start.Format("2006-01-02")
	case "year":
		return fmt.Sprintf("%d-01-01", now.Year())
	default: // month
		return fmt.Sprintf("%d-%02d-01", now.Year(), now.Month())
	}
}

// upsertCheckIn membuat atau update record check-in
func upsertCheckIn(userID, companyID, date string, checkInTime time.Time, status string, deduction float64, lat, lon float64, locID string, dist float64) {
	var att models.Attendance
	err := database.DB.Where("user_id = ? AND date = ?", userID, date).First(&att).Error
	if err != nil {
		att = models.Attendance{
			ID:              uuid.New().String(),
			UserID:          userID,
			CompanyID:       companyID,
			Date:            date,
			CheckInTime:     &checkInTime,
			Status:          status,
			SalaryDeduction: deduction,
			CheckInLatitude:  lat,
			CheckInLongitude: lon,
			CheckInLocationID: locID,
			CheckInDistance:  dist,
		}
		database.DB.Create(&att)
	} else {
		att.CheckInTime = &checkInTime
		att.Status = status
		att.SalaryDeduction = deduction
		att.CheckInLatitude = lat
		att.CheckInLongitude = lon
		att.CheckInLocationID = locID
		att.CheckInDistance = dist
		database.DB.Save(&att)
	}
}

// helper parseT (pindah keluar untuk dipakai di CheckIn)
func parseT(dateStr, t string, loc *time.Location) time.Time {
	parsed, _ := time.ParseInLocation("2006-01-02 15:04", dateStr+" "+t, loc)
	return parsed
}

// AdminGetAttendanceYears - Mengambil daftar tahun unik yang memiliki data absensi untuk filter dinamis
func AdminGetAttendanceYears(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	user_id := c.Query("user_id")
	var years []string
	// Mengambil 4 karakter pertama dari kolom date (YYYY)
	query := database.DB.Model(&models.Attendance{}).Where("company_id = ?", adminUser.CompanyID)
	if user_id != "" {
		query = query.Where("user_id = ?", user_id)
	}
	err := query.Select("DISTINCT(SUBSTRING(date, 1, 4)) as year").
		Order("year desc").
		Pluck("year", &years).Error

	if err != nil {
		utils.Error(c, "Gagal mengambil daftar tahun: "+err.Error())
		return
	}

	utils.Success(c, "Berhasil mengambil daftar tahun", years)
}

// AdminGetDetailedDashboardSummary - Mengambil ringkasan detail (Hadir, Telat, Bekerja, Izin/Sakit, dll)
// Mendukung filter: month, year, atau default (today)
func AdminGetDetailedDashboardSummary(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	filter := c.Query("filter")
	monthS := c.Query("month")
	yearS := c.Query("year")

	now := time.Now()
	loc := now.Location()
	today := now.Format("2006-01-02")

	// 1. Tentukan Rentang Tanggal
	var start, end string
	if filter == "month" && monthS != "" && yearS != "" {
		mInt, _ := strconv.Atoi(monthS)
		yInt, _ := strconv.Atoi(yearS)
		firstDay := time.Date(yInt, time.Month(mInt), 1, 0, 0, 0, 0, loc)
		lastDay := firstDay.AddDate(0, 1, -1)
		start = firstDay.Format("2006-01-02")
		end = lastDay.Format("2006-01-02")
		// Jika bulan ini, batasi end sampai hari ini
		if end > today {
			end = today
		}
	} else if filter == "year" && yearS != "" {
		yInt, _ := strconv.Atoi(yearS)
		start = fmt.Sprintf("%d-01-01", yInt)
		end = fmt.Sprintf("%d-12-31", yInt)
		if end > today {
			end = today
		}
	} else if filter == "week" {
		start = getFilterStart("week")
		end = today
	} else {
		// Default: today
		start = today
		end = today
	}

	// 2. Ambil Karyawan Aktif
	var employees []models.User
	database.DB.Where("company_id = ? AND role = ? AND status = ?", adminUser.CompanyID, "EMPLOYEE", "ACTIVE").Find(&employees)
	totalEmp := len(employees)

	// 3. Ambil Pengaturan
	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", adminUser.CompanyID).First(&settings)
	checkOutEndT := parseT(today, settings.CheckOutEnd, loc)

	// 4. Ambil Records & Mapping
	var records []models.Attendance
	database.DB.Where("company_id = ? AND date >= ? AND date <= ?", adminUser.CompanyID, start, end).Find(&records)

	recordMap := make(map[string]map[string]models.Attendance)
	for _, r := range records {
		if recordMap[r.Date] == nil {
			recordMap[r.Date] = make(map[string]models.Attendance)
		}
		recordMap[r.Date][r.UserID] = r
	}

	summary := map[string]int{
		"present":           0,
		"late":              0,
		"working":           0,
		"leave_sick":        0,
		"not_yet":           0,
		"absent":            0,
		"early_leave":       0,
		"late_early_leave":  0,
		"total":             totalEmp,
	}

	// 5. Iterasi Hari & Karyawan (Logika yang sama dengan History agar Konsisten)
	curr, _ := time.ParseInLocation("2006-01-02", start, loc)
	limit, _ := time.ParseInLocation("2006-01-02", end, loc)

	for !curr.After(limit) {
		dateStr := curr.Format("2006-01-02")

		for _, emp := range employees {
			att, exists := recordMap[dateStr][emp.ID]

			if exists {
				s := strings.ToUpper(att.Status)
				if s == "PRESENT" {
					summary["present"]++
					if att.CheckOutTime == nil && dateStr == today && now.Before(checkOutEndT) {
						summary["working"]++
					}
				} else if s == "LATE" {
					summary["late"]++
					if att.CheckOutTime == nil && dateStr == today && now.Before(checkOutEndT) {
						summary["working"]++
					}
				} else if s == "LEAVE" || s == "SICK" {
					summary["leave_sick"]++
				} else if s == "ABSENT" {
					summary["absent"]++
				} else if s == "EARLY_LEAVE" {
					summary["early_leave"]++
				} else if s == "LATE_EARLY_LEAVE" {
					summary["late_early_leave"]++
				}

				// DETEKSI DINAMIS UNTUK HARI INI
				if dateStr == today && att.CheckOutTime == nil && now.After(checkOutEndT) {
					if strings.ToUpper(att.Status) == "LATE" {
						// Pindahkan dari 'late' ke 'late_early_leave'
						summary["late_early_leave"]++
						summary["late"]--
					} else if strings.ToUpper(att.Status) == "PRESENT" {
						// Pindahkan dari 'present' ke 'early_leave'
						summary["early_leave"]++
						summary["present"]--
					}
				}
			} else {
				// Cegah hitung sebelum karyawan terdaftar
				regDate := emp.CreatedAt.In(loc).Format("2006-01-02")
				if dateStr < regDate {
					continue
				}

				isAlpha := false
				isHold, _ := isHoliday(adminUser.CompanyID, curr) // Cek libur untuk tanggal curr

				if !isHold {
					if dateStr < today {
						isAlpha = true
					} else if dateStr == today && now.After(checkOutEndT) {
						isAlpha = true
					}
				}

				if filter == "today" || (start == today && end == today) {
					if isAlpha {
						summary["absent"]++
					} else if !isHold {
						summary["not_yet"]++
					}
				} else {
					// Untuk agregat (Week/Month/Year), hari yang lewat tanpa absen adalah Alpha
					if isAlpha {
						summary["absent"]++
					}
				}
			}
		}
		curr = curr.AddDate(0, 0, 1)
	}

	utils.Success(c, "Berhasil mengambil ringkasan detail", summary)
}

// AdminGetAttendanceTrend - Mengambil tren persentase kehadiran berdasarkan filter
func AdminGetAttendanceTrend(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	filter := c.DefaultQuery("filter", "week") // week, month, year
	month := c.Query("month")
	year := c.Query("year")

	var labels []string
	var presentData, lateData, absentData, leaveSickData, earlyLeaveData, lateEarlyLeaveData []float64

	now := time.Now()
	loc := now.Location()

	var employees []models.User
	database.DB.Model(&models.User{}).Where("company_id = ? AND role = ? AND status = ?", adminUser.CompanyID, "EMPLOYEE", "ACTIVE").Find(&employees)
	totalEmp := len(employees)

	today := now.Format("2006-01-02")
	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", adminUser.CompanyID).First(&settings)
	checkOutEndT := parseT(today, settings.CheckOutEnd, loc)

	if totalEmp == 0 {
		utils.Success(c, "Trend data (empty)", gin.H{
			"labels": []string{},
			"present": []float64{}, "late": []float64{}, "absent": []float64{}, "leave_sick": []float64{}, "early_leave": []float64{}, "late_early_leave": []float64{},
		})
		return
	}

	if filter == "year" && year != "" {
		for m := 1; m <= 12; m++ {
			labels = append(labels, time.Month(m).String()[:3])
			pattern := fmt.Sprintf("%s-%02d%%", year, m)

			var p, l, ls, el, lel int64
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date LIKE ? AND status = 'PRESENT'", adminUser.CompanyID, pattern).Count(&p)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date LIKE ? AND status = 'LATE'", adminUser.CompanyID, pattern).Count(&l)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date LIKE ? AND (status = 'LEAVE' OR status = 'SICK')", adminUser.CompanyID, pattern).Count(&ls)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date LIKE ? AND status = 'EARLY_LEAVE'", adminUser.CompanyID, pattern).Count(&el)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date LIKE ? AND status = 'LATE_EARLY_LEAVE'", adminUser.CompanyID, pattern).Count(&lel)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date LIKE ? AND status = 'LATE_EARLY_LEAVE'", adminUser.CompanyID, pattern).Count(&lel)

			// Untuk tahunan, Alpha dihitung per bulan: (TotalEmp * hari_kerja_per_bulan) - total_absen? 
            // Agak kompleks tanpa calendar. Sederhananya, kita akumulasi Alpha harian untuk bulan tersebut.
            var a int64
            // Ambil semua records bulan ini untuk menghitung alpha harian secara akurat
            var monthRecords []models.Attendance
            database.DB.Where("company_id = ? AND date LIKE ?", adminUser.CompanyID, pattern).Find(&monthRecords)
            
            // Map: date -> user_id -> struct{}
            mRecordMap := make(map[string]map[string]bool)
            for _, r := range monthRecords {
                if mRecordMap[r.Date] == nil { mRecordMap[r.Date] = make(map[string]bool) }
                mRecordMap[r.Date][r.UserID] = true
            }

            // Iterasi hari dalam bulan m
            yInt, _ := strconv.Atoi(year)
            firstDay := time.Date(yInt, time.Month(m), 1, 0, 0, 0, 0, loc)
            lastDay := firstDay.AddDate(0, 1, -1)
            if lastDay.After(now) { lastDay = now }

            for d := firstDay; !d.After(lastDay); d = d.AddDate(0, 0, 1) {
                dateStr := d.Format("2006-01-02")
                for _, emp := range employees {
                    regDate := emp.CreatedAt.In(loc).Format("2006-01-02")
                    if dateStr < regDate { continue }
                    if !mRecordMap[dateStr][emp.ID] {
                        // Jika hari terlewati, Alpha (HANYA JIKA BUKAN HARI LIBUR)
                        isHold, _ := isHoliday(adminUser.CompanyID, d)
                        if !isHold {
                            if dateStr < today || (dateStr == today && now.After(checkOutEndT)) {
                                a++
                            }
                        }
                    }
                }
            }

			presentData = append(presentData, float64(p))
			lateData = append(lateData, float64(l))
			absentData = append(absentData, float64(a))
			leaveSickData = append(leaveSickData, float64(ls))
			earlyLeaveData = append(earlyLeaveData, float64(el))
			lateEarlyLeaveData = append(lateEarlyLeaveData, float64(lel))
		}
	} else if filter == "month" && month != "" && year != "" {
		yInt, _ := strconv.Atoi(year)
		mInt, _ := strconv.Atoi(month)
		firstDay := time.Date(yInt, time.Month(mInt), 1, 0, 0, 0, 0, loc)
		lastDay := firstDay.AddDate(0, 1, -1)
        if lastDay.After(now) { lastDay = now }

		for d := firstDay; !d.After(lastDay); d = d.AddDate(0, 0, 1) {
			dateStr := d.Format("2006-01-02")
			labels = append(labels, d.Format("02"))

			var p, l, ls, el, lel int64
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = 'PRESENT'", adminUser.CompanyID, dateStr).Count(&p)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = 'LATE'", adminUser.CompanyID, dateStr).Count(&l)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND (status = 'LEAVE' OR status = 'SICK')", adminUser.CompanyID, dateStr).Count(&ls)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = 'EARLY_LEAVE'", adminUser.CompanyID, dateStr).Count(&el)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = 'LATE_EARLY_LEAVE'", adminUser.CompanyID, dateStr).Count(&lel)

			// DETEKSI DINAMIS UNTUK HARI INI DI GRAFIK BULANAN
			if dateStr == today && now.After(checkOutEndT) {
				var recordsToday []models.Attendance
				database.DB.Where("company_id = ? AND date = ?", adminUser.CompanyID, today).Find(&recordsToday)
				for _, r := range recordsToday {
					if r.CheckOutTime == nil {
						if strings.ToUpper(r.Status) == "LATE" {
							lel++
							l--
						} else if strings.ToUpper(r.Status) == "PRESENT" {
							el++
							p--
						}
					}
				}
			}

			// Hitung Alpha (Gunakan logika yang sama: Hari lewat + tidak terdaftar record)
			var a int64
			var dailyRecords []string
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ?", adminUser.CompanyID, dateStr).Pluck("user_id", &dailyRecords)
			dMap := make(map[string]bool)
			for _, uid := range dailyRecords {
				dMap[uid] = true
			}

			for _, emp := range employees {
				regDate := emp.CreatedAt.In(loc).Format("2006-01-02")
				if dateStr < regDate {
					continue
				}
				if !dMap[emp.ID] {
					// Cek Hari Libur
					isHold, _ := isHoliday(adminUser.CompanyID, d)
					if !isHold {
						if dateStr < today || (dateStr == today && now.After(checkOutEndT)) {
							a++
						}
					}
				}
			}

			presentData = append(presentData, float64(p))
			lateData = append(lateData, float64(l))
			absentData = append(absentData, float64(a))
			leaveSickData = append(leaveSickData, float64(ls))
			earlyLeaveData = append(earlyLeaveData, float64(el))
			lateEarlyLeaveData = append(lateEarlyLeaveData, float64(lel))
		}
	} else if filter == "today" {
		for h := 6; h <= 18; h++ {
			label := fmt.Sprintf("%02d:00", h)
			labels = append(labels, label)
			hourPattern := fmt.Sprintf("%% %02d:%%", h)

			var p, l, ls, el, lel int64
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND check_in_time::text LIKE ? AND status = 'PRESENT'", adminUser.CompanyID, today, hourPattern).Count(&p)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND check_in_time::text LIKE ? AND status = 'LATE'", adminUser.CompanyID, today, hourPattern).Count(&l)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND check_in_time::text LIKE ? AND (status = 'LEAVE' OR status = 'SICK')", adminUser.CompanyID, today, hourPattern).Count(&ls)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND check_in_time::text LIKE ? AND status = 'EARLY_LEAVE'", adminUser.CompanyID, today, hourPattern).Count(&el)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND check_in_time::text LIKE ? AND status = 'LATE_EARLY_LEAVE'", adminUser.CompanyID, today, hourPattern).Count(&lel)

			presentData = append(presentData, float64(p))
			lateData = append(lateData, float64(l))
			absentData = append(absentData, float64(0)) // Untuk hari ini tren alpha tidak relevan per jam
			leaveSickData = append(leaveSickData, float64(ls))
			earlyLeaveData = append(earlyLeaveData, float64(el))
		}
	} else {
		for i := 6; i >= 0; i-- {
			d := now.AddDate(0, 0, -i)
			dateStr := d.Format("2006-01-02")
			labels = append(labels, d.Format("Mon"))

			var p, l, ls, el, lel int64
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = 'PRESENT'", adminUser.CompanyID, dateStr).Count(&p)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = 'LATE'", adminUser.CompanyID, dateStr).Count(&l)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND (status = 'LEAVE' OR status = 'SICK')", adminUser.CompanyID, dateStr).Count(&ls)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = 'EARLY_LEAVE'", adminUser.CompanyID, dateStr).Count(&el)
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = 'LATE_EARLY_LEAVE'", adminUser.CompanyID, dateStr).Count(&lel)

			// DETEKSI DINAMIS UNTUK HARI INI DI GRAFIK MINGGUAN/DEFAULT
			if dateStr == today && now.After(checkOutEndT) {
				var recordsToday []models.Attendance
				database.DB.Where("company_id = ? AND date = ?", adminUser.CompanyID, today).Find(&recordsToday)
				for _, r := range recordsToday {
					if r.CheckOutTime == nil {
						if strings.ToUpper(r.Status) == "LATE" {
							lel++
							l--
						} else if strings.ToUpper(r.Status) == "PRESENT" {
							el++
							p--
						}
					}
				}
			}

			var a int64
			var weeklyRecords []string
			database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ?", adminUser.CompanyID, dateStr).Pluck("user_id", &weeklyRecords)
			dMap := make(map[string]bool)
			for _, uid := range weeklyRecords {
				dMap[uid] = true
			}

			for _, emp := range employees {
				regDate := emp.CreatedAt.In(loc).Format("2006-01-02")
				if dateStr < regDate {
					continue
				}
				if !dMap[emp.ID] {
					// Cek Hari Libur
					isHold, _ := isHoliday(adminUser.CompanyID, d)
					if !isHold {
						if dateStr < today || (dateStr == today && now.After(checkOutEndT)) {
							a++
						}
					}
				}
			}

			presentData = append(presentData, float64(p))
			lateData = append(lateData, float64(l))
			absentData = append(absentData, float64(a))
			leaveSickData = append(leaveSickData, float64(ls))
			earlyLeaveData = append(earlyLeaveData, float64(el))
			lateEarlyLeaveData = append(lateEarlyLeaveData, float64(lel))
		}
	}

	utils.Success(c, "Data tren kehadiran", gin.H{
		"labels":      labels,
		"present":     presentData,
		"late":        lateData,
		"absent":      absentData,
		"leave_sick":  leaveSickData,
		"early_leave": earlyLeaveData,
		"late_early_leave": lateEarlyLeaveData,
	})
}

// PardonAttendance — admin menghapus sanksi absensi (Terlambat/Alpha/Pulang Awal)
func PardonAttendance(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		UserID string `json:"user_id" binding:"required"`
		Date   string `json:"date" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var att models.Attendance
	err := database.DB.Where("user_id = ? AND date = ? AND company_id = ?", body.UserID, body.Date, adminUser.CompanyID).First(&att).Error

	if err != nil {
		// Jika tidak ada di DB (berarti Virtual Alpha), buat record baru sebagai PRESENT
		att = models.Attendance{
			ID:              uuid.New().String(),
			UserID:          body.UserID,
			CompanyID:       adminUser.CompanyID,
			Date:            body.Date,
			Status:          "PRESENT",
			SalaryDeduction: 0,
			Notes:           "Sanksi dihapus secara manual oleh admin",
		}
		if err := database.DB.Create(&att).Error; err != nil {
			utils.Error(c, "Gagal membuat keterangan pemutihan")
			return
		}
	} else {
		// Jika ada di DB (Late/Early Leave/Recorded Alpha), update menjadi PRESENT
		att.Status = "PRESENT"
		att.SalaryDeduction = 0
		att.Notes = "Sanksi dihapus secara manual oleh admin"
		if err := database.DB.Save(&att).Error; err != nil {
			utils.Error(c, "Gagal memperbarui status absensi")
			return
		}
	}

	utils.Success(c, "Sanksi absensi berhasil dihapus", nil)
}

// CreateCompanyLocation — admin menambah titik lokasi absensi
func CreateCompanyLocation(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	var body struct {
		Name      string  `json:"name" binding:"required"`
		Latitude  float64 `json:"latitude" binding:"required"`
		Longitude float64 `json:"longitude" binding:"required"`
		Radius    float64 `json:"radius" binding:"required"`
		IsActive  bool    `json:"is_active"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	newLocation := models.CompanyLocation{
		ID:        uuid.New().String(),
		CompanyID: admin.CompanyID,
		Name:      body.Name,
		Latitude:  body.Latitude,
		Longitude: body.Longitude,
		Radius:    body.Radius,
		IsActive:  true,
	}

	if err := database.DB.Create(&newLocation).Error; err != nil {
		utils.Error(c, "Gagal menambah lokasi")
		return
	}

	utils.Success(c, "Lokasi berhasil ditambahkan", newLocation)
}

// GetCompanyLocations — admin mendapatkan semua lokasi perusahaan
func GetCompanyLocations(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)

	var locations []models.CompanyLocation
	database.DB.Where("company_id = ?", admin.CompanyID).Find(&locations)

	utils.Success(c, "Daftar lokasi absensi", locations)
}

// GetActiveCompanyLocations — karyawan mendapatkan lokasi absensi aktif (untuk validasi frontend)
func GetActiveCompanyLocations(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	var locations []models.CompanyLocation
	database.DB.Where("company_id = ? AND is_active = ?", emp.CompanyID, true).Find(&locations)

	utils.Success(c, "Daftar lokasi absensi aktif", locations)
}

// UpdateCompanyLocation — admin mengubah data lokasi
func UpdateCompanyLocation(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)
	id := c.Param("id")

	var loc models.CompanyLocation
	if err := database.DB.Where("id = ? AND company_id = ?", id, admin.CompanyID).First(&loc).Error; err != nil {
		utils.Error(c, "Lokasi tidak ditemukan")
		return
	}

	var body struct {
		Name      string  `json:"name"`
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
		Radius    float64 `json:"radius"`
		IsActive  *bool   `json:"is_active"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	if body.Name != "" { loc.Name = body.Name }
	if body.Latitude != 0 { loc.Latitude = body.Latitude }
	if body.Longitude != 0 { loc.Longitude = body.Longitude }
	if body.Radius != 0 { loc.Radius = body.Radius }
	if body.IsActive != nil { loc.IsActive = *body.IsActive }

	database.DB.Save(&loc)
	utils.Success(c, "Lokasi berhasil diperbarui", loc)
}

// DeleteCompanyLocation — admin menghapus lokasi
func DeleteCompanyLocation(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)
	id := c.Param("id")

	if err := database.DB.Where("id = ? AND company_id = ?", id, admin.CompanyID).Delete(&models.CompanyLocation{}).Error; err != nil {
		utils.Error(c, "Gagal menghapus lokasi")
		return
	}

	utils.Success(c, "Lokasi berhasil dihapus", nil)
}
