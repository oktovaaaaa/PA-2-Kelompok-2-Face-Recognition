// src/app/(dashboard)/persetujuan/page.tsx
'use client'

import EmployeeApproval from '@views/karyawan/EmployeeApproval'
import RoleGuard from '@/hocs/RoleGuard'

export default function page() {
  return (
    <RoleGuard allowedRoles={['ADMIN', 'OWNER']}>
      <EmployeeApproval />
    </RoleGuard>
  )
}
