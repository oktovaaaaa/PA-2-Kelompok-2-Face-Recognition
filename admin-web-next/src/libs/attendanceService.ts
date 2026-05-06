// admin-web-next/src/libs/attendanceService.ts

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

const getAuthHeaders = () => {
  const token = localStorage.getItem('token');

  
return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };
};

export interface AttendanceHistoryParams {
    status?: string;
    start_date?: string;
    end_date?: string;
    filter?: string;
    month?: string | number;
    year?: string | number;
    user_id?: string;
}

export const attendanceService = {
  // 1. Get Dashboard Summary (Basic)
  async getDashboardSummary() {
    const response = await fetch(`${API_URL}/admin/dashboard/summary`, {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    const data = await response.json();

    if (!response.ok) {
        if (response.status === 401) window.location.href = '/login';
        throw new Error(data.message || 'Gagal mengambil ringkasan dashboard.');
    }

    
return data.data;
  },

  // 2. Get Detailed Dashboard Summary (Status Breakdown for List)
  async getDetailedSummary(params: any = {}) {
    const queryParams = new URLSearchParams(params).toString();

    const response = await fetch(`${API_URL}/admin/dashboard/detailed-summary?${queryParams}`, {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    const data = await response.json();

    if (!response.ok) throw new Error(data.message || 'Gagal mengambil ringkasan detail.');
    
return data.data;
  },

  // 2.5 Get Attendance Trend (Line Chart)
  async getAttendanceTrend(params: any = {}) {
    // Clean up empty params
    const cleanParams: any = {};

    Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== '' && value !== null) {
            cleanParams[key] = value;
        }
    });

    const queryParams = new URLSearchParams(cleanParams).toString();

    const response = await fetch(`${API_URL}/admin/dashboard/trend?${queryParams}`, {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    const data = await response.json();

    if (!response.ok) throw new Error(data.message || 'Gagal mengambil data tren.');
    
return data.data;
  },

  // 3. Get All Attendance History (Table)
  async getAttendanceHistory(filters: AttendanceHistoryParams = {}) {
    // Clean up empty params
    const cleanParams: any = {};

    Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== '' && value !== null) {
            cleanParams[key] = value;
        }
    });

    const queryParams = new URLSearchParams(cleanParams).toString();

    const response = await fetch(`${API_URL}/admin/attendance?${queryParams}`, {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    const data = await response.json();

    if (!response.ok) throw new Error(data.message || 'Gagal mengambil riwayat kehadiran.');
    
return data.data;
  },

  // 4. Get Available Years for Filter
  async getAttendanceYears() {
    const response = await fetch(`${API_URL}/admin/attendance/years`, {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    const data = await response.json();

    if (!response.ok) throw new Error(data.message || 'Gagal mengambil daftar tahun.');
    
return data.data || [];
  },

  // 5. Get Settings
  async getSettings() {
    const response = await fetch(`${API_URL}/admin/attendance-settings`, {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    const data = await response.json();

    if (!response.ok) throw new Error(data.message || 'Gagal mengambil pengaturan absensi.');
    
return data.data;
  },
  
  // 6. Pardon/Excuse Attendance Violation
  async pardonAttendance(userId: string, date: string) {
    const response = await fetch(`${API_URL}/admin/attendance/pardon`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({ user_id: userId, date })
    });
    
    const data = await response.json();

    if (!response.ok) throw new Error(data.message || 'Gagal menghapus sanksi absensi.');
    
return data.data;
  }
};
