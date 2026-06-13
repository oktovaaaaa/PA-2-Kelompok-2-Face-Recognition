$env:GOOS="linux"
$env:GOARCH="amd64"
$env:CGO_ENABLED="0"

Write-Host "Compiling gateway for Linux..." -ForegroundColor Green
go build -o gateway cmd/gateway/main.go

Write-Host "Compiling auth for Linux..." -ForegroundColor Green
go build -o auth cmd/auth/main.go

Write-Host "Compiling attendance for Linux..." -ForegroundColor Green
go build -o attendance cmd/attendance/main.go

Write-Host "Compiling payroll for Linux..." -ForegroundColor Green
go build -o payroll cmd/payroll/main.go

Write-Host "Build complete! Pre-compiled Linux binaries generated successfully." -ForegroundColor Cyan
