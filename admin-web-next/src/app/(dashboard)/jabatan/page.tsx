// src/app/(dashboard)/jabatan/page.tsx
'use client'

import PositionList from '@views/jabatan/PositionList'
import RoleGuard from '@/hocs/RoleGuard'

export default function JabatanPage() {
  return (
    <RoleGuard allowedRoles={['ADMIN', 'OWNER']}>
      <PositionList />
    </RoleGuard>
  )
}
