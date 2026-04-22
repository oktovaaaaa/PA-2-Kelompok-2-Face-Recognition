'use client'

import { useEffect, useState, type ReactNode } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import CircularProgress from '@mui/material/CircularProgress'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'

export default function AuthGuard({ children }: { children: ReactNode }) {
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const pathname = usePathname()

  useEffect(() => {
    const token = localStorage.getItem('token')
    
    if (!token && !pathname.includes('/login') && !pathname.includes('/register') && !pathname.includes('/forgot-password')) {
      router.replace('/login')
    } else {
      setLoading(false)
    }
  }, [pathname, router])

  if (loading) {
    return (
      <Box className='flex flex-col items-center justify-center min-bs-screen gap-4'>
        <CircularProgress size={40} thickness={4} />
        <Typography variant='caption' className='font-bold text-slate-400 uppercase tracking-widest'>Verifikasi Sesi...</Typography>
      </Box>
    )
  }

  return <>{children}</>
}
