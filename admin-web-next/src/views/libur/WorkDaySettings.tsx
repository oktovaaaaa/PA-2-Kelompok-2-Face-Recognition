// src/views/libur/WorkDaySettings.tsx
'use client'

import React from 'react'

import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import Tooltip from '@mui/material/Tooltip'

interface Props {
  workDays: string[]
  onToggle: (day: string) => void
  onSave: () => void
  loading?: boolean
}

const ALL_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

const DAY_LABELS: { [key: string]: string } = {
  'Monday': 'Sen', 'Tuesday': 'Sel', 'Wednesday': 'Rab', 'Thursday': 'Kam', 'Friday': 'Jum', 'Saturday': 'Sab', 'Sunday': 'Min'
}

const WorkDaySettings = ({ workDays, onToggle, onSave, loading }: Props) => {
  return (
    <Card sx={{ mb: 6 }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 4 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <i className='ri-calendar-check-line' style={{ fontSize: '1.5rem', color: 'primary' }} />
            <Typography variant='h6' fontWeight='700'>Jadwal Kerja Rutin Mingguan</Typography>
          </Box>
          <Button 
            variant='contained' 
            onClick={onSave} 
            disabled={loading}
            size='small'
          >
            {loading ? 'Menyimpan...' : 'Simpan Jadwal'}
          </Button>
        </Box>
        
        <Typography variant='body2' color='text.secondary' sx={{ mb: 6 }}>
            Pilih hari kerja aktif perusahaan Anda. Hari yang tidak dipilih akan dianggap sebagai hari libur rutin.
        </Typography>

        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 4, justifyContent: 'center', py: 2 }}>
          {ALL_DAYS.map((day) => {
            const isSelected = workDays.includes(day)
            const isWeekend = day === 'Saturday' || day === 'Sunday'
            
            return (
              <Tooltip key={day} title={day}>
                <Box
                  onClick={() => onToggle(day)}
                  sx={{
                    width: 50,
                    height: 50,
                    borderRadius: '50%',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: 'pointer',
                    fontWeight: 'bold',
                    fontSize: '0.9rem',
                    transition: 'all 0.2s ease',
                    border: '2px solid',
                    borderColor: isSelected ? 'primary.main' : 'divider',
                    bgcolor: isSelected ? 'primary.main' : 'background.paper',
                    color: isSelected ? 'primary.contrastText' : (isWeekend ? 'error.light' : 'text.secondary'),
                    boxShadow: isSelected ? theme => `0 4px 12px ${theme.palette.primary.main}40` : 'none',
                    '&:hover': {
                      transform: 'translateY(-2px)',
                      borderColor: 'primary.main',
                      color: isSelected ? 'primary.contrastText' : 'primary.main'
                    }
                  }}
                >
                  {DAY_LABELS[day]}
                </Box>
              </Tooltip>
            )
          })}
        </Box>
      </CardContent>
    </Card>
  )
}

export default WorkDaySettings
