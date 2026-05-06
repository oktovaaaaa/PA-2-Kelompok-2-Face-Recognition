'use client'

import { useEffect, useState, type ReactNode } from 'react'

import { useRouter } from 'next/navigation'

import CircularProgress from '@mui/material/CircularProgress'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'

import { useNotification } from '@/contexts/NotificationContext'

interface RoleGuardProps {
  children: ReactNode
  allowedRoles: string[]
  fallbackPath?: string
}

export default function RoleGuard({ children, allowedRoles, fallbackPath = '/dashboard' }: RoleGuardProps) {
  const [authorized, setAuthorized] = useState(false)
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const { showNotification } = useNotification()

  useEffect(() => {
    const role = localStorage.getItem('role')
    
    if (!role || !allowedRoles.includes(role)) {
      showNotification('Akses ditolak: Anda tidak memiliki wewenang untuk membuka halaman ini.', 'error')
      router.replace(fallbackPath)
    } else {
      setAuthorized(true)
      setLoading(false)
    }
  }, [allowedRoles, fallbackPath, router, showNotification])

  if (loading || !authorized) {
    return (
      <Box className='flex flex-col items-center justify-center min-bs-[400px] gap-4'>
        <CircularProgress size={40} thickness={4} />
        <Typography variant='caption' className='font-bold text-slate-400 uppercase tracking-widest'>Memverifikasi Wewenang...</Typography>
      </Box>
    )
  }

  return <>{children}</>
}
