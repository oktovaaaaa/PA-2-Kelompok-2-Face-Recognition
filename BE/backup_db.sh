#!/bin/bash
# ====================================================
#    BACKUP DATABASE PRODUCTION - VIDENTI SYSTEM
# ====================================================

# Tentukan folder penyimpanan backup di VPS
BACKUP_DIR="$HOME/db_backups"
DATE=$(date +%Y-%m-%d)

# Buat folder jika belum ada
mkdir -p "$BACKUP_DIR"

echo "=== Memulai Backup Database Videnti ($DATE) ==="

# 1. Backup Database Auth (pa2_auth)
sudo docker exec videnti_db pg_dump -U postgres --inserts pa2_auth > "$BACKUP_DIR/videnti_auth_$DATE.sql"
echo "[✔] Backup pa2_auth berhasil."

# 2. Backup Database Attendance (pa2_attendance)
sudo docker exec videnti_db pg_dump -U postgres --inserts pa2_attendance > "$BACKUP_DIR/videnti_attendance_$DATE.sql"
echo "[✔] Backup pa2_attendance berhasil."

# 3. Backup Database Payroll (pa2_payroll)
sudo docker exec videnti_db pg_dump -U postgres --inserts pa2_payroll > "$BACKUP_DIR/videnti_payroll_$DATE.sql"
echo "[✔] Backup pa2_payroll berhasil."

# Hapus backup yang berumur lebih dari 30 hari agar penyimpanan VPS tidak penuh
find "$BACKUP_DIR" -type f -name "*.sql" -mtime +30 -delete
echo "[✔] Pembersihan file backup lama selesai."

echo "=== Proses Backup Database Selesai ==="
