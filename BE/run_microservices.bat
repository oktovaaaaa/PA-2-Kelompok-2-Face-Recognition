@echo off
echo ====================================================
echo    MENJALANKAN MICROSERVICES - FACE RECOGNITION
echo ====================================================

echo [1/4] Menjalankan Auth Service (Port 8081)...
start "Auth Service" cmd /k "go run cmd/auth/main.go"

echo [2/4] Menjalankan Attendance Service (Port 8082)...
start "Attendance Service" cmd /k "go run cmd/attendance/main.go"

echo [3/4] Menjalankan Payroll Service (Port 8083)...
start "Payroll Service" cmd /k "go run cmd/payroll/main.go"

echo [4/5] Menjalankan API Gateway (Port 8080)...
start "API Gateway" cmd /k "go run cmd/gateway/main.go"

echo [5/5] Menjalankan Python AI Engine (Port 5000)...
start "Python AI Engine" cmd /k "venv\Scripts\activate.bat && python process_face_api.py"

echo.
echo ====================================================
echo SEMUA SERVICE SEDANG BERJALAN! (Termasuk Python AI Engine)
echo JANGAN TUTUP JENDELA TERMINAL YANG TERBUKA.
echo ====================================================
pause
