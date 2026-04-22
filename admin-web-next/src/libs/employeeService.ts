// admin-web-next/src/libs/employeeService.ts

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

const getAuthHeaders = () => {
    const token = localStorage.getItem('token');
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };
};

export interface Employee {
    id: string;
    name: string;
    email: string;
    phone: string;
    photo_url: string;
    status: 'ACTIVE' | 'RESIGNED' | 'PENDING';
    position_id: string;
    position_name: string;
    salary: number;
    device_id: string;
    address: string;
    birth_date: string;
}

export interface Position {
    id: string;
    name: string;
    salary: number;
    description: string;
}

export const employeeService = {
    // 1. Get Employees List
    async getEmployees(status?: string) {
        let url = `${API_URL}/admin/employees`;
        if (status) url += `?status=${status}`;

        const response = await fetch(url, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengambil data karyawan.');
        return data.data as Employee[];
    },

    // 2. Get Positions
    async getPositions() {
        const response = await fetch(`${API_URL}/admin/positions`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengambil daftar jabatan.');
        return data.data as Position[];
    },

    // 3. Assign Position
    async assignPosition(userId: string, positionId: string) {
        const response = await fetch(`${API_URL}/admin/positions/assign`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ user_id: userId, position_id: positionId }),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal menetapkan jabatan.');
        return data;
    },

    // 3.1 Create Position
    async createPosition(data: { name: string, salary: number, description?: string }) {
        const response = await fetch(`${API_URL}/admin/positions`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });

        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal membuat jabatan.');
        return resData.data as Position;
    },

    // 3.2 Update Position
    async updatePosition(id: string, data: { name: string, salary: number, description?: string }) {
        const response = await fetch(`${API_URL}/admin/positions/${id}`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });

        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal memperbarui jabatan.');
        return resData.data as Position;
    },

    // 3.3 Delete Position
    async deletePosition(id: string) {
        const response = await fetch(`${API_URL}/admin/positions/${id}`, {
            method: 'DELETE',
            headers: getAuthHeaders(),
        });

        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal menghapus jabatan.');
        return resData;
    },

    // 4. Fire/Resign Employee
    async fireEmployee(userId: string, reason: string = '') {
        const response = await fetch(`${API_URL}/admin/employees/fire`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ user_id: userId, reason }),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memecat karyawan.');
        return data;
    },

    // 5. Reactivate Employee
    async reactivateEmployee(userId: string) {
        const response = await fetch(`${API_URL}/admin/employees/reactivate`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ user_id: userId }),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengaktifkan kembali karyawan.');
        return data;
    },

    // 6. Reset Device
    async resetDevice(userId: string) {
        const response = await fetch(`${API_URL}/admin/reset-device`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ user_id: userId }),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mereset perangkat.');
        return data;
    },

    // 7. Get Attendance History for Stats (User Specific)
    async getEmployeeAttendance(userId: string, filter: string = 'month', month?: string, year?: string) {
        let url = `${API_URL}/admin/attendance?user_id=${userId}&filter=${filter}`;
        if (month && month !== 'all') url += `&month=${month}`;
        if (year) url += `&year=${year}`;

        const response = await fetch(url, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengambil data statistik.');
        return data.data;
    },

    // 8. Get Available Attendance Years
    async getAttendanceYears() {
        const response = await fetch(`${API_URL}/admin/attendance/years`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengambil daftar tahun.');
        return data.data as string[];
    },

    // 9. Get Pending Employees (Approval)
    async getPendingEmployees() {
        const response = await fetch(`${API_URL}/admin/pending-employees`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengambil daftar pendaftaran.');
        return data.data as Employee[];
    },

    // 10. Approve Employee
    async approveEmployee(userId: string) {
        const response = await fetch(`${API_URL}/admin/approve-employee`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ user_id: userId }),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal menyetujui karyawan.');
        return data;
    },

    // 11. Reject Employee
    async rejectEmployee(userId: string) {
        const response = await fetch(`${API_URL}/admin/reject-employee`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ user_id: userId }),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal menolak karyawan.');
        return data;
    },

    // SUPER ADMIN SERVICES
    async getAllSystemUsers(status?: string) {
        let url = `${API_URL}/super-admin/users`;
        if (status) url += `?status=${status}`;

        const response = await fetch(url, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengambil data seluruh user.');
        return data.data as Employee[];
    },

    async getAllCompanies() {
        const response = await fetch(`${API_URL}/super-admin/companies`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengambil daftar perusahaan.');
        return data.data as any[];
    },

    async updateCompanyStatus(id: string, status: string) {
        const response = await fetch(`${API_URL}/super-admin/companies/${id}/status`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify({ status })
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memperbarui status perusahaan.');
        return data.data;
    }
};
