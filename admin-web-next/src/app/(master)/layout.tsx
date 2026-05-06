import React from 'react'

import Box from '@mui/material/Box'

import SuperAdminSideNav from '@/components/super-admin/SideNav'
import Providers from '@components/Providers'

const SuperAdminLayout = ({ children }: { children: React.ReactNode }) => {
  return (
    <Providers direction="ltr">
      <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: '#0F172A' }}>
        <SuperAdminSideNav />
        <Box 
          component="main" 
          sx={{ 
            flexGrow: 1, 
            ml: '280px', 
            p: 8,
            minHeight: '100vh',
            bgcolor: '#F8FAFC', // Light background for content area to maintain readability
            borderTopLeftRadius: 40,
            mt: 4,
            mr: 4,
            mb: 4,
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)'
          }}
        >
          {children}
        </Box>
      </Box>
    </Providers>
  )
}

export default SuperAdminLayout
