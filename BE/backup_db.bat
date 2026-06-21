@echo off
echo ====================================================
echo    BACKUP DATABASE - VIDENTI FACE RECOGNITION
echo ====================================================
echo.

:: Tentukan lokasi penyimpanan backup di folder proyek BE/backups
set BACKUP_DIR=backups
if not exist %BACKUP_DIR% (
    mkdir %BACKUP_DIR%
)

:: Tentukan format tanggal YYYY-MM-DD menggunakan PowerShell (menghindari bug carriage return dari WMIC)
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd'"`) do set DATE=%%i

echo [+] Memulai backup untuk tanggal: %DATE%
echo.

:: Cari path pg_dump.exe bawaan instalasi PostgreSQL Windows
set PG_DUMP_PATH=pg_dump
if exist "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe" (
    set PG_DUMP_PATH="C:\Program Files\PostgreSQL\17\bin\pg_dump.exe"
) else if exist "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe" (
    set PG_DUMP_PATH="C:\Program Files\PostgreSQL\16\bin\pg_dump.exe"
) else if exist "C:\Program Files\PostgreSQL\15\bin\pg_dump.exe" (
    set PG_DUMP_PATH="C:\Program Files\PostgreSQL\15\bin\pg_dump.exe"
) else if exist "C:\Program Files\PostgreSQL\14\bin\pg_dump.exe" (
    set PG_DUMP_PATH="C:\Program Files\PostgreSQL\14\bin\pg_dump.exe"
)

:: Set password database untuk pg_dump agar tidak memunculkan prompt password
set PGPASSWORD=postgres

echo [1/3] Mem-backup Database Auth (pa2_auth)...
%PG_DUMP_PATH% -h localhost -U postgres --inserts pa2_auth > "%BACKUP_DIR%\videnti_auth_%DATE%.sql"

echo [2/3] Mem-backup Database Attendance (pa2_attendance)...
%PG_DUMP_PATH% -h localhost -U postgres --inserts pa2_attendance > "%BACKUP_DIR%\videnti_attendance_%DATE%.sql"

echo [3/3] Mem-backup Database Payroll (pa2_payroll)...
%PG_DUMP_PATH% -h localhost -U postgres --inserts pa2_payroll > "%BACKUP_DIR%\videnti_payroll_%DATE%.sql"

echo.
echo ====================================================
echo BACKUP SELESAI!
echo Hasil disimpan di: %CD%\%BACKUP_DIR%
echo ====================================================
pause
