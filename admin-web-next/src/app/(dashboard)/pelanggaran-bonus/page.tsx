// src/app/(dashboard)/pelanggaran-bonus/page.tsx
'use client'

import dynamic from 'next/dynamic'

import RoleGuard from '@/hocs/RoleGuard'

// Komponen dikelola di sisi klien
const AdjustmentDashboard = dynamic(() => import('@/views/payroll/AdjustmentDashboard'), { ssr: false })

export default function page() {
  return (
    <RoleGuard allowedRoles={['ADMIN', 'OWNER']}>
      <AdjustmentDashboard />
    </RoleGuard>
  )
}
