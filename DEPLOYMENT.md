# Panduan Deployment Videnti (Backend & Frontend)

Dokumen ini berisi panduan lengkap untuk men-deploy seluruh sistem **Videnti** (Backend Microservices Go + Python, Admin Web Next.js, dan Konfigurasi Mobile Flutter) ke VPS Ubuntu (IDCloudHost).

---

## 🏗️ 1. Persiapan Awal di Server (VPS Ubuntu)

Hubungkan ke VPS Anda melalui SSH dan lakukan instalasi package yang dibutuhkan.

### A. Update System & Install Docker
Backend berjalan menggunakan Docker & Docker Compose.
```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install docker.io docker-compose-v2 -y

# Mulai dan aktifkan Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Tambahkan user aktif ke group docker (agar tidak perlu selalu mengetik 'sudo')
sudo usermod -aG docker $USER
# Setelah ini, logout SSH dan login kembali agar perubahan group aktif
```

### B. Install Node.js & PM2 (Untuk Admin Web Next.js)
Admin Web berjalan menggunakan Next.js dan memerlukan Node.js.
```bash
# Install Node.js LTS (v20.x atau terbaru)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2 secara global (untuk menjaga aplikasi Next.js tetap menyala di background)
sudo npm install pm2 -g
```

### C. Install Nginx & Certbot (Untuk Reverse Proxy & SSL HTTPS)
Nginx digunakan untuk mengarahkan domain/subdomain ke port backend (8080) dan frontend (3000).
```bash
sudo apt install nginx certbot python3-certbot-nginx -y
```

---

## ⚙️ 2. Deployment Backend (Microservices & Database)

Backend terdiri dari 4 microservices Go (`gateway`, `auth`, `attendance`, `payroll`), 1 service Python (`face-api-service`), dan database PostgreSQL. Semua dijalankan menggunakan **Docker Compose**.

### Langkah A: Pastikan Binaries Terupdate (Di Local PC Windows)
Karena Dockerfile BE menggunakan binary hasil kompilasi, jika Anda baru saja mengubah kode Go di local, jalankan script kompilasi ini di folder `BE` pada local PC Windows Anda:
```powershell
./build_linux.ps1
```
Kemudian, pastikan file binary (`gateway`, `auth`, `attendance`, `payroll`) di-commit dan di-push ke GitHub Anda.

### Langkah B: Clone Repository di Server
Di dalam terminal VPS Ubuntu Anda:
```bash
# Clone repository
git clone https://github.com/Oktovaaaaa/PA-2-Kelompok-2-Face-Recognition.git ~/videnti-app

# Masuk ke folder backend
cd ~/videnti-app/BE
```

### Langkah C: Konfigurasi Environment Variable (`.env`)
Di server, buat atau sesuaikan file `.env` di dalam folder `BE` untuk mengkonfigurasi database, SMTP email, JWT, dan Firebase.

Salin file `.env` yang ada, pastikan isinya sesuai. Yang paling krusial:
1. Pastikan file `service-account.json` (Firebase Service Account) diunggah/ada di folder `BE` server.
2. Edit file `.env`, `.env.auth`, `.env.attendance`, `.env.payroll` jika diperlukan. Karena kita menggunakan `network_mode: host` pada Docker Compose, settingan `DB_HOST=localhost` sudah benar dan kontainer microservice dapat langsung terhubung ke PostgreSQL yang berjalan di localhost port 5432.

### Langkah D: Jalankan Docker Compose
Jalankan perintah ini di dalam direktori `~/videnti-app/BE`:
```bash
# Build image docker dan jalankan container di background
docker compose up --build -d
```
*Catatan: Proses pertama kali akan memakan waktu sekitar 3–5 menit karena Docker perlu mengunduh library python face recognition (OpenCV, InsightFace) dan model deteksi wajah (`buffalo_l`).*

### Langkah E: Cek Status Container
Untuk memastikan semua service berjalan dengan baik:
```bash
docker compose ps
```
Anda juga bisa melihat log menggunakan:
```bash
docker compose logs -f
```

---

## 🖥️ 3. Deployment Frontend (Admin Web Next.js)

Aplikasi admin web Next.js dideploy secara langsung menggunakan Node.js dan dijaga oleh PM2.

### Langkah A: Masuk ke folder Frontend Admin
```bash
cd ~/videnti-app/admin-web-next
```

### Langkah B: Konfigurasi `.env.local`
Buat file konfigurasi `.env.local` untuk mengarahkan frontend ke server API gateway:
```bash
nano .env.local
```
Isi dengan konfigurasi berikut (sesuaikan domain/IP VPS Anda):
```env
NEXT_PUBLIC_API_URL=http://<IP_OR_DOMAIN_VPS>:8080/api
NEXT_PUBLIC_PRO_URL=https://themeselection.com/item/materio-nextjs-admin-template
NEXT_PUBLIC_DOCS_URL=https://demos.themeselection.com/materio-mui-nextjs-admin-template/documentation
NEXT_PUBLIC_REPO_NAME=materio-mui-nextjs-admin-template-free
```
*Tekan `Ctrl+O` lalu `Enter` untuk menyimpan, dan `Ctrl+X` untuk keluar.*

### Langkah C: Install Dependencies & Build
```bash
# Install package
npm install

# Build Next.js untuk production
npm run build
```

### Langkah D: Jalankan dengan PM2
Agar aplikasi Next.js tetap berjalan di background dan otomatis menyala saat server restart:
```bash
# Jalankan aplikasi Next.js dengan nama 'videnti-admin' pada port 3000
pm2 start npm --name "videnti-admin" -- start

# Simpan konfigurasi PM2 agar otomatis restore saat server reboot
pm2 save
pm2 startup
```
*Gunakan perintah `pm2 status` untuk melihat aplikasi yang sedang berjalan.*

---

## 🔒 4. Konfigurasi Nginx & SSL HTTPS (Sangat Direkomendasikan)

Agar aplikasi web dan API Anda aman (HTTPS) dan dapat diakses menggunakan domain, konfigurasikan Nginx sebagai reverse proxy.

### Langkah A: Buat File Konfigurasi Nginx
```bash
sudo nano /etc/nginx/sites-available/videnti
```
Masukkan konfigurasi berikut (ganti `domainanda.com` dengan domain asli Anda):
```nginx
server {
    listen 80;
    server_name domainanda.com www.domainanda.com;

    # Admin Web Next.js (Port 3000)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend Gateway API (Port 8080)
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        
        # Penanganan upload file ukuran besar jika dibutuhkan
        client_max_body_size 50M;
    }
}
```

### Langkah B: Aktifkan Konfigurasi & Restart Nginx
```bash
# Buat symlink untuk mengaktifkan site
sudo ln -s /etc/nginx/sites-available/videnti /etc/nginx/sites-enabled/

# Hapus default config Nginx bawaan jika bentrok
sudo rm /etc/nginx/sites-enabled/default

# Test konfigurasi nginx
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### Langkah C: Dapatkan Sertifikat SSL Gratis (HTTPS) dengan Let's Encrypt
```bash
# Dapatkan dan install SSL otomatis ke Nginx
sudo certbot --nginx -d domainanda.com -d www.domainanda.com
```
*Ikuti petunjuk di layar, ketik email Anda, dan pilih opsi redirect HTTP ke HTTPS secara otomatis.*

---

## 📱 5. Konfigurasi Mobile App (Flutter)

Setelah server Backend berhasil di-deploy:

1. Buka project Flutter Anda di local PC Windows.
2. Cari file konfigurasi atau service API, lalu ubah Base URL API dari `http://localhost:8080/api` atau `http://10.0.2.2:8080/api` menjadi URL server produksi Anda, contohnya:
   - Jika menggunakan domain + SSL: `https://domainanda.com/api`
   - Jika langsung menggunakan IP VPS: `http://<IP_VPS>:8080/api`
3. Lakukan pengujian koneksi aplikasi Flutter ke server API.
4. Build rilis baru dengan perintah:
   ```bash
   flutter build apk --release
   ```
5. File APK siap didistribusikan!

---

## 🧹 6. Perawatan (Maintenance) Server

### Cara Update Source Code Terbaru
Jika Anda melakukan update code di GitHub, ikuti langkah berikut di server:
```bash
# Update backend
cd ~/videnti-app/BE
git pull
docker compose down
docker compose up --build -d

# Update frontend admin
cd ~/videnti-app/admin-web-next
git pull
npm install
npm run build
pm2 restart videnti-admin
```
