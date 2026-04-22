// src/app/(dashboard)/pengguna/page.tsx
'use client'

import React from 'react'
import SystemUserList from '@views/karyawan/SystemUserList'
import RoleGuard from '@/hocs/RoleGuard'

export default function PenggunaPage() {
  return (
    <RoleGuard allowedRoles={['SUPER_ADMIN']}>
      <SystemUserList />
    </RoleGuard>
  )
}
