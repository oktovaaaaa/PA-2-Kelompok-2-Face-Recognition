// internal/services/email_service.go

package services

import (
	"fmt"
	"os"

	gomail "gopkg.in/gomail.v2"
)

func SendOTPEmail(email string, otp string) error {

	m := gomail.NewMessage()

	m.SetHeader("From", os.Getenv("SMTP_EMAIL"))
	m.SetHeader("To", email)
	m.SetHeader("Subject", fmt.Sprintf("🔐 [%s] Kode OTP Videnti", otp))

	// Embed logo
	m.Embed("assets/videnti.png")

	htmlBody := fmt.Sprintf(`
	<!DOCTYPE html>
	<html>
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<style>
			body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 0; }
			.container { max-width: 500px; margin: 40px auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); border: 1px solid #E2E8F0; }
			.header { background: linear-gradient(135deg, #0F172A 0%%, #1E3A8A 100%%); padding: 40px 20px; text-align: center; color: #ffffff; }
			.logo { width: 80px; height: 80px; margin-bottom: 15px; }
			.header h1 { margin: 0; font-size: 26px; font-weight: 800; letter-spacing: 2px; text-transform: uppercase; }
			.content { padding: 40px 30px; text-align: center; color: #1E293B; }
			.content h2 { font-size: 14px; text-transform: uppercase; letter-spacing: 2px; color: #64748B; margin-bottom: 24px; }
			.otp-box { background-color: #F1F5F9; border-radius: 16px; padding: 24px; display: inline-block; margin: 0 auto 30px; border: 2px solid #E2E8F0; }
			.otp-code { font-size: 36px; font-weight: 800; color: #0F172A; letter-spacing: 10px; margin: 0; font-family: 'Courier New', Courier, monospace; }
			.instruction { font-size: 15px; line-height: 1.6; color: #475569; margin-top: 0; }
			
			.safety-card { background-color: #FFF1F2; border: 1px solid #FECDD3; border-radius: 12px; padding: 20px; margin-top: 30px; text-align: left; }
			.safety-title { font-size: 13px; font-weight: 700; color: #BE123C; display: block; margin-bottom: 8px; text-decoration: underline; }
			.safety-text { font-size: 12px; color: #9D174D; margin: 0; line-height: 1.5; }

			.footer { background-color: #F8FAFC; padding: 24px; text-align: center; color: #94A3B8; font-size: 12px; border-top: 1px solid #F1F5F9; }
			.footer p { margin: 4px 0; }
		</style>
	</head>
	<body>
		<div class="container">
			<div class="header">
				<img src="cid:videnti.png" alt="Videnti Logo" class="logo">
				<h1>VIDENTI</h1>
			</div>
			<div class="content">
				<h2>Verifikasi Keamanan</h2>
				<p class="instruction">Halo, gunakan kode OTP berikut untuk melanjutkan proses login atau reset kata sandi Anda:</p>
				
				<div class="otp-box" style="background-color: #F1F5F9; border-radius: 16px; padding: 24px; border: 2px solid #E2E8F0;">
					<h2 class="otp-code" style="font-size: 36px; font-weight: 900; color: #0F172A; letter-spacing: 10px; margin: 0; font-family: 'Courier New', Courier, monospace;">
						<b style="font-weight: 900 !important;">%s</b>
					</h2>
				</div>
				
				<p class="instruction">Kode ini akan kedaluwarsa dalam <strong>5 menit</strong>.</p>
 
				<div class="safety-card">
					<span class="safety-title">⚠️ PERINGATAN KEAMANAN:</span>
					<p class="safety-text">
						• <strong>JANGAN PERNAH</strong> memberitahukan kode ini kepada siapapun.<br>
						• Tim Videnti tidak pernah meminta kode OTP Anda via telepon, chat, atau media apapun.<br>
						• Jika Anda tidak melakukan permintaan ini, segera amankan akun Anda.
					</p>
				</div>
			</div>
			<div class="footer">
				<p>&copy; 2026 PA-2-Kelompok-2 Face Recognition Team</p>
				<p>Butuh bantuan? Hubungi kami di <a href="mailto:videntiiii@gmail.com" style="color: #2563EB; text-decoration: none;">videntiiii@gmail.com</a></p>
			</div>
		</div>
	</body>
	</html>
	`, otp)

	m.SetBody("text/html", htmlBody)

	d := gomail.NewDialer(
		os.Getenv("SMTP_HOST"),
		587,
		os.Getenv("SMTP_EMAIL"),
		os.Getenv("SMTP_PASSWORD"),
	)

	return d.DialAndSend(m)
}