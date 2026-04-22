// src/app/(dashboard)/dashboard/page.tsx
'use client'

import { useState, useEffect } from 'react'
import Grid from '@mui/material/Grid'

// View Components
import MainAdminDashboard from '@views/dashboard/MainAdminDashboard'
import MainSuperAdminDashboard from '@views/dashboard/MainSuperAdminDashboard'

const DashboardAnalytics = () => {
  const [role, setRole] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setRole(localStorage.getItem('role'))
    setLoading(false)
  }, [])

  if (loading) return null

  return (
    <Grid container spacing={6}>
      <Grid item xs={12}>
        {role === 'SUPER_ADMIN' ? <MainSuperAdminDashboard /> : <MainAdminDashboard />}
      </Grid>
    </Grid>
  )
}

export default DashboardAnalytics
