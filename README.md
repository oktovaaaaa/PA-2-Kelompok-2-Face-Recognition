# PA-2 Face Recognition System

Sistem Presensi Karyawan berbasis Face Recognition dengan fitur Multi-Vector Registration dan Liveness Detection.

## 📱 Panduan Menjalankan Secara Wireless (Android)

Untuk menjalankan aplikasi di HP tanpa kabel, pastikan HP dan Laptop berada dalam satu jaringan (contoh: Hotspot HP atau WiFi yang sama).

### 1. Konfigurasi Backend URL
Pastikan Flutter menggunakan IP Laptop Anda sebagai `baseUrl`.
- **Lokasi Proyek Utama:** `FE/lib/core/constants/app_constants.dart`
- **Lokasi Proyek FR:** `fr/fr/fe/lib/main.dart`

Ganti IP dengan IP Laptop Anda (misal: `172.20.10.3`):
```dart
static const String baseUrl = 'http://172.20.10.3:8080';
```

### 2. Setup Wireless ADB (Tanpa Kabel)

#### Cara A: Menggunakan Kabel USB (Inisialisasi)
1. Hubungkan HP ke Laptop via kabel USB.
2. Buka terminal di Laptop dan jalankan:
   ```powershell
   adb tcpip 5555
   ```
3. Lepaskan kabel USB.
4. Hubungkan ke IP HP Anda (misal: `172.20.10.2`):
   ```powershell
   adb connect 172.20.10.2:5555
   ```

#### Cara B: Android 11+ (Murni Wireless)
1. Aktifkan **Wireless Debugging** di Developer Options HP.
2. Klik **Pair device with pairing code**.
3. Jalankan perintah pair di terminal:
   ```powershell
   adb pair [IP_HP]:[PORT_PAIRING]
   ```
4. Masukkan pairing code yang muncul di HP.
5. Jalankan perintah connect:
   ```powershell
   adb connect [IP_HP]:[PORT_CONNECT]
   ```

### 3. Menjalankan Aplikasi
1. **Jalankan Backend (Go):**
   ```powershell
   cd BE
   go run main.go
   ```
2. **Jalankan Frontend (Flutter):**
   ```powershell
   cd FE
   flutter run
   ```
   *Jika ada pilihan perangkat, pilih angka yang sesuai dengan IP HP Anda (misal: `172.20.10.2:5555`).*

   **Tips:** Anda bisa langsung menargetkan perangkat wireless agar tidak perlu memilih lagi:
   ```powershell
   flutter run -d 172.20.10.2:5555
   ```

## 🛠️ Catatan Penting
- **Firewall:** Pastikan Firewall Windows mengizinkan koneksi masuk pada port `8080`.
- **IP Address:** Selalu cek IP terbaru dengan `ipconfig` (Laptop) dan di menu WiFi/Tentang Ponsel (HP).
- **Path ADB:** Jika `adb` tidak dikenal, gunakan path lengkap:
  `C:\Users\[User]\AppData\Local\Android\Sdk\platform-tools\adb.exe`

---

## 💾 Panduan Backup Database (Mingguan)

Karena sistem ini menggunakan arsitektur *Database-per-Service* dengan 3 database PostgreSQL terpisah (`pa2_auth`, `pa2_attendance`, dan `pa2_payroll`), backup harus dilakukan untuk ketiga database tersebut.

Telah disediakan script otomatis untuk mem-backup database baik di lingkungan lokal maupun VPS produksi.

### A. Lingkungan Lokal (Windows)
1. Buka folder `BE` di terminal atau File Explorer.
2. Jalankan script batch:
   - **Melalui File Explorer:** Klik dua kali file [backup_db.bat](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/BE/backup_db.bat).
   - **Melalui Terminal/Command Prompt:**
     ```cmd
     cd BE
     .\backup_db.bat
     ```
3. Hasil file backup (.sql) akan otomatis disimpan di folder `BE/backups` dengan format nama menyertakan tanggal saat ini.

### B. Lingkungan Produksi (VPS Linux/Ubuntu)
1. Masuk ke folder proyek BE di VPS Anda:
   ```bash
   cd ~/PA-2-Kelompok-2-Face-Recognition/BE
   ```
2. Berikan izin eksekusi pada file script backup:
   ```bash
   chmod +x backup_db.sh
   ```
3. Jalankan script backup secara manual:
   ```bash
   ./backup_db.sh
   ```
4. **Cara Melihat Hasil Backup:**
   File backup `.sql` akan tersimpan di direktori `~/db_backups/`. Gunakan perintah berikut untuk melihat hasil dan isinya:
   ```bash
   cd ~/db_backups
   ls -lh                                                 # Melihat daftar file backup dan ukurannya
   grep -i "INSERT INTO" videnti_auth_2026-06-22.sql | head -n 10  # Memverifikasi data record yang berhasil di-backup
   ```
5. **Otomatisasi Menggunakan Cron Job:**
   Agar backup berjalan otomatis setiap hari (misal pukul 02:00 dini hari), edit konfigurasi cron di VPS Anda:
   ```bash
   crontab -e
   ```
   Tambahkan baris berikut di baris paling bawah (sesuaikan dengan username VPS Anda):
   ```text
   0 2 * * * /home/oktovaaaaa/PA-2-Kelompok-2-Face-Recognition/BE/backup_db.sh > /dev/null 2>&1
   ```

---

## 🛡️ Mekanisme Ketahanan (Database Fallback Resilience)

Sistem microservices ini telah dilengkapi dengan mekanisme ketahanan terhadap kegagalan service pusat (`auth-service` di port `8081`). 

### Cara Kerja:
- Secara default, `attendance-service` dan `payroll-service` mengambil data profile user, detail instansi, jabatan, dan daftar admin melalui request REST API internal ke `auth-service`.
- Jika `auth-service` mati atau port `8081` tidak dapat dihubungi (misalnya saat maintenance server), pemanggilan REST API tersebut akan gagal.
- Sistem akan otomatis mendeteksi kegagalan tersebut dan beralih (**fallback**) untuk membaca data langsung dari tabel replikasi lokal (`users`, `companies`, `positions`) yang berada di database masing-masing (`pa2_attendance` dan `pa2_payroll`).
- Dengan demikian, dashboard web admin, pengajuan izin/sakit, absensi masuk/pulang, dan kalkulasi payroll tetap dapat berfungsi dengan normal meskipun `auth-service` sedang offline.

### Cara Simulasi Pengujian di VPS:
1. Hentikan container `auth-service` secara manual di VPS:
   ```bash
   sudo docker stop videnti_auth
   ```
2. Akses web admin dashboard atau aplikasi mobile. Sistem akan mendeteksi `auth-service` down dan mengaktifkan fallback lokal. Anda akan melihat log fallback pada konsol docker container:
   `--> [ATTENDANCE WORKAROUND] Gagal mengambil data dari Auth Service, mencoba local DB...`
3. Nyalakan kembali container jika pengujian selesai:
   ```bash
   sudo docker start videnti_auth
   ```
