// src/app/(dashboard)/pelanggaran-bonus/page.tsx

import dynamic from 'next/dynamic'

// Komponen dikelola di sisi klien
const AdjustmentDashboard = dynamic(() => import('@/views/payroll/AdjustmentDashboard'), { ssr: false })

export default function PelanggaranBonusPage() {
  return <AdjustmentDashboard />
}
