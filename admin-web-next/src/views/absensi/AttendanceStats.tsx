'use client'

import React, { useState, useEffect } from 'react'

import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Divider from '@mui/material/Divider'
import Typography from '@mui/material/Typography'
import Avatar from '@mui/material/Avatar'

import { attendanceService } from '@/libs/attendanceService'

interface AttendanceStatsProps {
  period: string
  month: number
  year: number
}

const AttendanceStats = ({ period, month, year }: AttendanceStatsProps) => {
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState<any>(null)

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true)

      try {
        const data = await attendanceService.getDetailedSummary({
            filter: period,
            month: month,
            year: year
        })

        setStats(data)
      } catch (error) {
        console.error('Error fetching detailed stats:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [period, month, year])

  if (loading) return <div>Loading Summary...</div>

  // Data for Top 4 Summary Cards
  const summaryCards = [
    { title: 'Total Karyawan', count: stats?.total || 0, icon: 'ri-group-line', color: 'primary' },
    { title: 'Hadir Tepat Waktu', count: stats?.present || 0, icon: 'ri-checkbox-circle-line', color: 'success' },
    { title: 'Terlambat', count: stats?.late || 0, icon: 'ri-time-line', color: 'warning' },
    { title: 'Alpha', count: stats?.absent || 0, icon: 'ri-close-circle-line', color: 'error' }
  ]

  return (
    <Grid container spacing={6}>
      {/* 1. Top Summary Cards */}
      {summaryCards.map((item, index) => (
        <Grid item xs={12} sm={6} md={3} key={index}>
          <Card>
            <CardContent className='flex items-center gap-4'>
              <Avatar variant='rounded' sx={{ bgcolor: `${item.color}.lighterOpacity`, color: `${item.color}.main` }}>
                <i className={item.icon} />
              </Avatar>
              <div>
                <Typography variant='caption'>{item.title}</Typography>
                <Typography variant='h5'>{item.count}</Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
      ))}

    </Grid>
  )
}

export default AttendanceStats
