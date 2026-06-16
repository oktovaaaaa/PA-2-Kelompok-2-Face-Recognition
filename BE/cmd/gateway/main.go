package main

import (
	"log"
	"net/http/httputil"
	"net/url"

	"employee-system/internal/middleware"

	"github.com/gin-gonic/gin"
)

// 1. fungsi reverse proxy untuk meneruskan request ke target microservice tertentu
// menggunakan httputil.NewSingleHostReverseProxy untuk mengarahkan request masuk ke ip/port service tujuan
func proxy(target string) gin.HandlerFunc {
	url, _ := url.Parse(target)
	proxy := httputil.NewSingleHostReverseProxy(url)

	return func(c *gin.Context) {
		// menyamakan host request dengan host server tujuan sebelum diteruskan
		c.Request.Host = url.Host
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

func main() {
	r := gin.Default()

	// 2. terapkan cors middleware agar frontend web/mobile diijinkan mengakses api
	r.Use(middleware.CORSMiddleware())

	// ==========================================
	// --- AUTH SERVICE (Port 8081) ---
	// ==========================================
	// - r.Any() digunakan untuk menangkap seluruh metode http (GET, POST, PUT, DELETE, dll)
	// - akhiran /*any (wildcard) digunakan agar seluruh sub-endpoint di bawahnya otomatis diteruskan (contoh: /api/auth/login)
	authProxy := proxy("http://localhost:8081")
	r.Any("/api/auth", authProxy)
	r.Any("/api/auth/*any", authProxy)
	r.Any("/api/profile", authProxy)
	r.Any("/api/profile/*any", authProxy)
	r.Any("/api/upload", authProxy) // Upload rute global
	r.Any("/api/testimonials", authProxy)
	r.Any("/api/testimonials/*any", authProxy)
	r.Any("/api/notifications", authProxy)
	r.Any("/api/notifications/*any", authProxy)
	r.Any("/api/sessions", authProxy)
	r.Any("/api/sessions/*any", authProxy)

	// User/Employee Management (Auth)
	r.Any("/api/admin/employees", authProxy)
	r.Any("/api/admin/employees/*any", authProxy)
	r.Any("/api/admin/positions", authProxy)
	r.Any("/api/admin/positions/*any", authProxy)
	r.Any("/api/admin/company", authProxy)
	r.Any("/api/admin/company/*any", authProxy)
	r.Any("/api/admin/generate-invite", authProxy)
	r.Any("/api/admin/pending-employees", authProxy)
	r.Any("/api/admin/approve-employee", authProxy)
	r.Any("/api/admin/reject-employee", authProxy)
	r.Any("/api/admin/reset-device", authProxy)
	r.Any("/api/admin/testimonials", authProxy)
	r.Any("/api/admin/testimonials/*any", authProxy)

	// Super Admin Features (Auth Service)
	r.Any("/api/super-admin", authProxy)
	r.Any("/api/super-admin/*any", authProxy)

	// ==========================================
	// --- ATTENDANCE SERVICE (Port 8082) ---
	// ==========================================
	// meneruskan request terkait absensi (checkin/out), lokasi kantor, wifi ssid/bssid, dan hari libur ke attendance service
	attProxy := proxy("http://localhost:8082")
	r.Any("/api/employee/attendance", attProxy)
	r.Any("/api/employee/attendance/*any", attProxy)
	r.Any("/api/employee/leaves", attProxy)
	r.Any("/api/employee/leaves/*any", attProxy)
	r.Any("/api/employee/locations", attProxy)
	r.Any("/api/employee/wifis", attProxy)

	// Admin Attendance Features
	r.Any("/api/admin/attendance", attProxy)
	r.Any("/api/admin/attendance/*any", attProxy)
	r.Any("/api/admin/leaves", attProxy)
	r.Any("/api/admin/leaves/*any", attProxy)
	r.Any("/api/admin/locations", attProxy)
	r.Any("/api/admin/locations/*any", attProxy)
	r.Any("/api/admin/wifis", attProxy)
	r.Any("/api/admin/wifis/*any", attProxy)
	r.Any("/api/admin/holidays", attProxy)
	r.Any("/api/admin/holidays/*any", attProxy)
	r.Any("/api/admin/attendance-settings", attProxy)
	r.Any("/api/admin/attendance-settings/*any", attProxy)
	r.Any("/api/admin/dashboard", attProxy) // DASHBOARD SUMMARY FIX
	r.Any("/api/admin/dashboard/*any", attProxy)

	// ==========================================
	// --- PAYROLL SERVICE (Port 8083) ---
	// ==========================================
	// meneruskan rincian slip gaji, nominal bonus, denda sanksi, dan aksi bayar gaji ke payroll service
	payProxy := proxy("http://localhost:8083")
	r.Any("/api/employee/salaries", payProxy)
	r.Any("/api/employee/salaries/*any", payProxy)
	r.Any("/api/employee/bank-info", authProxy) // Changed from payProxy to authProxy
	r.Any("/api/employee/penalties", payProxy)

	r.Any("/api/admin/payroll", payProxy)
	r.Any("/api/admin/payroll/*any", payProxy)
	r.Any("/api/admin/bonuses", payProxy)
	r.Any("/api/admin/bonuses/*any", payProxy)
	r.Any("/api/admin/penalties", payProxy)
	r.Any("/api/admin/penalties/*any", payProxy)

	// 3. penyajian folder statis untuk file gambar/bukti transfer yang diupload
	r.Static("/uploads", "./uploads")

	// 4. jalankan reverse proxy api gateway utama di port 8080
	log.Println("API Gateway running on port 8080...")
	r.Run(":8080")
}
