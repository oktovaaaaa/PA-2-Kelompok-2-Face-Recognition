// src/app/(dashboard)/karyawan/page.tsx
'use client'

import React from 'react'

import EmployeeList from '@views/karyawan/EmployeeList'
import RoleGuard from '@/hocs/RoleGuard'

export default function KaryawanPage() {
  return (
    <RoleGuard allowedRoles={['ADMIN', 'OWNER']}>
      <EmployeeList />
    </RoleGuard>
  )
}
