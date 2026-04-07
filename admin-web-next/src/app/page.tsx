'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { authService } from '@/libs/auth'

export default function RootPage() {
  const router = useRouter()

  useEffect(() => {
    if (authService.isAuthenticated()) {
      router.replace('/dashboard')
    } else {
      router.replace('/landing')
    }
  }, [router])

  return null
}
