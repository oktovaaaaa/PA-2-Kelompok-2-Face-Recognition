// src/views/cuti/LeaveHeader.tsx
'use client'

import React from 'react'

import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Avatar from '@mui/material/Avatar'
import Box from '@mui/material/Box'

interface Props {
  stats: {
    total: number
    pending: number
    approved: number
    rejected: number
  }
}

const LeaveHeader = ({ stats }: Props) => {
  const statCards = [
    { title: 'Total Pengajuan', value: stats.total, icon: 'ri-file-list-3-line', color: 'primary' },
    { title: 'Menunggu', value: stats.pending, icon: 'ri-time-line', color: 'warning' },
    { title: 'Disetujui', value: stats.approved, icon: 'ri-checkbox-circle-line', color: 'success' },
    { title: 'Ditolak', value: stats.rejected, icon: 'ri-close-circle-line', color: 'error' }
  ]

  return (
    <Grid container spacing={6}>
      {statCards.map((item, index) => (
        <Grid item xs={12} sm={6} md={3} key={index}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <Avatar 
                  variant='rounded' 
                  sx={{ 
                    bgcolor: theme => `rgba(${theme.palette[item.color as 'primary'].mainOpacity}, 0.1)`, 
                    color: `${item.color}.main`,
                    width: 44,
                    height: 44
                  }}
                >
                  <i className={item.icon} style={{ fontSize: '1.5rem' }} />
                </Avatar>
                <Box>
                  <Typography variant='body2' color='text.secondary'>{item.title}</Typography>
                  <Typography variant='h5' fontWeight='700'>{item.value}</Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  )
}

export default LeaveHeader
