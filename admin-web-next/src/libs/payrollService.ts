// src/libs/payrollService.ts

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api'

const getAuthHeaders = (isMultipart = false) => {
  const token = localStorage.getItem('token')

  const headers: any = {
    'Authorization': `Bearer ${token}`
  }

  if (!isMultipart) {
    headers['Content-Type'] = 'application/json'
  }

  
return headers
}

export interface SalaryPayment {
  id: string
  salary_id: string
  amount: number
  proof: string
  paid_at: string
}

export interface Salary {
  id: string
  user_id: string
  month: number
  year: number
  base_salary: number
  deductions: number
  bonuses: number
  total_salary: number
  paid_amount: number
  deductions_detail: string
  bonuses_detail: string
  status: 'PENDING' | 'PARTIAL' | 'PAID'
  payment_proof?: string
  paid_at?: string
  created_at: string
  user: {
    name: string
    email: string
    photo_url: string
    bank_name?: string
    bank_account_number?: string
    position?: {
      name: string
    }
  }
  payments?: SalaryPayment[]
}

export const payrollService = {
  // 1. Get Payroll List for Admin
  async getAdminSalaries(filters: { month?: number; year?: number; position_id?: string; search?: string }) {
    const params = new URLSearchParams()

    if (filters.month) params.append('month', filters.month.toString())
    if (filters.year) params.append('year', filters.year.toString())
    if (filters.position_id) params.append('position_id', filters.position_id)
    if (filters.search) params.append('search', filters.search)

    const response = await fetch(`${API_URL}/admin/payroll?${params.toString()}`, {
      method: 'GET',
      headers: getAuthHeaders()
    })

    const data = await response.json()

    if (!response.ok) throw new Error(data.message || 'Gagal mengambil data payroll.')
    
return data.data as Salary[]
  },

  // 2. Process Payment (Full or Partial)
  async paySalary(salaryId: string, amount: string, proofFile?: File) {
    const formData = new FormData()

    formData.append('amount', amount)

    if (proofFile) {
      formData.append('proof', proofFile)
    }

    const response = await fetch(`${API_URL}/admin/payroll/${salaryId}/pay`, {
      method: 'POST',
      headers: getAuthHeaders(true),
      body: formData
    })

    const data = await response.json()

    if (!response.ok) throw new Error(data.message || 'Gagal memproses pembayaran.')
    
return data.data as Salary
  },

  // 3. Simple Years Fetcher (Reuse from attendance if needed, but let's have it here)
  async getPayrollYears() {
     const response = await fetch(`${API_URL}/admin/attendance/years`, { // Fallback to attendance years if dedicated payroll years not exists
      method: 'GET',
      headers: getAuthHeaders()
    })

    const data = await response.json()

    
return data.data as string[]
  }
}
