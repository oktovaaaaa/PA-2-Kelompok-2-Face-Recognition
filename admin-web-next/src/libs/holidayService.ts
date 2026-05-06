// src/libs/holidayService.ts

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

const getAuthHeaders = () => {
    const token = localStorage.getItem('token');

    
return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };
};

export interface Holiday {
    id: string;
    company_id: string;
    name: string;
    description: string;
    start_date: string;
    end_date: string;
    created_at: string;
}

export interface AttendanceSettings {
    company_id: string;
    work_days: string; // format: "Monday,Tuesday,..."
    late_penalty_tiers: any;

    // ... fields lainnya
}

export const holidayService = {
    // 1. Get List Holidays
    async getHolidays() {
        const response = await fetch(`${API_URL}/admin/holidays`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal mengambil data libur.');
        
return data.data as Holiday[];
    },

    // 2. Create Holiday
    async createHoliday(data: { name: string; description: string; start_date: string; end_date: string }) {
        const response = await fetch(`${API_URL}/admin/holidays`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });

        const resData = await response.json();

        if (!response.ok) throw new Error(resData.message || 'Gagal membuat hari libur.');
        
return resData.data as Holiday;
    },

    // 3. Update Holiday
    async updateHoliday(id: string, data: { name: string; description: string; start_date: string; end_date: string }) {
        const response = await fetch(`${API_URL}/admin/holidays/${id}`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });

        const resData = await response.json();

        if (!response.ok) throw new Error(resData.message || 'Gagal memperbarui hari libur.');
        
return resData.data as Holiday;
    },

    // 4. Delete Holiday
    async deleteHoliday(id: string) {
        const response = await fetch(`${API_URL}/admin/holidays/${id}`, {
            method: 'DELETE',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal menghapus hari libur.');
        
return data;
    },

    // 5. Delete Past Holidays
    async deletePastHolidays() {
        const response = await fetch(`${API_URL}/admin/holidays/past`, {
            method: 'DELETE',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal menghapus riwayat libur.');
        
return data;
    },

    // 6. Get Attendance Settings (untuk work_days)
    async getSettings() {
        const response = await fetch(`${API_URL}/admin/attendance-settings`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal mengambil pengaturan.');
        
return data.data as AttendanceSettings;
    },

    // 7. Update Attendance Settings (untuk work_days)
    async updateSettings(settings: any) {
        const response = await fetch(`${API_URL}/admin/attendance-settings`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify(settings),
        });

        const data = await response.json();

        if (!response.ok) throw new Error(data.message || 'Gagal menyimpan pengaturan.');
        
return data;
    }
};
