'use client'

import React from 'react'

import TestimonialList from '@views/testimoni/TestimonialList'
import RoleGuard from '@/hocs/RoleGuard'

export default function TestimoniPage() {
  return (
    <RoleGuard allowedRoles={['SUPER_ADMIN']}>
      <TestimonialList />
    </RoleGuard>
  )
}
