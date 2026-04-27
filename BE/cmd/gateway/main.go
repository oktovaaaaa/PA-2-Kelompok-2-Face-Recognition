package main

import (
	"log"
	"net/http/httputil"
	"net/url"

	"github.com/gin-gonic/gin"
)

func proxy(target string) gin.HandlerFunc {
	url, _ := url.Parse(target)
	proxy := httputil.NewSingleHostReverseProxy(url)

	return func(c *gin.Context) {
		c.Request.Host = url.Host
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

func main() {
	r := gin.Default()

	// --- AUTH SERVICE (Port 8081) ---
	authProxy := proxy("http://localhost:8081")
	r.Any("/api/auth", authProxy)
	r.Any("/api/auth/*any", authProxy)
	r.Any("/api/login", authProxy)
	r.Any("/api/register-admin", authProxy)
	r.Any("/api/profile", authProxy)
	r.Any("/api/profile/*any", authProxy)
	r.Any("/api/testimonials", authProxy)
	r.Any("/api/testimonials/*any", authProxy)
	r.Any("/api/notifications", authProxy)
	r.Any("/api/notifications/*any", authProxy)
	// User/Employee Management (Auth)
	r.Any("/api/admin/employees", authProxy)
	r.Any("/api/admin/employees/*any", authProxy)
	r.Any("/api/admin/positions", authProxy)
	r.Any("/api/admin/positions/*any", authProxy)
	r.Any("/api/admin/company", authProxy)
	r.Any("/api/admin/company/*any", authProxy)

	// --- ATTENDANCE SERVICE (Port 8082) ---
	attProxy := proxy("http://localhost:8082")
	r.Any("/api/check-in", attProxy)
	r.Any("/api/check-out", attProxy)
	r.Any("/api/today-attendance", attProxy)
	r.Any("/api/attendance", attProxy)
	r.Any("/api/attendance/*any", attProxy)
	r.Any("/api/leave", attProxy)
	r.Any("/api/leave/*any", attProxy)
	// Admin Attendance Features
	r.Any("/api/admin/attendance", attProxy)
	r.Any("/api/admin/attendance/*any", attProxy)
	r.Any("/api/admin/leave", attProxy)
	r.Any("/api/admin/leave/*any", attProxy)
	r.Any("/api/admin/locations", attProxy)
	r.Any("/api/admin/locations/*any", attProxy)
	r.Any("/api/admin/holidays", attProxy)
	r.Any("/api/admin/holidays/*any", attProxy)
	r.Any("/api/admin/settings", attProxy)
	r.Any("/api/admin/settings/*any", attProxy)
	r.Any("/api/admin/attendance-settings", attProxy)       // Tambahan khusus
	r.Any("/api/admin/attendance-settings/*any", attProxy) // Tambahan khusus

	// --- PAYROLL SERVICE (Port 8083) ---
	payProxy := proxy("http://localhost:8083")
	r.Any("/api/payroll", payProxy)
	r.Any("/api/payroll/*any", payProxy)
	// Admin Payroll Features
	r.Any("/api/admin/payroll", payProxy)
	r.Any("/api/admin/payroll/*any", payProxy)
	r.Any("/api/admin/bonuses", payProxy)
	r.Any("/api/admin/bonuses/*any", payProxy)
	r.Any("/api/admin/penalties", payProxy)
	r.Any("/api/admin/penalties/*any", payProxy)
	r.Any("/api/admin/salaries", payProxy)
	r.Any("/api/admin/salaries/*any", payProxy)

	// Static Files (Assuming Auth Service handles them or separate)
	r.Static("/uploads", "./uploads")

	log.Println("API Gateway running on port 8080...")
	r.Run(":8080")
}
