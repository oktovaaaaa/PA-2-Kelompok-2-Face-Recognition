// routes/routes.go

package routes

import (
	"employee-system/internal/handlers"
	"employee-system/internal/middleware"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {

	r := gin.Default()

	// Enable CORS
	r.Use(middleware.CORSMiddleware())

	// Serve file upload statis
	r.Static("/uploads", "./uploads")

	api := r.Group("/api")

	{
		api.GET("/health", func(c *gin.Context) {
			utils.Success(c, "Server berjalan", nil)
		})

		api.POST("/auth/register-admin", handlers.RegisterAdmin)
	}

	// Auth routes (public)
	api.POST("/auth/send-otp", handlers.SendOTP)
	api.POST("/auth/verify-otp", handlers.VerifyOTP)
	api.POST("/auth/login", handlers.Login)
	api.POST("/auth/verify-login-otp", handlers.VerifyLoginOTP)
	api.POST("/auth/validate-invite", handlers.ValidateInvite)
	api.POST("/auth/google-login", handlers.GoogleLogin)
	api.POST("/auth/register-employee", handlers.RegisterEmployee)
	api.POST("/auth/login-pin", handlers.LoginPin)
	api.POST("/auth/forgot-password", handlers.ForgotPassword)
	api.POST("/auth/reset-password", handlers.ResetPassword)
	api.GET("/testimonials", handlers.GetTestimonials)
	api.POST("/testimonials", handlers.CreateTestimonial)
	api.POST("/testimonials/upload", handlers.UploadFile)

	// Protected routes (semua user yang sudah login)
	protected := api.Group("/")
	protected.Use(middleware.AuthMiddleware())
	{
		// Upload file (gambar profil, foto izin, logo perusahaan)
		protected.POST("/upload", handlers.UploadFile)

		// Profil (admin & karyawan)
		protected.GET("/profile", handlers.GetMyProfile)
		protected.PUT("/profile", handlers.UpdateMyProfile)
		protected.PUT("/profile/fcm-token", handlers.UpdateFcmToken)
		protected.POST("/profile/request-otp", handlers.RequestProfileOTP)
		protected.POST("/profile/verify-password", handlers.VerifyPassword)
		protected.POST("/profile/change-password", handlers.ChangePassword)
		protected.POST("/profile/change-pin", handlers.ChangePin)
		protected.DELETE("/profile", handlers.DeleteAccount)

		// Notifikasi (admin & karyawan)
		protected.GET("/notifications", handlers.GetNotifications)
		protected.PUT("/notifications/:id/read", handlers.MarkNotificationRead)
		protected.PUT("/notifications/read-all", handlers.MarkAllNotificationsRead)
		protected.DELETE("/notifications/:id", handlers.DeleteNotification)
		protected.DELETE("/notifications", handlers.DeleteAllNotifications)
		// Denda Pelanggaran (Melihat denda sendiri)
		protected.GET("/penalties", handlers.GetPenalties)
	}

	// Protected Admin Routes
	admin := api.Group("/admin")
	admin.Use(middleware.AuthMiddleware(), middleware.AdminOnlyMiddleware())
	{
		// Undangan karyawan
		admin.POST("/generate-invite", handlers.GenerateInvite)
		admin.GET("/pending-employees", handlers.GetPendingEmployees)
		admin.POST("/approve-employee", handlers.ApproveEmployee)
		admin.POST("/reject-employee", handlers.RejectEmployee)
		admin.POST("/reset-device", handlers.ResetDeviceBinding)

		// Data perusahaan
		admin.POST("/company", handlers.UpdateCompanySettings)
		admin.GET("/company", handlers.GetCompanySettings)

		// Jabatan
		admin.POST("/positions", handlers.CreatePosition)
		admin.GET("/positions", handlers.GetPositions)
		admin.PUT("/positions/:id", handlers.UpdatePosition)
		admin.DELETE("/positions/:id", handlers.DeletePosition)
		admin.POST("/positions/assign", handlers.AssignPosition)

		// Kelola karyawan
		admin.GET("/employees", handlers.GetEmployees)
		admin.POST("/employees/fire", handlers.FireEmployee)
		admin.POST("/employees/reactivate", handlers.ReactivateEmployee)

		// Perizinan karyawan
		admin.GET("/leaves", handlers.AdminGetLeaveRequests)
		admin.POST("/leaves", handlers.AdminCreateLeave)
		admin.PUT("/leaves/:id/approve", handlers.ApproveLeave)
		admin.PUT("/leaves/:id/reject", handlers.RejectLeave)
		admin.DELETE("/leaves/:id", handlers.AdminDeleteLeave)

		// Riwayat absensi semua karyawan
		admin.GET("/attendance", handlers.AdminGetAttendanceHistory)
		admin.GET("/attendance/years", handlers.AdminGetAttendanceYears)
		admin.POST("/attendance/pardon", handlers.PardonAttendance)
		admin.DELETE("/attendance", handlers.AdminBulkDeleteAttendance)
		admin.GET("/dashboard/summary", handlers.AdminGetDashboardSummary)
		admin.GET("/dashboard/detailed-summary", handlers.AdminGetDetailedDashboardSummary)
		admin.GET("/dashboard/trend", handlers.AdminGetAttendanceTrend)

		// Pengaturan absensi
		admin.GET("/attendance-settings", handlers.GetAttendanceSettings)
		admin.PUT("/attendance-settings", handlers.UpdateAttendanceSettings)

		// Penggajian (Payroll)
		admin.GET("/payroll", handlers.AdminGetSalaries)
		admin.POST("/payroll/:id/pay", handlers.AdminPaySalary)

		// Hari Libur
		admin.POST("/holidays", handlers.CreateHoliday)
		admin.GET("/holidays", handlers.GetHolidays)
		admin.PUT("/holidays/:id", handlers.UpdateHoliday)
		admin.DELETE("/holidays/:id", handlers.DeleteHoliday)
		admin.DELETE("/holidays/past", handlers.DeletePastHolidays)

		// Denda Pelanggaran (Manual Penalty)
		admin.POST("/penalties", handlers.CreatePenalty)
		admin.GET("/penalties", handlers.GetPenalties)
		admin.DELETE("/penalties/:id", handlers.DeletePenalty)
		admin.GET("/penalties/years", handlers.AdminGetPenaltyYears)

		// Bonus & Insentif
		admin.GET("/bonuses", handlers.AdminGetBonuses)
		admin.GET("/bonuses/years", handlers.AdminGetBonusYears)
		admin.POST("/bonuses", handlers.AdminCreateBonus)
		admin.DELETE("/bonuses/:id", handlers.AdminDeleteBonus)

		// Testimoni admin
		admin.GET("/testimonials", handlers.AdminGetTestimonials)
		admin.PUT("/testimonials/:id/approve", handlers.ApproveTestimonial)
		admin.DELETE("/testimonials/:id", handlers.DeleteTestimonial)

		// Lokasi Perusahaan
		admin.GET("/locations", handlers.GetCompanyLocations)
		admin.POST("/locations", handlers.CreateCompanyLocation)
		admin.PUT("/locations/:id", handlers.UpdateCompanyLocation)
		admin.DELETE("/locations/:id", handlers.DeleteCompanyLocation)
	}

	// Protected Employee Routes
	employee := api.Group("/employee")
	employee.Use(middleware.AuthMiddleware())
	{
		// Absensi
		employee.POST("/attendance/checkin", handlers.CheckIn)
		employee.POST("/attendance/checkout", handlers.CheckOut)
		employee.GET("/attendance/today", handlers.GetTodayAttendance)
		employee.GET("/attendance/history", handlers.GetMyAttendanceHistory)
		employee.GET("/locations", handlers.GetActiveCompanyLocations)

		// Pengajuan izin / sakit
		employee.POST("/leaves", handlers.EmployeeCreateLeave)
		employee.GET("/leaves", handlers.EmployeeGetLeaves)
		employee.PUT("/leaves/:id", handlers.EmployeeUpdateLeave)
		employee.DELETE("/leaves/:id", handlers.EmployeeDeleteLeave)
		employee.POST("/leaves/bulk-delete", handlers.EmployeeBulkDeleteLeaves)

		// Penggajian (Payroll)
		employee.GET("/salaries/years", handlers.GetSalaryYears)
		employee.GET("/salaries", handlers.GetMySalaries)
		employee.PUT("/bank-info", handlers.UpdateBankInfo)
	}

	return r
}
