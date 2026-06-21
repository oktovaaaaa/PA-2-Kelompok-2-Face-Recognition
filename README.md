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

Jalankan perintah-perintah berikut langsung di terminal SSH VPS Anda:

#### 1. Masuk ke Folder Proyek Backend
```bash
cd ~/PA-2-Kelompok-2-Face-Recognition/BE
```

#### 2. Berikan Izin Eksekusi pada Script Backup
*(Hanya perlu dilakukan satu kali)*
```bash
chmod +x backup_db.sh
```

#### 3. Jalankan Backup secara Manual
```bash
./backup_db.sh
```

#### 4. Cara Melihat Hasil Backup & Isinya
File backup `.sql` akan tersimpan di folder `~/db_backups/` di direktori home user VPS Anda. Untuk melihat daftar dan isinya, jalankan perintah berikut di VPS:
```bash
# Masuk ke folder penyimpanan hasil backup di VPS
cd ~/db_backups

# Melihat file backup yang terbentuk beserta ukuran filenya (bukan 0 bytes)
ls -lh

# Mengintip isi 50 baris teratas file SQL (untuk memastikan struktur dump terbentuk)
head -n 50 videnti_auth_2026-06-22.sql

# Mencari baris perintah INSERT INTO (untuk memastikan record data ter-backup secara riil)
grep -i "INSERT INTO" videnti_auth_2026-06-22.sql | head -n 10
```
*(Sesuaikan tanggal pada nama file `videnti_auth_YYYY-MM-DD.sql` dengan tanggal hari ini).*

#### 5. Menyiapkan Backup Otomatis Mingguan (Cron Job)
Agar backup berjalan otomatis setiap minggu pada **hari Minggu pukul 00:00 dini hari**, atur jadwal di VPS Anda:

1. Di terminal VPS Anda, ketik perintah berikut:
   ```bash
   crontab -e
   ```
2. Jika ditanya jenis editor, pilih `nano` (biasanya ketik `1` lalu tekan `Enter`).
3. Scroll ke baris paling bawah, lalu paste baris perintah cron job berikut:
   ```text
   0 0 * * 0 /home/oktovaaaaa/PA-2-Kelompok-2-Face-Recognition/BE/backup_db.sh > /dev/null 2>&1
   ```
4. Simpan perubahan dengan menekan `Ctrl+O`, lalu `Enter`, dan keluar dengan menekan `Ctrl+X`.

---

## 🛡️ Mekanisme Ketahanan (Database Fallback Resilience)

Sistem microservices ini telah dilengkapi dengan mekanisme ketahanan terhadap kegagalan service pusat (`auth-service` di port `8081`).

### File Terkait:
- **`attendance-service` (port 8082)**:
  - [attendance_handler.go](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/BE/internal/handlers/attendance_handler.go) (fitur check-in, check-out, history, dashboard summary)
  - [leave_handler.go](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/BE/internal/handlers/leave_handler.go) (approval izin, pengajuan izin admin/karyawan)
- **`payroll-service` (port 8083)**:
  - [payroll_handler.go](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/BE/internal/handlers/payroll_handler.go) (kalkulasi gaji, report payroll admin)
  - [bonus_handler.go](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/BE/internal/handlers/bonus_handler.go) (input bonus manual admin)
  - [penalty_handler.go](file:///c:/Users/Oktovaaaaa/Documents/GitHub/PA-2-Kelompok-2-Face-Recognition/BE/internal/handlers/penalty_handler.go) (input denda manual admin)

### Cara Kerja:
- Secara default, `attendance-service` dan `payroll-service` mengambil data profile user, detail instansi, jabatan, dan daftar admin melalui request REST API internal ke `auth-service` (port `8081`).
- Jika `auth-service` mati atau port `8081` terputus, pemanggilan REST API tersebut akan gagal dengan error *connection refused*.
- Sistem akan mendeteksi kegagalan tersebut melalui penanganan error pada client HTTP dan beralih (**fallback**) untuk membaca data secara lokal dari tabel replikasi (`users`, `companies`, `positions`) di database internal masing-masing (`pa2_attendance` dan `pa2_payroll`).
- Dengan demikian, dashboard web admin, perizinan, absensi masuk/pulang, dan laporan payroll tetap berfungsi dengan normal meskipun `auth-service` sedang offline.

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
