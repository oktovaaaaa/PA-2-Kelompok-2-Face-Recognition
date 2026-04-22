// src/app/(dashboard)/libur/page.tsx
'use client'

import HolidayPage from '@views/libur/HolidayPage'
import RoleGuard from '@/hocs/RoleGuard'

export default function page() {
  return (
    <RoleGuard allowedRoles={['ADMIN', 'OWNER']}>
      <HolidayPage />
    </RoleGuard>
  )
}
