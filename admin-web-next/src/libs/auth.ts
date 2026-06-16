// admin-web-next/src/libs/auth.ts

import { getBrowserInfo } from '@/utils/deviceInfo';

// Mengambil URL API dasar dari environment variable atau menggunakan default localhost:8080
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

export const authService = {
  // === ALUR 1: LOGIN 2-FA (TAHAP 1) ===
  async loginStep1(email: string, password: string) {
    // 1. Memicu request POST ke endpoint login.
    const response = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // 2. Mengirimkan email, password, & flag isAdminPanel agar backend memverifikasi hak akses administratif.
      // Jika kredensial cocok, backend secara otomatis memicu pengiriman OTP ke email tujuan.
      body: JSON.stringify({ email, password, isAdminPanel: true }),
    });

    // 3. Mengubah respon mentah menjadi JSON.
    const data = await response.json();

    // 4. Jika status HTTP tidak 2xx (gagal), lemparkan error untuk ditangkap di UI login.
    if (!response.ok) {
      throw new Error(data.message || 'Email atau password salah.');
    }

    // 5. Mengembalikan nilai true untuk memberi tahu UI bahwa Step 1 berhasil dan OTP telah terkirim.
    return true;
  },

  // === ALUR 2: REGISTRASI & PENGIRIMAN OTP UMUM ===
  async sendOTP(email: string, isAdminPanel: boolean = false, type: 'LOGIN' | 'REGISTER' = 'REGISTER') {
    // 1. Mengirim request ke endpoint send-otp.
    const response = await fetch(`${API_URL}/auth/send-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // 2. Mengirim email target, asal panel, & tipe alur (registrasi/login) agar backend men-generate OTP yang tepat.
      body: JSON.stringify({ email, isAdminPanel, type }),
    });

    // 3. Mengubah respon server menjadi JSON.
    const data = await response.json();

    // 4. Lemparkan error jika proses pembuatan/pengiriman email OTP gagal di sisi backend.
    if (!response.ok) {
      throw new Error(data.message || 'Gagal mengirim OTP.');
    }

    // 5. Mengembalikan status sukses pengiriman ke komponen UI.
    return true;
  },

  // === ALUR 1: LOGIN 2-FA (TAHAP 2 - VERIFIKASI OTP) ===
  async loginStep2(email: string, code: string, rememberMe: boolean = false) {
    // 1. Mengirimkan OTP yang dimasukkan oleh pengguna ke endpoint verifikasi login.
    const response = await fetch(`${API_URL}/auth/verify-login-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        email, 
        code, 
        // 2. Mendapatkan atau membuat ID perangkat unik di sisi klien untuk binding device.
        device_id: (() => {
          let id = localStorage.getItem('device_id');
          if (!id) {
            id = 'web-' + Math.random().toString(36).substring(2, 15);
            localStorage.setItem('device_id', id);
          }
          return id;
        })(),
        // 3. Mendapatkan informasi browser (user agent) untuk log aktivitas.
        device_name: getBrowserInfo()
      }),
    });

    // 4. Parsing response body dari server.
    const data = await response.json();

    // 5. Apabila OTP tidak valid atau kedaluwarsa, lemparkan pesan error.
    if (!response.ok) {
      throw new Error(data.message || 'Kode OTP tidak valid.');
    }

    const allowedRoles = ['ADMIN', 'SUPER_ADMIN', 'OWNER'];

    // 6. Validasi otoritas peran (role) pengguna; pastikan pengguna memiliki peran administrator.
    if (!data.data || !data.data.role || !allowedRoles.includes(data.data.role.toUpperCase())) {
      throw new Error('Akun ini tidak memiliki akses Administrator.')
    }

    const authData = data.data;

    // 7. Simpan token JWT dan metadata penting lainnya di LocalStorage browser untuk persistensi sesi.
    localStorage.setItem('token', authData.token);
    localStorage.setItem('user_id', authData.userId);
    localStorage.setItem('user_name', authData.email ? authData.email.split('@')[0] : 'Admin');
    localStorage.setItem('role', authData.role);
    localStorage.setItem('company_id', authData.companyId);

    // 8. Kembalikan data otentikasi lengkap ke dashboard.
    return authData;
  },

  // === ALUR 1.1: LOGIN DENGAN GOOGLE (2-FA TAHAP 1) ===
  async googleLogin(idToken: string) {
    // 1. Mengirimkan ID Token Google OAuth yang didapat dari provider ke backend.
    const response = await fetch(`${API_URL}/auth/google-login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id_token: idToken }),
    });

    // 2. Parsing response body.
    const data = await response.json();

    // 3. Jika validasi gagal di BE, batalkan proses login.
    if (!response.ok) {
      throw new Error(data.message || 'Gagal login dengan Google.');
    }

    // 4. Mengembalikan true jika berhasil; BE akan otomatis mengirimkan OTP 2FA ke email Google tersebut.
    return true;
  },

  // === ALUR 2.1: REGISTRASI ADMIN BARU DENGAN VERIFIKASI OTP ===
  async register(name: string, email: string, password: string, companyName: string, otpCode: string) {
    // 1. Mengirim seluruh data registrasi admin beserta instansinya & kode OTP ke server.
    const response = await fetch(`${API_URL}/auth/register-admin`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, password, companyName, otpCode }),
    });

    // 2. Parsing response JSON.
    const data = await response.json();

    // 3. Lemparkan error jika pendaftaran ditolak oleh BE (misal OTP salah atau email sudah terdaftar).
    if (!response.ok) {
      throw new Error(data.message || 'Gagal mendaftarkan akun.');
    }

    return true;
  },

  // === ALUR 3: LUPA PASSWORD (TAHAP 1 - REQUEST OTP) ===
  async requestResetOTP(email: string, isAdminPanel: boolean = false) {
    // 1. Mengirim request lupa password ke endpoint forgot-password.
    const response = await fetch(`${API_URL}/auth/forgot-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // 2. Mengirimkan email target & asal panel agar BE memvalidasi dan mengirimkan OTP reset via email.
      body: JSON.stringify({ email, isAdminPanel }),
    });

    // 3. Parsing response server.
    const data = await response.json();

    // 4. Jika email tidak terdaftar/gagal kirim, tampilkan error.
    if (!response.ok) {
      throw new Error(data.message || 'Email tidak ditemukan.');
    }

    return true;
  },

  // === ALUR 3: LUPA PASSWORD (TAHAP 2 - UPDATE PASSWORD DENGAN OTP) ===
  async resetPassword(email: string, code: string, newPassword: string) {
    // 1. Mengirimkan email, kode OTP verifikasi reset, dan password baru ke endpoint reset-password.
    const response = await fetch(`${API_URL}/auth/reset-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, code, newPassword }),
    });

    // 2. Parsing response.
    const data = await response.json();

    // 3. Jika OTP salah/kedaluwarsa, tampilkan pesan gagal.
    if (!response.ok) {
      throw new Error(data.message || 'Reset password gagal.');
    }

    return true;
  },

  logout() {
    // Menghapus data sesi saat logout
    localStorage.clear();
    sessionStorage.clear();
    window.location.href = '/login';
  },

  getToken() {
    return localStorage.getItem('token');
  },

  isAuthenticated() {
    return !!this.getToken();
  }
};
