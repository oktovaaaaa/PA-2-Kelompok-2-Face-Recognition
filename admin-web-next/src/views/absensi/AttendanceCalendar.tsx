'use client'

import React, { useState } from 'react'

import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Grid from '@mui/material/Grid'
import Typography from '@mui/material/Typography'
import Button from '@mui/material/Button'
import { IconButton } from '@mui/material'

const AttendanceCalendar = () => {
  const [currentDate] = useState(new Date())
  const daysInMonth = 30
  const monthName = 'April 2026'

  // Mock data for attendance
  const attendanceData: Record<number, string> = {
    1: 'HADIR', 2: 'HADIR', 3: 'HADIR', 4: 'LIBUR', 5: 'LIBUR',
    6: 'HADIR', 7: 'TERLAMBAT', 8: 'HADIR', 9: 'HADIR', 10: 'IZIN',
    11: 'LIBUR', 12: 'LIBUR', 13: 'HADIR', 14: 'HADIR', 15: 'HADIR'
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'HADIR': return 'success.main'
      case 'TERLAMBAT': return 'warning.main'
      case 'IZIN': return 'info.main'
      case 'ALPA': return 'error.main'
      case 'LIBUR': return 'text.disabled'
      default: return 'transparent'
    }
  }

  return (
    <Card>
      <CardHeader 
        title='Kalender Kehadiran' 
        action={
          <div className='flex items-center gap-2'>
            <IconButton size='small'><i className='ri-arrow-left-s-line' /></IconButton>
            <Typography variant='h6'>{monthName}</Typography>
            <IconButton size='small'><i className='ri-arrow-right-s-line' /></IconButton>
          </div>
        }
      />
      <CardContent>
        <Grid container spacing={1} sx={{ textAlign: 'center', mb: 2 }}>
          {['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'].map(day => (
            <Grid item xs={1.7} key={day}>
              <Typography variant='caption' fontWeight='600'>{day}</Typography>
            </Grid>
          ))}
        </Grid>
        <Grid container spacing={1}>
          {Array.from({ length: daysInMonth }).map((_, i) => {
            const day = i + 1
            const status = attendanceData[day] || ''

            
return (
              <Grid item xs={1.7} key={day}>
                <Card 
                  variant='outlined' 
                  sx={{ 
                    height: 80, 
                    display: 'flex', 
                    flexDirection: 'column', 
                    alignItems: 'center', 
                    justifyContent: 'center',
                    bgcolor: status === 'LIBUR' ? 'action.hover' : 'background.paper',
                    borderColor: getStatusColor(status)
                  }}
                >
                  <Typography variant='body2' fontWeight='600'>{day}</Typography>
                  {status && status !== 'LIBUR' && (
                    <Typography variant='caption' sx={{ color: getStatusColor(status), fontSize: '0.6rem' }}>
                      {status}
                    </Typography>
                  )}
                </Card>
              </Grid>
            )
          })}
        </Grid>
        <div className='mt-6 flex flex-wrap gap-4'>
          <div className='flex items-center gap-2'><div className='w-3 h-3 rounded-full bg-success-main' style={{backgroundColor: '#4caf50'}} /> <Typography variant='caption'>Hadir</Typography></div>
          <div className='flex items-center gap-2'><div className='w-3 h-3 rounded-full bg-warning-main' style={{backgroundColor: '#ff9800'}} /> <Typography variant='caption'>Terlambat</Typography></div>
          <div className='flex items-center gap-2'><div className='w-3 h-3 rounded-full bg-info-main' style={{backgroundColor: '#2196f3'}} /> <Typography variant='caption'>Izin</Typography></div>
          <div className='flex items-center gap-2'><div className='w-3 h-3 rounded-full bg-error-main' style={{backgroundColor: '#f44336'}} /> <Typography variant='caption'>Alpa</Typography></div>
        </div>
      </CardContent>
    </Card>
  )
}

export default AttendanceCalendar
