// admin-web-next/src/libs/auth.ts

import { getBrowserInfo } from '@/utils/deviceInfo';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

export const authService = {
  // Step 1: Login with Email & Password
  async loginStep1(email: string, password: string) {
    const response = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, isAdminPanel: true }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Email atau password salah.');
    }

    return true;
  },

  // Send OTP (General)
  async sendOTP(email: string, isAdminPanel: boolean = false) {
    const response = await fetch(`${API_URL}/auth/send-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, isAdminPanel }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Gagal mengirim OTP.');
    }

    return true;
  },

  // Step 2: Verify OTP
  async loginStep2(email: string, code: string, rememberMe: boolean = false) {
    const response = await fetch(`${API_URL}/auth/verify-login-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        email, 
        code, 
        device_id: (() => {
          let id = localStorage.getItem('device_id');
          if (!id) {
            id = 'web-' + Math.random().toString(36).substring(2, 15);
            localStorage.setItem('device_id', id);
          }
          return id;
        })(),
        device_name: getBrowserInfo()
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Kode OTP tidak valid.');
    }

    const allowedRoles = ['ADMIN', 'SUPER_ADMIN', 'OWNER'];

    if (!data.data || !data.data.role || !allowedRoles.includes(data.data.role.toUpperCase())) {
      throw new Error('Akun ini tidak memiliki akses Administrator.')
    }

    // Store in localStorage
    const authData = data.data;

    localStorage.setItem('token', authData.token);
    localStorage.setItem('user_id', authData.userId);
    localStorage.setItem('user_name', authData.email ? authData.email.split('@')[0] : 'Admin');
    localStorage.setItem('role', authData.role);
    localStorage.setItem('company_id', authData.companyId);

    return authData;
  },

  async googleLogin(idToken: string) {
    const response = await fetch(`${API_URL}/auth/google-login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id_token: idToken }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Gagal login dengan Google.');
    }

    return true;
  },

  // Register Admin
  async register(name: string, email: string, password: string, companyName: string, otpCode: string) {
    const response = await fetch(`${API_URL}/auth/register-admin`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, password, companyName, otpCode }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Gagal mendaftarkan akun.');
    }

    return true;
  },

  // Forgot Password Step 1
  async requestResetOTP(email: string, isAdminPanel: boolean = false) {
    const response = await fetch(`${API_URL}/auth/forgot-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, isAdminPanel }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Email tidak ditemukan.');
    }

    return true;
  },

  // Forgot Password Step 2: Reset
  async resetPassword(email: string, code: string, newPassword: string) {
    const response = await fetch(`${API_URL}/auth/reset-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, code, newPassword }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Reset password gagal.');
    }

    return true;
  },

  logout() {
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
