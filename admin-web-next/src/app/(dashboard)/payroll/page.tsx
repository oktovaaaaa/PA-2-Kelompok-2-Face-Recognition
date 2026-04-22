// src/app/(dashboard)/payroll/page.tsx
'use client'

import PayrollList from '@/views/payroll/PayrollList'
import RoleGuard from '@/hocs/RoleGuard'

export default function page() {
  return (
    <RoleGuard allowedRoles={['ADMIN', 'OWNER']}>
      <PayrollList />
    </RoleGuard>
  )
}
