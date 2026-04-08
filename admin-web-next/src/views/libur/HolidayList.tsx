// src/views/libur/HolidayList.tsx
'use client'

import React from 'react'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import IconButton from '@mui/material/IconButton'
import Chip from '@mui/material/Chip'
import Grid from '@mui/material/Grid'
import Tooltip from '@mui/material/Tooltip'
import { Holiday } from '@/libs/holidayService'
import { format, isPast } from 'date-fns'
import { formatFullDate } from '@/utils/dateFormatter'

interface Props {
  holidays: Holiday[]
  onEdit: (h: Holiday) => void
  onDelete: (id: string) => void
}

const HolidayList = ({ holidays, onEdit, onDelete }: Props) => {
  const upcomingHolidays = holidays.filter(h => !isPast(new Date(h.end_date)))
  const pastHolidays = holidays.filter(h => isPast(new Date(h.end_date)))

  const renderHolidayCard = (h: Holiday, isHistory = false) => {
    const startDate = new Date(h.start_date)
    const endDate = new Date(h.end_date)
    
    return (
      <Card key={h.id} sx={{ mb: 4, bgcolor: 'background.paper', position: 'relative', border: theme => isHistory ? `1px dashed ${theme.palette.divider}` : `1px solid ${theme.palette.divider}` }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <Box 
              sx={{ 
                bgcolor: isHistory ? 'action.hover' : 'primary.main', 
                color: isHistory ? 'text.secondary' : 'primary.contrastText',
                p: 2, borderRadius: 2, textAlign: 'center', minWidth: 60
              }}
            >
              <Typography variant='h6' sx={{ color: 'inherit', lineHeight: 1 }}>{format(startDate, 'dd')}</Typography>
              <Typography variant='caption' sx={{ color: 'inherit' }}>{format(startDate, 'MMM')}</Typography>
            </Box>
            
            <Box sx={{ flex: 1, overflow: 'hidden' }}>
              <Typography variant='subtitle1' fontWeight='700' noWrap>{h.name}</Typography>
              <Typography variant='caption' color='text.secondary'>
                {formatFullDate(h.start_date)} - {formatFullDate(h.end_date)}
              </Typography>
            </Box>

            <Box sx={{ display: 'flex', gap: 1 }}>
              {!isHistory && (
                <IconButton size='small' color='primary' onClick={() => onEdit(h)}>
                    <i className='ri-edit-line' />
                </IconButton>
              )}
              <IconButton size='small' color='error' onClick={() => onDelete(h.id)}>
                <i className='ri-delete-bin-line' />
              </IconButton>
            </Box>
          </Box>
          {h.description && (
            <Typography variant='body2' sx={{ mt: 3, pt: 3, borderTop: theme => `1px solid ${theme.palette.divider}`, fontStyle: 'italic', color: 'text.secondary' }}>
              {h.description}
            </Typography>
          )}
        </CardContent>
      </Card>
    )
  }

  return (
    <Box>
      {/* Upcoming */}
      <Box sx={{ mb: 8 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 4 }}>
          <i className='ri-upcoming-line' style={{ fontSize: '1.2rem', color: 'primary' }} />
          <Typography variant='subtitle1' fontWeight='700'>Libur Akan Datang</Typography>
          <Chip label={upcomingHolidays.length} size='small' color='primary' />
        </Box>
        <Grid container spacing={4}>
           {upcomingHolidays.length === 0 ? (
               <Grid item xs={12}>
                   <Typography variant='body2' color='text.secondary' align='center' sx={{ py: 6, bgcolor: 'action.hover', borderRadius: 1 }}>
                       Belum ada jadwal libur mendatang.
                   </Typography>
               </Grid>
           ) : upcomingHolidays.map(h => (
               <Grid item xs={12} md={6} key={h.id}>
                   {renderHolidayCard(h)}
               </Grid>
           ))}
        </Grid>
      </Box>

      {/* History */}
      <Box sx={{ opacity: 0.7 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 4 }}>
          <i className='ri-history-line' style={{ fontSize: '1.2rem' }} />
          <Typography variant='subtitle1' fontWeight='700'>Riwayat Libur</Typography>
        </Box>
        <Grid container spacing={4}>
           {pastHolidays.map(h => (
               <Grid item xs={12} md={6} key={h.id}>
                   {renderHolidayCard(h, true)}
               </Grid>
           ))}
        </Grid>
      </Box>
    </Box>
  )
}

export default HolidayList
