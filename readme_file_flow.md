# Pemetaan File Sistem Videnti Berdasarkan Alur Fitur

Berikut adalah daftar file yang terbagi berdasarkan Frontend (FE) dan Backend (BE) untuk setiap alur fitur yang ada pada sistem:

## 1. Absensi, Alur & Status (Terlambat, Tepat Waktu, Pulang Awal, Alpha)

FE:

- employee_attendance_tab.dart
- attendanceService.ts

BE:

- attendance_handler.go
- attendance.go
- attendance_settings.go

---

## 2. Cuti & Perizinan

FE:

- employee_leave_tab.dart
- admin_leave_tab.dart
- leaveService.ts

BE:

- leave_handler.go
- leave_request.go

---

## 3. Payroll & Laporan Gaji

FE:

- employee_salary_tab.dart
- SalaryDetailModal.tsx
- payrollService.ts

BE:

- payroll_handler.go
- salary.go

---

## 4. Bonus

FE:

- EmployeeDetailModal.tsx

BE:

- bonus_handler.go
- bonus.go

---

## 5. Sanksi Denda Kantor

FE:

- EmployeeDetailModal.tsx

BE:

- penalty_handler.go
- penalty.go

---

## 6. Manajemen Jabatan

FE:

- admin_employee_tab.dart
- admin_position_tab.dart

BE:

- position_handler.go
- position.go

---

## 7. Face Recognition & Biometrik

FE:

- face_registration_screen.dart
- face_verification_screen.dart
- face_service.dart
- session_provider.dart

BE:

- process_face_api.py
- face_service.go
- profile_handler.go
- attendance_handler.go

---

## 8. Login, Register & Approval

FE:

- auth.ts

BE:

- auth_handler.go
- employee_management_handler.go

---

## 9. Geolokasi & Radius

FE:

- LocationSettings.tsx
- MapComponent.tsx
- settingService.ts
- location_management_screen.dart
- employee_attendance_tab.dart
- AndroidManifest.xml

BE:

- attendance_handler.go
- company_location.go

---

## 10. Pengaturan Akun & Profil

FE:

- employee_profile_tab.dart
- index.jsx

BE:

- profile_handler.go
- user.go

---

## 11. Stress Test

- k6_stress_test.js

---

## Syncron Database

position_handler.go
sync.go

## Export PDF
attendanceTable.tsx:
 const handleExportPDF

## Panduan Operasional & Konfigurasi Sistem

### 1. Cara Menemukan BSSID (MAC Address Wi-Fi Router)

BSSID adalah alamat MAC unik fisik dari router Wi-Fi yang digunakan untuk validasi absen kantor.

- **Melalui HP Android (Saat Terkoneksi)**:
  - Masuk ke **Settings > Network & Internet > Wi-Fi**.
  - Ketuk nama Wi-Fi yang sedang terhubung, gulir ke bawah pada bagian **Advanced**.
  - Salin string pada kolom **MAC address / BSSID** (format: `AA:BB:CC:DD:EE:FF`).
- **Melalui CMD Windows (Laptop yang terhubung Wi-Fi)**:
  - Jalankan perintah: `netsh wlan show interfaces`
  - Cari baris **BSSID** untuk melihat alamat MAC router.

### 2. Cara Mengubah IP Endpoint (Lokal vs Server)

Untuk merubah tujuan API dari server ke lokal atau sebaliknya:

- **Pada Flutter Mobile**:
  - Buka file [app_constants.dart](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/FE/lib/core/constants/app_constants.dart).
  - Ganti nilai `static const String baseUrl`.
  - _Untuk server_: `https://api.videnti.web.id`
  - _Untuk lokal laptop (hp fisik satu wifi)_: `http://[IP_LAPTOP_ANDA]:8080`
  - _Untuk Android Emulator_: `http://10.0.2.2:8080`
- **Pada Next.js Admin Web**:
  - Buka file [.env.local](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/admin-web-next/.env.local).
  - Ubah variabel `NEXT_PUBLIC_API_URL`.
  - _Lokal_: `http://localhost:8080/api`
  - _Server_: `https://api.videnti.web.id/api`

### 3. Cara Menginstal Library Python AI Engine

Python service digunakan untuk mengekstrak embedding wajah absensi.

- Buka CMD Windows/PowerShell dan masuk ke folder BE:
  ```cmd
  cd /d c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognition\BE
  ```
- Pastikan Python >= 3.8 terinstall, lalu jalankan perintah instalasi library:
  ```cmd
  pip install -r requirements.txt
  ```
  _(Library utama mencakup: fastapi, uvicorn, insightface, opencv-python, numpy, onnxruntime)._

### 4. Cara Menjalankan Backend (Microservices & AI Engine)

- **Menjalankan AI Engine (Python)**:
  Buka CMD/PowerShell baru, masuk ke folder BE:

  ```cmd
  cd /d c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognition\BE
  python process_face_api.py
  ```

  _(Berjalan di port 5000)._

- **Menjalankan Seluruh Microservices Go Sekaligus (Windows)**:
  Buka CMD/PowerShell baru, masuk ke folder BE:

  ```cmd
  cd /d c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognition\BE
  run_microservices.bat
  ```

- **Menjalankan Microservices Satu demi Satu secara Manual**:
  - **Auth Service** (Port 8081):
    ```cmd
    cd /d c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognition\BE
    go run cmd/auth/main.go
    ```
  - **Attendance Service** (Port 8082):
    ```cmd
    cd /d c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognition\BE
    go run cmd/attendance/main.go
    ```
  - **Payroll Service** (Port 8083):
    ```cmd
    cd /d c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognition\BE
    go run cmd/payroll/main.go
    ```
  - **API Gateway** (Port 8080):
    ```cmd
    cd /d c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognition\BE
    go run cmd/gateway/main.go
    ```

### 5. Cara Menjalankan Stress Test k6

Pemicu beban kerja uji stress pada endpoint absensi:

- Buka CMD Windows/PowerShell baru dan masuk ke direktori utama (root) proyek:
  ```cmd
  cd /d c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognition
  ```
- Pastikan file face_base64.txt sudah dibuat di folder root tersebut berisi string base64 gambar wajah.
- Jalankan pengujian dasar dengan k6:

  ```cmd

  ```

- Jalankan pengujian dan ekspor hasilnya ke file CSV untuk dianalisis:
  ```cmd
  k6 run --out csv=results.csv k6_stress_test.js
  ```

### 6. Cara Kerja dan Pemetaan Sinkronisasi Database

Mekanisme replikasi data instansi, jabatan, dan pengguna lintas microservices:

- **Database Asal (Sumber Utama)**:
  - **Nama DB**: pa2_auth (Dideklarasikan di file konfigurasi .env.auth lewat variabel DB_NAME=pa2_auth).
- **Database Target (Tujuan Duplikasi)**:
  - **Nama DB**: pa2_attendance dan pa2_payroll (Dideklarasikan di file sync.go melalui parameter koneksi GORM eksplisit).
- **Pemetaan Skema Tabel**:
  - Tabel companies (di DB pa2_auth) -> diduplikasi ke tabel companies (di DB pa2_attendance & pa2_payroll).
  - Tabel positions (di DB pa2_auth) -> diduplikasi ke tabel positions (di DB pa2_attendance & pa2_payroll).
  - Tabel users (di DB pa2_auth) -> diduplikasi ke tabel users (di DB pa2_attendance & pa2_payroll).
- **Lokasi Deklarasi Kode**:
  - Koneksi massal awal dideklarasikan di fungsi InitialSyncFromAuth (sync.go):
    ```go
    authDsn := fmt.Sprintf(..., "pa2_auth", ...)
    ```
  - Sinkronisasi harian berjalan melalui aksi CRUD di Handler (misal: position_handler.go):
    ```go
    // simpan ke DB asal (pa2_auth)
    database.DB.Create(&position)
    // sync ke DB target (pa2_attendance & pa2_payroll)
    database.SyncPositionToAttendance(position)
    ```


1. Kenapa Hanya Network Bandwidth yang Melonjak Tajam?
Penyebab: Request POST /checkin mengirimkan payload berupa foto wajah (baik dalam format Base64 atau file gambar). Satu file foto memiliki ukuran yang cukup besar (bisa 500 KB hingga 2 MB per foto).
Efek: Ketika 100 user melakukan absensi secara bersamaan, mereka mengunggah file foto secara serentak ke server. Ini menyebabkan lonjakan lalu lintas jaringan (transfer data masuk/ingress) yang membuat grafik Network Bandwidth naik drastis.
Perbandingan: Request GET lainnya (/locations, /today, dll.) hanya mengirimkan teks JSON kecil (beberapa byte saja), sehingga tidak mempengaruhi bandwidth.
2. Kenapa Waktu Respon POST Sangat Lambat (25,8 Detik) tetapi CPU, RAM, & Disk I/O Sangat Rendah?
A. Kemacetan Antrean (Single-Threaded Blocking)
Proses ekstraksi wajah dengan model AI (face_analyzer.get(img)) adalah komputasi matematika berat. Secara default, FastAPI/Uvicorn berjalan pada satu worker (single-process).

Python memiliki batas yang disebut GIL (Global Interpreter Lock) yang membuat Python hanya bisa mengeksekusi komputasi berat pada satu CPU core secara bergantian.
Ketika 100 user menembak server secara bersamaan, server tidak memproses 100 foto sekaligus, melainkan mengantrekan request tersebut. User ke-2 harus menunggu user ke-1 selesai, user ke-3 menunggu user ke-2, hingga user ke-100 harus mengantre di urutan paling belakang.
Waktu 25,8 detik tersebut bukanlah waktu pemrosesan 1 foto, melainkan waktu tunggu antrean akumulatif bagi user-user di antrean belakang sebelum foto mereka giliran diproses.
B. Mengapa CPU Terlihat Rendah (Mendekati 0%)?
Karena request tersebut mengantre satu per satu, hanya 1 core CPU saja yang bekerja pada satu waktu, sedangkan core CPU lainnya (misalnya server Anda memiliki 8 atau 16 core) menganggur. Pada grafik total server, penggunaan CPU kumulatif akan terlihat sangat kecil (misal hanya 5-10% dari total kapasitas CPU server keseluruhan).
C. Mengapa RAM Datar?
Model AI buffalo_l sudah di-load ke RAM sejak server dijalankan (~1.8 GB). Saat memproses foto, memori yang dibutuhkan untuk satu foto sangat kecil dan langsung dihapus setelah deteksi selesai. Karena foto diproses satu per satu (tidak paralel), penggunaan RAM tidak akan menumpuk dan grafik RAM akan terlihat flat.
D. Mengapa Disk I/O Datar?
Pemrosesan foto di process_face_api.py dilakukan langsung di dalam memori menggunakan io.BytesIO (in-memory bytes). Server tidak menulis atau membaca file foto ke dalam Harddisk/SSD selama proses verifikasi, sehingga aktivitas piringan harddisk (Disk I/O) tetap berada di angka 0.
💡 Solusi untuk Mengatasi Masalah Ini:
Gunakan Multi-Worker (Multiprocessing): Jalankan Uvicorn dengan menambahkan parameter --workers sesuai jumlah core CPU Anda.
Contoh: uvicorn process_face_api:app --host 0.0.0.0 --port 5000 --workers 4
Ini akan membuat Python membuka 4 proses paralel di RAM untuk memproses 4 wajah sekaligus di core CPU yang berbeda.
Kompres Gambar di Sisi Aplikasi (Flutter): Sebelum mengirim foto ke backend, kompres resolusi gambar (maksimal 640x640 piksel saja karena input deteksi model diset pada det_size=(640, 640)). Ini akan memangkas lonjakan network bandwidth dan meringankan beban kerja CPU.
8:17 AM
