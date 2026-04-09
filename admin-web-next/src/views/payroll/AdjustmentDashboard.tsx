// src/views/payroll/AdjustmentDashboard.tsx

'use client'

import { useState } from 'react'
import { Box, Typography, Tabs, Tab, Card, CardContent, Divider } from '@mui/material'
import BonusManager from './BonusManager'
import PenaltyManager from '../operasional/PenaltyManager'

const AdjustmentDashboard = () => {
  const [activeTab, setActiveTab] = useState(0)

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue)
  }

  return (
    <Box sx={{ p: 2 }}>
      <Box sx={{ mb: 6 }}>
        <Typography variant='h4' sx={{ fontWeight: 800, mb: 1, display: 'flex', alignItems: 'center', gap: 2 }}>
          <i className='ri-equalizer-line' style={{ color: '#6366f1' }} />
          Manajemen Bonus & Sanksi
        </Typography>
        <Typography variant='body1' color='text.secondary'>
          Kelola penyesuaian gaji manual untuk setiap karyawan dalam satu dashboard terpadu.
        </Typography>
      </Box>

      <Card sx={{ border: '1px solid', borderColor: 'divider', boxShadow: 'none' }}>
        <Box sx={{ borderBottom: 1, borderColor: 'divider', bgcolor: 'background.paper' }}>
          <Tabs 
            value={activeTab} 
            onChange={handleChange} 
            indicatorColor="primary" 
            textColor="primary"
            sx={{ px: 4 }}
          >
            <Tab 
                label="Bonus & Insentif" 
                icon={<i className='ri-medal-line' />} 
                iconPosition="start" 
                sx={{ fontWeight: 'bold', minHeight: 64 }} 
            />
            <Tab 
                label="Pelanggaran & Sanksi" 
                icon={<i className='ri-error-warning-line' />} 
                iconPosition="start" 
                sx={{ fontWeight: 'bold', minHeight: 64 }} 
            />
          </Tabs>
        </Box>
        <CardContent sx={{ pt: 8, px: 6, pb: 10 }}>
          {activeTab === 0 && <BonusManager />}
          {activeTab === 1 && <PenaltyManager />}
        </CardContent>
      </Card>

      <Box sx={{ mt: 6, p: 4, bgcolor: 'primary.soft', borderRadius: 2, display: 'flex', alignItems: 'center', gap: 3, border: '1px dashed', borderColor: 'primary.main' }}>
         <i className='ri-information-fill' style={{ fontSize: '1.5rem', color: '#6366f1' }} />
         <Typography variant='body2' sx={{ color: 'primary.dark', fontWeight: 500 }}>
            Semua perubahan nominal di sini akan langsung dikalkulasikan ke dalam laporan payroll bulan terkait secara otomatis saat Anda menyimpan data.
         </Typography>
      </Box>
    </Box>
  )
}

export default AdjustmentDashboard
