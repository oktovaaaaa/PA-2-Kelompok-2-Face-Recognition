// internal/handlers/leave_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"
	"encoding/json"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ===== ADMIN HANDLERS =====

// AdminGetLeaveRequests — admin melihat semua izin karyawan perusahaannya
// Query params: status=PENDING|APPROVED|REJECTED (opsional)
func AdminGetLeaveRequests(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	status := c.Query("status")
	month := c.Query("month")
	year := c.Query("year")
	search := c.Query("search")

	type LeaveWithUser struct {
		ID              string    `json:"id"`
		UserID          string    `json:"user_id"`
		UserName        string    `json:"user_name"`
		UserEmail       string    `json:"user_email"`
		UserPhoto       string    `json:"user_photo"`
		Type            string    `json:"type"`
		Title           string    `json:"title"`
		Description     string    `json:"description"`
		PhotoURL        string    `json:"photo_url"`
		Status          string    `json:"status"`
		AdminNote       string    `json:"admin_note"`
		ConfirmedHonest bool      `json:"confirmed_honest"`
		Dates           string    `json:"dates"`
		CreatedAt       time.Time `json:"created_at"`
	}

	var result []LeaveWithUser
	query := database.DB.Model(&models.LeaveRequest{}).
		Select("leave_requests.id, leave_requests.user_id, leave_requests.type, leave_requests.title, leave_requests.description, leave_requests.photo_url, leave_requests.status, leave_requests.admin_note, leave_requests.confirmed_honest, leave_requests.dates, leave_requests.created_at, users.name as user_name, users.email as user_email, users.photo_url as user_photo").
		Joins("left join users on users.id = leave_requests.user_id").
		Where("leave_requests.company_id = ? AND leave_requests.is_deleted_by_admin = ?", adminUser.CompanyID, false)

	if status != "" && status != "ALL" {
		query = query.Where("leave_requests.status = ?", status)
	}

	if year != "" {
		query = query.Where("EXTRACT(YEAR FROM leave_requests.created_at) = ?", year)
	}
	if month != "" && month != "0" {
		query = query.Where("EXTRACT(MONTH FROM leave_requests.created_at) = ?", month)
	}

	if search != "" {
		query = query.Where("users.name ILIKE ?", "%"+search+"%")
	}

	query.Order("CASE WHEN leave_requests.status = 'PENDING' THEN 0 ELSE 1 END, leave_requests.created_at ASC").Find(&result)

	utils.Success(c, "Daftar izin karyawan", result)
}

// ApproveLeave — admin menyetujui izin karyawan
func ApproveLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	var body struct {
		Note string `json:"note"`
	}
	c.ShouldBindJSON(&body)

	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}
	if leave.Status != "PENDING" {
		utils.Error(c, "Izin sudah diproses sebelumnya")
		return
	}

	leave.Status = "APPROVED"
	leave.AdminNote = body.Note
	database.DB.Save(&leave)

	// Tandai hari kehadiran dengan status LEAVE/SICK untuk SEMUA tanggal terpilih
	attendanceStatus := "LEAVE"
	if leave.Type == "SAKIT" {
		attendanceStatus = "SICK"
	}

	if leave.Dates != "" {
		var dateList []string
		if err := json.Unmarshal([]byte(leave.Dates), &dateList); err == nil {
			for _, d := range dateList {
				upsertAttendance(leave.UserID, adminUser.CompanyID, d, attendanceStatus)
			}
		}
	} else {
		// Fallback ke CreatedAt jika data Dates kosong (kompatibilitas data lama)
		upsertAttendance(leave.UserID, adminUser.CompanyID, leave.CreatedAt.Format("2006-01-02"), attendanceStatus)
	}

	// Kirim notifikasi ke karyawan
	services.CreateNotification(leave.UserID, adminUser.CompanyID, "Izin Disetujui",
		"Izin kamu telah disetujui oleh admin.", "LEAVE_APPROVED", leave.ID)
	services.SendPushNotification(leave.UserID, "Izin Disetujui", "Izin kamu telah disetujui oleh admin.")

	utils.Success(c, "Izin berhasil disetujui", nil)
}

// RejectLeave — admin menolak izin karyawan
func RejectLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	var body struct {
		Note string `json:"note"`
	}
	c.ShouldBindJSON(&body)

	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}
	if leave.Status != "PENDING" {
		utils.Error(c, "Izin sudah diproses sebelumnya")
		return
	}

	leave.Status = "REJECTED"
	leave.AdminNote = body.Note
	database.DB.Save(&leave)

	// Kirim notifikasi ke karyawan
	services.CreateNotification(leave.UserID, adminUser.CompanyID, "Izin Ditolak",
		"Izin kamu ditolak oleh admin. "+body.Note, "LEAVE_REJECTED", leave.ID)
	services.SendPushNotification(leave.UserID, "Izin Ditolak", "Izin kamu ditolak oleh admin.")

	utils.Success(c, "Izin berhasil ditolak", nil)
}

// AdminDeleteLeave — admin menghapus izin (soft-delete sisi admin)
func AdminDeleteLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}

	leave.IsDeletedByAdmin = true
	database.DB.Save(&leave)

	// Hapus permanen jika kedua pihak sudah menghapus
	if leave.IsDeletedByEmployee {
		database.DB.Delete(&leave)
	}

	utils.Success(c, "Izin dihapus", nil)
}

// AdminCreateLeave — admin membuatkan izin untuk karyawan tertentu
func AdminCreateLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		UserID          string   `json:"user_id"`
		Type            string   `json:"type"`
		Title           string   `json:"title"`
		Description     string   `json:"description"`
		Date            string   `json:"date"`  // format YYYY-MM-DD (legacy/single)
		Dates           []string `json:"dates"` // format [YYYY-MM-DD, ...]
		Status          string   `json:"status"` // PENDING/APPROVED
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.UserID == "" || body.Type == "" {
		utils.Error(c, "Data tidak lengkap")
		return
	}

	// Normalisasi: jika hanya ada Date tunggal, pindahkan ke Dates
	if len(body.Dates) == 0 && body.Date != "" {
		body.Dates = []string{body.Date}
	}

	if len(body.Dates) == 0 {
		utils.Error(c, "Pilih minimal satu tanggal")
		return
	}

	// Parsing tanggal pertama untuk CreatedAt
	parsedDate, _ := time.Parse("2006-01-02", body.Dates[0])
	datesJSON, _ := json.Marshal(body.Dates)

	leave := models.LeaveRequest{
		ID:              uuid.New().String(),
		UserID:          body.UserID,
		CompanyID:       adminUser.CompanyID,
		Type:            body.Type,
		Title:           body.Title,
		Description:     body.Description,
		Status:          body.Status,
		ConfirmedHonest: true,
		Dates:           string(datesJSON),
	}
	// override created_at if provided to match the calendar date
	if !parsedDate.IsZero() {
		leave.CreatedAt = parsedDate
	}

	if err := database.DB.Create(&leave).Error; err != nil {
		utils.Error(c, "Gagal menambahkan izin")
		return
	}

	// Jika langsung APPROVED, update attendance untuk SEMUA tanggal
	if body.Status == "APPROVED" {
		attendanceStatus := "LEAVE"
		if body.Type == "SAKIT" {
			attendanceStatus = "SICK"
		}
		for _, d := range body.Dates {
			upsertAttendance(body.UserID, adminUser.CompanyID, d, attendanceStatus)
		}
	}

	utils.Success(c, "Izin berhasil ditambahkan oleh admin", leave)
}

// ===== EMPLOYEE HANDLERS =====

// EmployeeCreateLeave — karyawan mengajukan izin/sakit
func EmployeeCreateLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	var body struct {
		Type            string   `json:"type"`
		Title           string   `json:"title"`
		Description     string   `json:"description"`
		PhotoURL        string   `json:"photo_url"`
		ConfirmedHonest bool     `json:"confirmed_honest"`
		Dates           []string `json:"dates"` // Harap mengirimkan list tanggal
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.Title == "" || body.Type == "" || len(body.Dates) == 0 {
		utils.Error(c, "Data izin tidak lengkap (pastikan tanggal sudah dipilih)")
		return
	}
	if !body.ConfirmedHonest {
		utils.Error(c, "Kamu harus mengkonfirmasi kejujuran data izin")
		return
	}
	if body.Type != "IZIN" && body.Type != "SAKIT" {
		utils.Error(c, "Tipe izin tidak valid (IZIN / SAKIT)")
		return
	}

	// Serialize dates to JSON string
	datesJSON, _ := json.Marshal(body.Dates)

	leave := models.LeaveRequest{
		ID:              uuid.New().String(),
		UserID:          emp.ID,
		CompanyID:       emp.CompanyID,
		Type:            body.Type,
		Title:           body.Title,
		Description:     body.Description,
		PhotoURL:        body.PhotoURL,
		Status:          "PENDING",
		ConfirmedHonest: body.ConfirmedHonest,
		Dates:           string(datesJSON),
	}
	if err := database.DB.Create(&leave).Error; err != nil {
		utils.Error(c, "Gagal membuat izin")
		return
	}

	// Cari admin perusahaan ini untuk kirim notifikasi
	var admin models.User
	if err := database.DB.Where("company_id = ? AND role = ?", emp.CompanyID, "ADMIN").First(&admin).Error; err == nil {
		services.CreateNotification(admin.ID, emp.CompanyID, "Pengajuan Izin Baru",
			emp.Name+" mengajukan "+body.Type+": "+body.Title, "LEAVE_REQUEST", leave.ID)
		services.SendPushNotification(admin.ID, "Pengajuan Izin Baru",
			emp.Name+" mengajukan "+body.Type+": "+body.Title)
	}

	utils.Success(c, "Izin berhasil diajukan", leave)
}

// EmployeeUpdateLeave — edit izin (hanya jika masih PENDING)
func EmployeeUpdateLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	id := c.Param("id")
	var body struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		PhotoURL    string `json:"photo_url"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND user_id = ?", id, emp.ID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}
	if leave.Status != "PENDING" {
		utils.Error(c, "Izin yang sudah diproses tidak bisa diedit")
		return
	}

	leave.Title = body.Title
	leave.Description = body.Description
	if body.PhotoURL != "" {
		leave.PhotoURL = body.PhotoURL
	}
	database.DB.Save(&leave)
	utils.Success(c, "Izin berhasil diperbarui", leave)
}

// EmployeeDeleteLeave — soft-delete dari sisi karyawan
func EmployeeDeleteLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	id := c.Param("id")
	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND user_id = ?", id, emp.ID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}

	leave.IsDeletedByEmployee = true
	
	// Jika status masih PENDING, maka pembatalan oleh karyawan otomatis menghapus 
	// pengajuan tersebut dari daftar antrean Admin (is_deleted_by_admin = true)
	if leave.Status == "PENDING" {
		leave.IsDeletedByAdmin = true
	}

	database.DB.Save(&leave)

	// Hapus permanen jika kedua pihak sudah menghapus
	if leave.IsDeletedByAdmin && leave.IsDeletedByEmployee {
		database.DB.Delete(&leave)
	}
	utils.Success(c, "Izin dihapus dari riwayat kamu", nil)
}

// EmployeeBulkDeleteLeaves — hapus beberapa izin sekaligus dari riwayat karyawan
func EmployeeBulkDeleteLeaves(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	var body struct {
		IDs []string `json:"ids"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || len(body.IDs) == 0 {
		utils.Error(c, "Daftar ID tidak valid")
		return
	}

	// Soft-delete: Tandai is_deleted_by_employee = true
	database.DB.Model(&models.LeaveRequest{}).
		Where("user_id = ? AND id IN ?", emp.ID, body.IDs).
		Update("is_deleted_by_employee", true)

	// Hapus permanen yang sudah dihapus oleh kedua pihak
	database.DB.Where("user_id = ? AND id IN ? AND is_deleted_by_admin = ?", emp.ID, body.IDs, true).
		Delete(&models.LeaveRequest{})

	utils.Success(c, "Beberapa izin berhasil dihapus dari riwayat", nil)
}

// EmployeeGetLeaves — list izin milik karyawan sendiri (dengan filter bulan/tahun)
func EmployeeGetLeaves(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	month := c.Query("month")
	year := c.Query("year")

	var leaves []models.LeaveRequest
	query := database.DB.Where("user_id = ? AND is_deleted_by_employee = ?", emp.ID, false)

	// Filter bulan & tahun menggunakan EXTRACT (Postgres)
	if year != "" {
		query = query.Where("EXTRACT(YEAR FROM created_at) = ?", year)
	}
	if month != "" {
		query = query.Where("EXTRACT(MONTH FROM created_at) = ?", month)
	}

	query.Order("created_at desc").Find(&leaves)
	utils.Success(c, "Daftar izin kamu", leaves)
}

// helper: buat atau update record attendance untuk karyawan pada tanggal tertentu
func upsertAttendance(userID, companyID, date, status string) {
	var att models.Attendance
	err := database.DB.Where("user_id = ? AND date = ?", userID, date).First(&att).Error
	if err != nil {
		// Buat baru
		att = models.Attendance{
			ID:        uuid.New().String(),
			UserID:    userID,
			CompanyID: companyID,
			Date:      date,
			Status:    status,
		}
		database.DB.Create(&att)
	} else {
		att.Status = status
		database.DB.Save(&att)
	}
}
