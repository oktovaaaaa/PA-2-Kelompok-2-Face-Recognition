// src/libs/leaveService.ts

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

const getAuthHeaders = () => {
    const token = localStorage.getItem('token');
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };
};

export const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:8080';

export const formatImageUrl = (url?: string) => {
    if (!url) return undefined;
    if (url.startsWith('http')) return url;
    
    // Ensure no double slashes
    const cleanUrl = url.startsWith('/') ? url.slice(1) : url;
    return `${BASE_URL}/${cleanUrl}`;
};

export interface LeaveRequest {
  id: string
  user_id: string
  user_name: string
  user_email: string
  user_photo: string
  company_id: string
  type: 'IZIN' | 'SAKIT' | 'CUTI'
  title: string
  description: string
  photo_url?: string
  status: 'PENDING' | 'APPROVED' | 'REJECTED'
  admin_note?: string
  dates?: string
  created_at: string
}

export const leaveService = {
  // Admin methods
  async getLeaves(params: { status?: string; month?: number; year?: number; search?: string }) {
    let url = `${API_URL}/admin/leaves?`;
    if (params.status) url += `status=${params.status}&`;
    if (params.month) url += `month=${params.month}&`;
    if (params.year) url += `year=${params.year}&`;
    if (params.search) url += `search=${encodeURIComponent(params.search)}&`;

    const response = await fetch(url, {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    const data = await response.json();
    if (!response.ok) throw new Error(data.message || 'Gagal mengambil data izin.');
    return data.data as LeaveRequest[];
  },

  async approveLeave(id: string, note?: string) {
    const response = await fetch(`${API_URL}/admin/leaves/${id}/approve`, {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify({ note }),
    });

    const data = await response.json();
    if (!response.ok) throw new Error(data.message || 'Gagal menyetujui izin.');
    return data;
  },

  async rejectLeave(id: string, note: string) {
    const response = await fetch(`${API_URL}/admin/leaves/${id}/reject`, {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify({ note }),
    });

    const data = await response.json();
    if (!response.ok) throw new Error(data.message || 'Gagal menolak izin.');
    return data;
  },

  async deleteLeave(id: string) {
    const response = await fetch(`${API_URL}/admin/leaves/${id}`, {
      method: 'DELETE',
      headers: getAuthHeaders(),
    });

    const data = await response.json();
    if (!response.ok) throw new Error(data.message || 'Gagal menghapus izin.');
    return data;
  },

  // Admin creating leave for employee
  async createLeave(data: { 
    user_id: string; 
    type: string; 
    title: string; 
    description: string; 
    date: string; 
    status: string 
  }) {
    const response = await fetch(`${API_URL}/admin/leaves`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify(data),
    });

    const resData = await response.json();
    if (!response.ok) throw new Error(resData.message || 'Gagal menambahkan izin.');
    return resData.data as LeaveRequest;
  }
}
