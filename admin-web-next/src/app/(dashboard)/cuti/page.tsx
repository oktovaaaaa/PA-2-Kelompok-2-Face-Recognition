// src/app/(dashboard)/cuti/page.tsx
'use client'

import LeavePage from '@views/cuti/LeavePage'
import RoleGuard from '@/hocs/RoleGuard'

export default function page() {
  return (
    <RoleGuard allowedRoles={['ADMIN', 'OWNER']}>
      <LeavePage />
    </RoleGuard>
  )
}
