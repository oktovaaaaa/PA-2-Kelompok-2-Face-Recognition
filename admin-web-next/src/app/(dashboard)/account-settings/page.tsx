// src/app/(dashboard)/account-settings/page.tsx
'use client'

import { useState, useEffect, type ReactElement } from 'react'

import dynamic from 'next/dynamic'

import AccountSettings from '@views/account-settings'

const AccountTab = dynamic(() => import('@views/account-settings/account'))
const SecurityTab = dynamic(() => import('@views/account-settings/security'))
const CompanyTab = dynamic(() => import('@views/account-settings/company'))
const DevicesTab = dynamic(() => import('@views/account-settings/devices'))

const AccountSettingsPage = () => {
  const [role, setRole] = useState<string | null>(null)

  useEffect(() => {
    const savedRole = localStorage.getItem('role')

    setRole(savedRole)
  }, [])

  const getTabContentList = (): { [key: string]: ReactElement } => {
    const tabs: { [key: string]: ReactElement } = {
      account: <AccountTab />,
      security: <SecurityTab />,
      devices: <DevicesTab />,
    }

    // Hanya tampilkan tab instansi jika bukan Super Admin
    if (role !== 'SUPER_ADMIN') {
      tabs.company = <CompanyTab />
    }

    return tabs
  }

  return <AccountSettings tabContentList={getTabContentList()} />
}

export default AccountSettingsPage
