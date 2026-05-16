// src/views/dashboard/AttendanceSummaryPie.tsx
'use client'

import { useState, useEffect } from 'react'

import dynamic from 'next/dynamic'

import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import Grid from '@mui/material/Grid'
import IconButton from '@mui/material/IconButton'
import type { ApexOptions } from 'apexcharts'

import type { DashboardSummary } from '@/libs/dashboardService'

const AppReactApexCharts = dynamic(() => import('@/libs/styles/AppReactApexCharts'))

interface Props {
  summary: DashboardSummary | null
  onRefresh: () => void
}

const AttendanceSummaryPie = ({ summary, onRefresh }: Props) => {
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])

  const isDataEmpty = !summary || (
    (summary.present || 0) === 0 &&
    (summary.late || 0) === 0 &&
    (summary.absent || 0) === 0 &&
    ((summary.leave || 0) + (summary.sick || 0)) === 0 &&
    (summary.working || 0) === 0 &&
    (summary.early_leave || 0) === 0 &&
    (summary.late_early_leave || 0) === 0 &&
    (summary.not_yet || 0) === 0
  );

  const pieOptions: ApexOptions = {
    labels: isDataEmpty ? ['Hari Libur'] : ['Hadir', 'Terlambat', 'Alpha', 'Izin/Sakit', 'Sedang Bekerja', 'Pulang di jam kerja', 'Terlambat & Pulang di jam kerja', 'Belum Hadir'],
    colors: isDataEmpty ? ['#E2E8F0'] : ['#22C55E', '#FBBF24', '#EF4444', '#0EA5E9', '#6366F1', '#F97316', '#D946EF', '#94A3B8'],
    legend: { show: false },
    dataLabels: { enabled: false },
    stroke: { width: 0 },
    plotOptions: {
      pie: {
        donut: {
          size: '75%',
          labels: {
            show: true,
            name: {
              show: true,
              color: 'var(--mui-palette-text-primary)'
            },
            value: {
              show: !isDataEmpty,
              color: 'var(--mui-palette-text-primary)'
            },
            total: {
              show: true,
              label: isDataEmpty ? 'HARI LIBUR' : 'Karyawan',
              fontSize: isDataEmpty ? '22px' : '14px',
              fontWeight: 700,
              color: isDataEmpty ? '#3B82F6' : 'var(--mui-palette-text-secondary)',
              offsetY: isDataEmpty ? 8 : 0,
              formatter: () => isDataEmpty ? '' : (summary?.total.toString() || '0')
            }
          }
        }
      }
    }
  }

  const pieSeries = summary ? (
    isDataEmpty ? [1] : [
      summary.present,
      summary.late,
      summary.absent,
      (summary.leave || 0) + (summary.sick || 0),
      summary.working,
      summary.early_leave,
      summary.late_early_leave,
      summary.not_yet
    ]
  ) : []

  return (
    <Card className='shadow-lg rounded-3xl h-full border-none'>
        <CardContent className='p-6'>
            <Box className='flex justify-between items-center mbe-8'>
                <Box>
                    <Typography variant='subtitle2' className='font-bold uppercase tracking-widest'>Ringkasan Kehadiran</Typography>
                    <Typography variant='caption' color='text.secondary'>Statistik kehadiran karyawan hari ini</Typography>
                </Box>
                <IconButton size='small' onClick={onRefresh}>
                    <i className='ri-refresh-line text-slate-400' />
                </IconButton>
            </Box>
            <Box className='flex flex-col items-center justify-center min-h-[300px] w-full'>
                {isMounted && summary ? (
                    <AppReactApexCharts type='donut' width='100%' height={300} options={pieOptions} series={pieSeries} />
                ) : (
                    <Box className='h-[300px] flex flex-col items-center justify-center gap-4'>
                        <i className='ri-loader-4-line animate-spin text-3xl text-blue-500' />
                        <Typography variant='caption' color='text.secondary' className='italic'>Memuat data ringkasan...</Typography>
                    </Box>
                )}
                <Grid container spacing={2} className='mbs-6'>
                    {[
                        { color: '#22C55E', label: 'Hadir', val: summary?.present },
                        { color: '#FBBF24', label: 'Telat', val: summary?.late },
                        { color: '#EF4444', label: 'Alpha', val: summary?.absent },
                        { color: '#0EA5E9', label: 'Izin', val: (summary?.leave || 0) + (summary?.sick || 0) },
                        { color: '#6366F1', label: 'Bekerja', val: summary?.working },
                        { color: '#F97316', label: 'Pulang JK', val: summary?.early_leave },
                        { color: '#D946EF', label: 'Telat & PJK', val: summary?.late_early_leave },
                        { color: '#94A3B8', label: 'Belum Hadir', val: summary?.not_yet }
                    ].map((item, idx) => (
                        <Grid item xs={6} key={idx}>
                            <Box className='flex items-center gap-2 p-2 rounded-xl bg-actionHover border border-divider'>
                                <Box className='w-2.5 h-2.5 rounded-full' style={{ backgroundColor: item.color }} />
                                <Typography variant='caption' className='whitespace-nowrap'>
                                    {item.label}: <b className='ml-1' style={{ color: 'var(--mui-palette-text-primary)' }}>{item.val || 0}</b>
                                </Typography>
                            </Box>
                        </Grid>
                    ))}
                </Grid>
            </Box>
        </CardContent>
    </Card>
  )
}

export default AttendanceSummaryPie
