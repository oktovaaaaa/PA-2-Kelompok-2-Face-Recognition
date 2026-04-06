// src/libs/settingService.ts

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

const getAuthHeaders = () => {
    const token = localStorage.getItem('token');
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };
};

export const BASE_URL = 'http://localhost:8080';

export const formatImageUrl = (url?: string) => {
    if (!url) return undefined;
    if (url.startsWith('http')) return url;
    
    // Ensure no double slashes
    const cleanUrl = url.startsWith('/') ? url.slice(1) : url;
    return `${BASE_URL}/${cleanUrl}`;
};

export interface Profile {
    id: string;
    name: string;
    email: string;
    phone: string;
    birth_place: string;
    birth_date: string;
    address: string;
    photo_url: string;
    bank_name?: string;
    bank_account_number?: string;
}

export interface Company {
    id: string;
    name: string;
    address: string;
    email: string;
    phone: string;
    logo_url?: string;
}

export interface PenaltyTier {
    hours: number;
    penalty: number;
}

export interface AttendanceSettings {
    id: string;
    company_id: string;
    check_in_start: string;
    check_in_end: string;
    check_out_start: string;
    check_out_end: string;
    alpha_penalty: number;
    late_penalty: number;
    late_penalty_tiers: string; // JSON String from backend: [{"hours": 1, "penalty": 10000}]
    early_leave_penalty: number;
    work_days: string;
}

export interface ManualPenalty {
    id: string;
    user_id: string;
    title: string;
    amount: number;
    date: string;
    user?: {
        name: string;
    };
}

export interface Notification {
    id: string;
    user_id: string;
    company_id: string;
    title: string;
    body: string;
    type: string;
    ref_id: string;
    is_read: boolean;
    created_at: string;
}

export const settingService = {
    // 1. Profile Methods
    async getProfile() {
        const response = await fetch(`${API_URL}/profile`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memuat profil.');
        return data.data as Profile;
    },

    async updateProfile(data: Partial<Profile>) {
        const response = await fetch(`${API_URL}/profile`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal memperbarui profil.');
        return resData.data;
    },

    // 2. Security Methods
    async requestOTP() {
        const response = await fetch(`${API_URL}/profile/request-otp`, {
            method: 'POST',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengirim OTP.');
        return data;
    },

    async changePassword(data: { old_password?: string; otp_code?: string; new_password: string }) {
        const response = await fetch(`${API_URL}/profile/change-password`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal mengubah password.');
        return resData;
    },

    async changePIN(data: { old_pin?: string; otp_code?: string; new_pin: string }) {
        const response = await fetch(`${API_URL}/profile/change-pin`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal mengubah PIN.');
        return resData;
    },

    // 3. Company Methods
    async getCompany() {
        const response = await fetch(`${API_URL}/admin/company`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memuat data perusahaan.');
        return data.data as Company;
    },

    async updateCompany(data: Partial<Company>) {
        const response = await fetch(`${API_URL}/admin/company`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal memperbarui instansi.');
        return resData.data;
    },

    // 4. Manual Penalty Management
    async getManualPenalties(page: number = 1, limit: number = 10, month?: string, year?: string) {
        let url = `${API_URL}/admin/penalties?page=${page}&limit=${limit}`;
        if (month) url += `&month=${month}`;
        if (year) url += `&year=${year}`;

        const response = await fetch(url, {
            method: 'GET',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memuat data denda.');
        
        return {
            data: data.data.data as ManualPenalty[],
            total: data.data.total as number
        };
    },

    async getPenaltyYears() {
        const response = await fetch(`${API_URL}/admin/penalties/years`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memuat daftar tahun.');
        return data.data as string[];
    },

    async createManualPenalty(data: { user_id: string; amount: number; title: string; date: string }) {
        const response = await fetch(`${API_URL}/admin/penalties`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal menambahkan denda.');
        return resData.data;
    },

    async deletePenalty(id: string) {
        const response = await fetch(`${API_URL}/admin/penalties/${id}`, {
            method: 'DELETE',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal menghapus denda.');
        return data;
    },

    // 5. Attendance Settings
    async getAttendanceSettings() {
        const response = await fetch(`${API_URL}/admin/attendance-settings`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memuat pengaturan absensi.');
        return data.data as AttendanceSettings;
    },

    async updateAttendanceSettings(data: Partial<AttendanceSettings>) {
        const response = await fetch(`${API_URL}/admin/attendance-settings`, {
            method: 'PUT', // Using PUT for updates
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal memperbarui pengaturan.');
        return resData.data;
    },

    // 6. Common Upload Method
    async uploadFile(file: File) {
        const token = localStorage.getItem('token');
        const formData = new FormData();
        formData.append('file', file);

        const response = await fetch(`${API_URL}/upload`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
            },
            body: formData,
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengunggah file.');
        return data.data; // Expecting { url: string }
    },

    // 7. Notification Methods
    async getNotifications() {
        const response = await fetch(`${API_URL}/notifications`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memuat notifikasi.');
        return data.data as { notifications: Notification[], unread_count: number };
    },

    async markNotificationRead(id: string) {
        const response = await fetch(`${API_URL}/notifications/${id}/read`, {
            method: 'PUT',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal menandai notifikasi.');
        return data;
    },

    async markAllNotificationsRead() {
        const response = await fetch(`${API_URL}/notifications/read-all`, {
            method: 'PUT',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal menandai semua notifikasi.');
        return data;
    }
};
