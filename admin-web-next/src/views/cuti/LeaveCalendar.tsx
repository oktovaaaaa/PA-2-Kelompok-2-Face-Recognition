// src/views/cuti/LeaveCalendar.tsx
'use client'

import React, { useState, useMemo } from 'react'

import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'
import IconButton from '@mui/material/IconButton'
import Grid from '@mui/material/Grid'
import Tooltip from '@mui/material/Tooltip'
import Badge from '@mui/material/Badge'

import { format, startOfMonth, endOfMonth, startOfWeek, endOfWeek, addDays, isSameMonth, isSameDay, addMonths, subMonths } from 'date-fns'

import type { LeaveRequest } from '@/libs/leaveService'

interface Props {
  leaves: LeaveRequest[]
  onDateClick: (date: Date) => void
}

const LeaveCalendar = ({ leaves, onDateClick }: Props) => {
  const [currentMonth, setCurrentMonth] = useState(new Date())

  const renderHeader = () => {
    return (
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 6, px: 2 }}>
        <Typography variant='h6' fontWeight='700'>
          {format(currentMonth, 'MMMM yyyy')}
        </Typography>
        <Box>
          <IconButton size='small' onClick={() => setCurrentMonth(subMonths(currentMonth, 1))}>
            <i className='ri-arrow-left-s-line' />
          </IconButton>
          <IconButton size='small' onClick={() => setCurrentMonth(addMonths(currentMonth, 1))}>
            <i className='ri-arrow-right-s-line' />
          </IconButton>
        </Box>
      </Box>
    )
  }

  const renderDays = () => {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']

    
return (
      <Grid container spacing={1} sx={{ mb: 2 }}>
        {days.map((day, i) => (
          <Grid item xs={12/7} key={i} sx={{ textAlign: 'center' }}>
            <Typography variant='caption' fontWeight='600' color='text.secondary'>
              {day}
            </Typography>
          </Grid>
        ))}
      </Grid>
    )
  }

  const renderCells = () => {
    const monthStart = startOfMonth(currentMonth)
    const monthEnd = endOfMonth(monthStart)
    const startDate = startOfWeek(monthStart)
    const endDate = endOfWeek(monthEnd)

    const rows = []
    let days = []
    let day = startDate
    let formattedDate = ''

    while (day <= endDate) {
      for (let i = 0; i < 7; i++) {
        formattedDate = format(day, 'd')
        const cloneDay = day
        
        // Find leaves for this day
        const dayLeaves = leaves.filter(l => {
           // We'll normalize date strings from backend
           const lDate = new Date(l.created_at)

           
return isSameDay(lDate, cloneDay)
        })

        days.push(
          <Grid 
            item 
            xs={12/7} 
            key={day.toString()} 
            sx={{ 
                height: 80, 
                border: theme => `1px solid ${theme.palette.divider}`,
                cursor: 'pointer',
                bgcolor: !isSameMonth(day, monthStart) ? 'action.hover' : 'background.paper',
                '&:hover': { bgcolor: 'action.selected' },
                p: 1,
                position: 'relative'
            }}
            onClick={() => onDateClick(cloneDay)}
          >
            <Typography 
                variant='body2' 
                sx={{ 
                    color: !isSameMonth(day, monthStart) ? 'text.disabled' : 'text.primary',
                    fontWeight: isSameDay(day, new Date()) ? '800' : '400',
                    textAlign: 'right'
                }}
            >
              {formattedDate}
            </Typography>
            
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5, mt: 1, overflow: 'hidden' }}>
                {dayLeaves.slice(0, 2).map((l, idx) => (
                   <Tooltip key={l.id} title={`${l.user_name}: ${l.title}`}>
                      <Box sx={{ 
                          height: 6, 
                          bgcolor: l.status === 'APPROVED' ? 'success.main' : l.status === 'REJECTED' ? 'error.main' : 'warning.main',
                          borderRadius: '2px',
                          width: '100%'
                      }} />
                   </Tooltip>
                ))}
                {dayLeaves.length > 2 && (
                    <Typography variant='caption' sx={{ fontSize: '0.6rem', textAlign: 'center' }}>
                        +{dayLeaves.length - 2} more
                    </Typography>
                )}
            </Box>
          </Grid>
        )
        day = addDays(day, 1)
      }

      rows.push(
        <Grid container spacing={0} key={day.toString()}>
          {days}
        </Grid>
      )
      days = []
    }

    
return <Box sx={{ borderRadius: 1, overflow: 'hidden', border: theme => `1px solid ${theme.palette.divider}` }}>{rows}</Box>
  }

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        {renderHeader()}
        {renderDays()}
        {renderCells()}
        <Box sx={{ mt: 4, display: 'flex', gap: 4, flexWrap: 'wrap' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Box sx={{ width: 10, height: 10, borderRadius: '2px', bgcolor: 'warning.main' }} />
                <Typography variant='caption'>Menunggu</Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Box sx={{ width: 10, height: 10, borderRadius: '2px', bgcolor: 'success.main' }} />
                <Typography variant='caption'>Disetujui</Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Box sx={{ width: 10, height: 10, borderRadius: '2px', bgcolor: 'error.main' }} />
                <Typography variant='caption'>Ditolak</Typography>
            </Box>
            <Typography variant='caption' color='text.secondary' sx={{ ml: 'auto' }}>
                * Klik tanggal untuk menambah izin
            </Typography>
        </Box>
      </CardContent>
    </Card>
  )
}

export default LeaveCalendar
