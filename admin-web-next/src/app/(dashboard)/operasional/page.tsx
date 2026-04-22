// src/app/(dashboard)/operasional/page.tsx
'use client'

import OperationalPage from '@views/operasional/OperationalPage'
import RoleGuard from '@/hocs/RoleGuard'

export default function page() {
  return (
    <RoleGuard allowedRoles={['ADMIN', 'OWNER']}>
      <OperationalPage />
    </RoleGuard>
  )
}
