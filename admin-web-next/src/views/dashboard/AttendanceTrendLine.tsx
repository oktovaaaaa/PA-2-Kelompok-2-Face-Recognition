// src/views/dashboard/AttendanceTrendLine.tsx
'use client'

import { useState, useEffect } from 'react'

import dynamic from 'next/dynamic'

import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import type { ApexOptions } from 'apexcharts'

import { useTheme } from '@mui/material/styles'

import type { AttendanceTrend } from '@/libs/dashboardService'

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
      custom: function({ series, seriesIndex, dataPointIndex, w }: any) {

        const labels = w.globals.labels;
        const date = labels[dataPointIndex];
        const isDark = theme.palette.mode === 'dark';
        
        // All categories are null, 'null', undefined, or 0 means it's a holiday
        const isHoliday = series.every((s: any) => {
          const v = s[dataPointIndex];

          
return v === null || v === 'null' || v === 0 || v === undefined || isNaN(Number(v));
        });
        
        if (isHoliday) {
          return `
          <div class="p-4 shadow-2xl rounded-2xl ${isDark ? 'bg-[#0F172A] text-white' : 'bg-white text-slate-800'} border border-slate-100 dark:border-slate-800">
            <div class="font-bold text-[10px] mb-2 text-slate-500 dark:text-slate-400 uppercase tracking-wider">${date}</div>
            <div style="
              display: flex; 
              align-items: center; 
              gap: 8px; 
              color: ${isDark ? '#FDBA74' : '#EA580C'} !important; 
              font-weight: 800; 
              font-size: 11px; 
              background-color: ${isDark ? 'rgba(234, 88, 12, 0.1)' : 'rgba(251, 191, 36, 0.1)'} !important; 
              border: 1.5px solid ${isDark ? '#EA580C' : '#F59E0B'}; 
              padding: 6px 14px; 
              border-radius: 9999px;
              box-shadow: 0 0 12px ${isDark ? 'rgba(234, 88, 12, 0.4)' : 'rgba(245, 158, 11, 0.2)'};
              backdrop-filter: blur(4px);
            ">
              <span style="display: block; height: 6px; width: 6px; border-radius: 50%; background-color: ${isDark ? '#EA580C' : '#F59E0B'}; box-shadow: 0 0 8px ${isDark ? '#EA580C' : '#F59E0B'};"></span>
              HARI LIBUR
            </div>
          </div>`;
        }
        
        let html = `<div class="p-4 shadow-2xl rounded-2xl ${isDark ? 'bg-[#0F172A] text-white' : 'bg-white text-slate-800'} border border-slate-100 dark:border-slate-800">
          <div class="font-bold text-[10px] border-b border-slate-100 dark:border-slate-800 pb-2 mb-3 text-slate-500 dark:text-slate-400 uppercase tracking-wider">${date}</div>`;
        
        series.forEach((s: any, idx: number) => {
          const v = s[dataPointIndex];
          const val = (v === null || v === 'null' || v === undefined || isNaN(Number(v))) ? 0 : Number(v);
          const name = w.globals.seriesNames[idx];
          const color = w.globals.colors[idx];

          html += `<div class="flex items-center justify-between gap-8 py-1.5">
            <div class="flex items-center gap-3">
              <span class="h-2.5 w-2.5 rounded-full shadow-sm" style="background-color: ${color}"></span>
              <span class="text-[11px] font-semibold ${isDark ? 'text-slate-300' : 'text-slate-700'}">${name}</span>
            </div>
            <span class="text-[11px] font-bold ${isDark ? 'text-white' : 'text-slate-900'}">${val} Karyawan</span>
          </div>`;
        });
        
        html += `</div>`;
        
return html;
      }
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
