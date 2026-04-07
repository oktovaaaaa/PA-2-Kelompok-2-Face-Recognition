package main

import (
	"fmt"
	"log"
	"math/rand"
	"time"

	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/internal/models"

	"gorm.io/gorm"
)

func main() {
	// Load environment variables
	config.LoadEnv()

	// Connect to database
	database.ConnectDatabase()
	db := database.DB

	// 1. Delete all existing testimonials
	fmt.Println("Membersihkan data testimoni lama...")
	db.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&models.Testimonial{})

	// 2. Generate 20 positive testimonials
	names := []string{
		"Budi Santoso", "Siti Aminah", "Andi Wijaya", "Dewi Lestari", "Joko Widodo",
		"Rina Marlina", "Anton Setiawan", "Maya Putri", "Eko Prasetyo", "Indah Permata",
		"Rizky Fauzi", "Ani Suryani", "Hendra Gunawan", "Lusi Natalia", "Doni Irawan",
		"Fitri Handayani", "Agus Saputra", "Siska Olivia", "Bambang Pamungkas", "Yulia Erna",
	}

	feedbacks := []string{
		"Sistem absensi wajahnya sangat cepat dan akurat. Tidak ada lagi antrean di pagi hari!",
		"Sangat membantu manajemen dalam memantau kehadiran karyawan secara real-time.",
		"Fitur payroll otomatisnya benar-benar menghemat waktu tim HR kami. Luar biasa!",
		"Tampilan dashboard-nya sangat intuitif dan mudah dipahami, bahkan untuk pemula.",
		"Keamanan data terjamin dengan Face Recognition. Sangat direkomendasikan untuk perusahaan modern.",
		"Proses pengajuan cuti jadi jauh lebih mudah lewat aplikasi ini. Transparan sekali.",
		"Aplikasi yang sangat stabil. Jarang sekali ada kendala teknis saat melakukan absensi.",
		"Laporan kehadiran per bulan sekarang bisa diunduh hanya dengan satu klik. Sangat efisien!",
		"Sistem yang sangat adil. Perhitungan lembur dan keterlambatan jadi sangat presisi.",
		"Tim support-nya sangat responsif membantu saat kami melakukan integrasi sistem.",
		"Integrasi dengan sistem penggajian berjalan sangat mulus. Tidak ada lagi human error.",
		"Karyawan merasa lebih disiplin sejak menggunakan sistem absensi cerdas ini.",
		"Fitur pendeteksi lokasi (GPS) sangat membantu untuk tim sales lapangan kami.",
		"Interface aplikasinya sangat profesional dan mencerminkan modernitas perusahaan kami.",
		"Sangat menghemat biaya operasional dibandingkan menggunakan mesin fingerprint tradisional.",
		"Notifikasi real-time yang masuk ke admin sangat membantu koordinasi tim.",
		"Fleksibilitas sistem ini memungkinkan kami mengelola berbagai shift kerja dengan mudah.",
		"Data kehadiran tidak bisa dimanipulasi sama sekali. Integritas data sangat terjaga.",
		"Investasi terbaik untuk digitalisasi proses administrasi di kantor kami.",
		"Terima kasih VIDENTI! Proses absensi sekarang jadi lebih menyenangkan bagi karyawan.",
	}

	rand.Seed(time.Now().UnixNano())

	fmt.Println("Memasukkan 20 testimoni baru...")

	for i := 0; i < 20; i++ {
		testi := models.Testimonial{
			Name:        names[i],
			Description: feedbacks[i],
			Rating:      rand.Intn(2) + 4, // Generates 4 or 5
			IsApproved:  true,
			CreatedAt:   time.Now(),
		}

		if err := db.Create(&testi).Error; err != nil {
			log.Fatalf("Gagal membuat testimoni ke-%d: %v", i+1, err)
		}
	}

	fmt.Println("Berhasil! 20 testimoni positif telah ditambahkan ke database.")
}
