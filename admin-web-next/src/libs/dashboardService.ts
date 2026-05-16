// src/libs/dashboardService.ts

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

const getAuthHeaders = () => {
    const token = localStorage.getItem('token');

    
return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };
};

export interface DashboardSummary {
    present: number;
    absent: number;
    late: number;
    leave: number;
    sick: number;
    working: number;
    not_yet: number;
    early_leave: number;
    late_early_leave: number;
    total: number;
}

export interface AttendanceTrend {
    labels: string[];
    present: number[];
    late: number[];
    absent: number[];
    leave_sick: number[];
    early_leave: number[];
    late_early_leave: number[];
}

export interface AttendanceLog {
    id: string;
    user_id: string;
    user_name: string;
    user_email: string;
    photo_url: string;
    date: string;
    check_in_time: string | null;
    check_out_time: string | null;
    status: string;
    is_virtual: boolean;
}

export const dashboardService = {
    async getSummary(employeeId?: string): Promise<DashboardSummary> {
        let url = `${API_URL}/admin/dashboard/summary`;

        if (employeeId) url += `?user_id=${employeeId}`;

        const response = await fetch(url, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal memuat ringkasan dashboard.');
        
        return data.data as DashboardSummary;
    },

    async getTrend(filter: 'today' | '7days' | 'month' | 'year' = '7days', employeeId?: string): Promise<AttendanceTrend> {
        let url = `${API_URL}/admin/dashboard/trend?filter=${filter}`;

        if (employeeId) url += `&user_id=${employeeId}`;

        const response = await fetch(url, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal memuat tren kehadiran.');
        
        return data.data as AttendanceTrend;
    },

    async generateInviteToken(): Promise<{ token: string }> {
        const response = await fetch(`${API_URL}/admin/generate-invite`, {
            method: 'POST',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal membuat token undangan.');
        
return data.data as { token: string };
    },

    async getAttendanceLogs(date?: string, employeeId?: string): Promise<AttendanceLog[]> {
        // Use start_date and end_date for consistency with the backend AdminGetAttendanceHistory
        let params = date ? `?start_date=${date}&end_date=${date}&filter=today` : '';
        if (employeeId) {
            params += params ? `&user_id=${employeeId}` : `?user_id=${employeeId}`;
        }

        const response = await fetch(`${API_URL}/admin/attendance${params}`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal memuat log absensi.');
        
return data.data as AttendanceLog[];
    },

    // SUPER ADMIN SERVICES
    async getSuperAdminStats(): Promise<{ recent_companies: any[], recent_users: any[], stats: any }> {
        const response = await fetch(`${API_URL}/super-admin/stats`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal memuat statistik Super Admin.');
        
return data.data;
    },

    async getRegistrationTrend(year: number): Promise<number[]> {
        const response = await fetch(`${API_URL}/super-admin/registration-trend?year=${year}`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal memuat tren pendaftaran.');
        
return data.data as number[];
    },

    async getRegistrationYears(): Promise<number[]> {
        const response = await fetch(`${API_URL}/super-admin/registration-years`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal memuat daftar tahun.');
        
return data.data as number[];
    }
};
