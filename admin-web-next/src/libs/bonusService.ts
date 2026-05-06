// src/libs/bonusService.ts

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

const getAuthHeaders = () => {
    const token = localStorage.getItem('token');

    
return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };
};

export interface Bonus {
    id: string;
    user_id: string;
    user: {
        name: string;
        email: string;
    };
    title: string;
    description: string;
    amount: number;
    date: string;
    created_at: string;
}

export const bonusService = {
    // 1. Create Bonus
    async createBonus(data: { user_id: string, title: string, amount: number, date: string, description?: string }) {
        const response = await fetch(`${API_URL}/admin/bonuses`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data)
        });

        const resData = await response.json();

        if (!response.ok) throw new Error(resData.message || 'Gagal mencatat bonus');
        
return resData.data;
    },

    // 2. Get Bonuses
    async getBonuses(page = 1, limit = 10, month = '', year = '', search = '') {
        const queryParams = new URLSearchParams({
            page: page.toString(),
            limit: limit.toString(),
            month,
            year,
            search
        });

        const response = await fetch(`${API_URL}/admin/bonuses?${queryParams}`, {
            headers: getAuthHeaders()
        });

        const resData = await response.json();

        if (!response.ok) throw new Error(resData.message || 'Gagal mengambil data bonus');
        
return resData;
    },

    // 3. Delete Bonus
    async deleteBonus(id: string) {
        const response = await fetch(`${API_URL}/admin/bonuses/${id}`, {
            method: 'DELETE',
            headers: getAuthHeaders()
        });

        const resData = await response.json();

        if (!response.ok) throw new Error(resData.message || 'Gagal menghapus bonus');
        
return resData.data;
    },

    // 4. Get Bonus Years
    async getBonusYears() {
        const response = await fetch(`${API_URL}/admin/bonuses/years`, {
            headers: getAuthHeaders()
        });

        const resData = await response.json();

        if (!response.ok) throw new Error(resData.message || 'Gagal mengambil daftar tahun');
        
return resData.data;
    }
};
