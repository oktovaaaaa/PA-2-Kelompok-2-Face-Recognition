// src/views/dashboard/AttendanceTrendLine.tsx
'use client'

import dynamic from 'next/dynamic'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import type { ApexOptions } from 'apexcharts'
import { AttendanceTrend } from '@/libs/dashboardService'
import { useState, useEffect } from 'react'
import { useTheme } from '@mui/material/styles'

const AppReactApexCharts = dynamic(() => import('@/libs/styles/AppReactApexCharts'))

interface Props {
  trend: AttendanceTrend | null
}

const AttendanceTrendLine = ({ trend }: Props) => {
  const theme = useTheme()
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])
  
  const trendOptions: ApexOptions = {
    chart: {
      toolbar: { show: false },
      zoom: { enabled: false },
      parentHeightOffset: 0,
    },
    xaxis: {
      categories: trend?.labels || [],
      axisBorder: { show: false },
      axisTicks: { show: false },
      labels: { style: { colors: 'var(--mui-palette-text-secondary)', fontSize: '11px' } }
    },
    yaxis: {
      labels: {
        style: { colors: 'var(--mui-palette-text-secondary)', fontSize: '11px' },
        formatter: (val: number) => Math.round(val).toString()
      }
    },
    colors: ['#22C55E', '#FBBF24', '#EF4444', '#0EA5E9', '#F97316', '#D946EF'],
    stroke: { curve: 'smooth', width: 3 },
    fill: {
      type: 'gradient',
      gradient: {
        shadeIntensity: 1,
        opacityFrom: 0.4,
        opacityTo: 0.1,
        stops: [0, 90, 100]
      }
    },
    grid: {
      borderColor: 'var(--mui-palette-divider)',
      padding: { bottom: 12, left: -10, right: -10 }
    },
    markers: { size: 4, strokeWidth: 2, strokeColors: '#fff', hover: { size: 6 } },
    legend: { 
      position: 'top', 
      horizontalAlign: 'right',
      fontSize: '12px',
      fontWeight: 500,
      fontFamily: 'inherit',
      labels: {
        colors: 'var(--mui-palette-text-primary)'
      },
      markers: { size: 8, strokeWidth: 0 }
    },
    tooltip: {
      theme: theme.palette.mode as 'light' | 'dark',
      x: { show: true },
      y: { formatter: (val: number) => `${val} Karyawan` }
    }
  }

  // Preprocess data: if all categories for a day are 0, set them to null to create a gap in the chart
  const processedData = {
    present: trend?.present.map((v, i) => {
      const isHoliday = (
        (trend?.present?.[i] ?? 0) === 0 && 
        (trend?.late?.[i] ?? 0) === 0 && 
        (trend?.absent?.[i] ?? 0) === 0 && 
        (trend?.leave_sick?.[i] ?? 0) === 0 && 
        (trend?.early_leave?.[i] ?? 0) === 0 && 
        (trend?.late_early_leave?.[i] ?? 0) === 0
      );
      return isHoliday ? null : v;
    }) || [],
    late: trend?.late.map((v, i) => {
      const isHoliday = (
        (trend?.present?.[i] ?? 0) === 0 && 
        (trend?.late?.[i] ?? 0) === 0 && 
        (trend?.absent?.[i] ?? 0) === 0 && 
        (trend?.leave_sick?.[i] ?? 0) === 0 && 
        (trend?.early_leave?.[i] ?? 0) === 0 && 
        (trend?.late_early_leave?.[i] ?? 0) === 0
      );
      return isHoliday ? null : v;
    }) || [],
    absent: trend?.absent.map((v, i) => {
      const isHoliday = (
        (trend?.present?.[i] ?? 0) === 0 && 
        (trend?.late?.[i] ?? 0) === 0 && 
        (trend?.absent?.[i] ?? 0) === 0 && 
        (trend?.leave_sick?.[i] ?? 0) === 0 && 
        (trend?.early_leave?.[i] ?? 0) === 0 && 
        (trend?.late_early_leave?.[i] ?? 0) === 0
      );
      return isHoliday ? null : v;
    }) || [],
    leave_sick: trend?.leave_sick.map((v, i) => {
      const isHoliday = (
        (trend?.present?.[i] ?? 0) === 0 && 
        (trend?.late?.[i] ?? 0) === 0 && 
        (trend?.absent?.[i] ?? 0) === 0 && 
        (trend?.leave_sick?.[i] ?? 0) === 0 && 
        (trend?.early_leave?.[i] ?? 0) === 0 && 
        (trend?.late_early_leave?.[i] ?? 0) === 0
      );
      return isHoliday ? null : v;
    }) || [],
    early_leave: trend?.early_leave.map((v, i) => {
      const isHoliday = (
        (trend?.present?.[i] ?? 0) === 0 && 
        (trend?.late?.[i] ?? 0) === 0 && 
        (trend?.absent?.[i] ?? 0) === 0 && 
        (trend?.leave_sick?.[i] ?? 0) === 0 && 
        (trend?.early_leave?.[i] ?? 0) === 0 && 
        (trend?.late_early_leave?.[i] ?? 0) === 0
      );
      return isHoliday ? null : v;
    }) || [],
    late_early_leave: trend?.late_early_leave.map((v, i) => {
      const isHoliday = (
        (trend?.present?.[i] ?? 0) === 0 && 
        (trend?.late?.[i] ?? 0) === 0 && 
        (trend?.absent?.[i] ?? 0) === 0 && 
        (trend?.leave_sick?.[i] ?? 0) === 0 && 
        (trend?.early_leave?.[i] ?? 0) === 0 && 
        (trend?.late_early_leave?.[i] ?? 0) === 0
      );
      return isHoliday ? null : v;
    }) || []
  };

  const trendSeries = [
    { name: 'Hadir Tepat Waktu', data: processedData.present },
    { name: 'Terlambat', data: processedData.late },
    { name: 'Alpha', data: processedData.absent },
    { name: 'Izin/Sakit', data: processedData.leave_sick },
    { name: 'Pulang di jam kerja', data: processedData.early_leave },
    { name: 'Terlambat & Pulang di jam kerja', data: processedData.late_early_leave }
  ]

  return (
    <Card className='shadow-lg rounded-3xl h-full border-none'>
        <CardContent className='p-6'>
            <Box className='flex justify-between items-center mbe-8'>
                <Box>
                    <Typography variant='subtitle2' className='font-bold uppercase tracking-widest'>Tren Kehadiran 7 Hari</Typography>
                    <Typography variant='caption' color='text.secondary'>Kedisplinan karyawan satu minggu terakhir</Typography>
                </Box>
                <Box className='px-3 py-1 bg-primaryLight text-primary rounded-full text-[10px] font-bold'>
                    7 HARI TERAKHIR
                </Box>
            </Box>
            <Box className='min-h-[400px]'>
                {isMounted ? (
                    <AppReactApexCharts type='area' height={400} width='100%' options={trendOptions} series={trendSeries} />
                ) : (
                    <Box className='h-[400px] flex items-center justify-center'>
                        <i className='ri-loader-4-line animate-spin text-2xl text-primary' />
                    </Box>
                )}
            </Box>
        </CardContent>
    </Card>
  )
}

export default AttendanceTrendLine
