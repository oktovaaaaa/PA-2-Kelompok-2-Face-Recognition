'use client'

import React, { useState, useEffect } from 'react'

import dynamic from 'next/dynamic'

import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import { useTheme } from '@mui/material/styles'

import { attendanceService } from '@/libs/attendanceService'

const Chart = dynamic(() => import('react-apexcharts'), { ssr: false })

const getMonthName = (month: number) => {
  const months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ]

  
return months[month - 1] || `Bulan ${month}`
}

const statusColors = {
  present: '#22C55E',     // Green
  late: '#FBBF24',        // Yellow/Amber
  working: '#6366F1',     // Indigo
  leave_sick: '#0EA5E9',  // Light Blue
  not_yet: '#94A3B8',     // Slate/Grey
  absent: '#EF4444',      // Red
  early_leave: '#F97316', // Orange
  late_early_leave: '#D946EF' // Magenta
}

interface AttendanceChartsProps {
  period: string
  month: number
  year: number
}

const AttendanceCharts = ({ period, month, year }: AttendanceChartsProps) => {
  const theme = useTheme()
  const [stats, setStats] = useState<any>(null)
  const [trendData, setTrendData] = useState<any>({ labels: [], data: [] })

  // Define explicit theme colors to avoid ApexCharts processing errors
  const isDark = theme.palette.mode === 'dark'
  const textColorPrimary = isDark ? '#E2E8F0' : '#475569'
  const textColorSecondary = isDark ? '#94A3B8' : '#64748B'
  const textColorMuted = isDark ? '#64748B' : '#94A3B8'

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [summary, trend] = await Promise.all([
          attendanceService.getDetailedSummary({ filter: period, month, year }),
          attendanceService.getAttendanceTrend({ filter: period, month, year })
        ])

        setStats(summary)
        setTrendData(trend)
      } catch (error) {
        console.error('Error fetching charts data:', error)
      }
    }

    fetchData()
  }, [period, month, year])

  // Detailed rows for the "Ringkasan Kehadiran" sidebar
  const detailedStats = [
    { label: 'Hadir', count: stats?.present || 0, color: statusColors.present },
    { label: 'Terlambat', count: stats?.late || 0, color: statusColors.late },
    { label: 'Sedang Bekerja', count: stats?.working || 0, color: statusColors.working },
    { label: 'Izin/Sakit', count: stats?.leave_sick || 0, color: statusColors.leave_sick },
    { label: 'Belum Hadir', count: stats?.not_yet || 0, color: statusColors.not_yet },
    { label: 'Alpha', count: stats?.absent || 0, color: statusColors.absent },
    { label: 'Pulang di jam kerja', count: stats?.early_leave || 0, color: statusColors.early_leave },
    { label: 'Terlambat & Pulang di jam kerja', count: stats?.late_early_leave || 0, color: statusColors.late_early_leave },
  ]

  const donutOptions = {
    labels: [
      'Hadir', 
      'Terlambat', 
      'Sedang Bekerja', 
      'Izin/Sakit', 
      'Belum Hadir', 
      'Alpha', 
      'Pulang di jam kerja',
      'Terlambat & Pulang di jam kerja'
    ],
    colors: [
        statusColors.present,
        statusColors.late,
        statusColors.working,
        statusColors.leave_sick,
        statusColors.not_yet,
        statusColors.absent,
        statusColors.early_leave,
        statusColors.late_early_leave
    ],
    legend: { 
      position: 'bottom',
      fontSize: '13px',
      markers: { radius: 2 },
      labels: { colors: textColorPrimary }
    },
    stroke: { show: false },
    dataLabels: { enabled: false },
    plotOptions: { 
      pie: { 
        donut: { 
          size: '75%',
          labels: {
            show: true,
            name: {
              show: true,
              fontSize: '14px',
              color: textColorSecondary,
              offsetY: -10
            },
            value: {
              show: true,
              fontSize: '22px',
              fontWeight: 600,
              color: textColorPrimary,
              offsetY: 4,
              formatter: (val: string) => val
            },
            total: {
                show: true,
                label: 'Karyawan',
                fontSize: '14px',
                color: textColorSecondary,
                formatter: () => stats?.total || 0
            }
          }
        } 
      } 
    }
  }

  const donutSeries = [
    stats?.present || 0,
    stats?.late || 0,
    stats?.working || 0,
    stats?.leave_sick || 0,
    stats?.not_yet || 0,
    stats?.absent || 0,
    stats?.early_leave || 0,
    stats?.late_early_leave || 0
  ]

  // Preprocess data: if all categories for a day are 0, set them to null to create a gap in the chart
  const processedTrendData = {
    present: trendData.present?.map((v: number, i: number) => {
      const isHoliday = (
        (trendData.present?.[i] ?? 0) === 0 && 
        (trendData.late?.[i] ?? 0) === 0 && 
        (trendData.absent?.[i] ?? 0) === 0 && 
        (trendData.leave_sick?.[i] ?? 0) === 0 && 
        (trendData.early_leave?.[i] ?? 0) === 0 && 
        (trendData.late_early_leave?.[i] ?? 0) === 0
      );

      
return isHoliday ? null : v;
    }) || [],
    late: trendData.late?.map((v: number, i: number) => {
      const isHoliday = (
        (trendData.present?.[i] ?? 0) === 0 && 
        (trendData.late?.[i] ?? 0) === 0 && 
        (trendData.absent?.[i] ?? 0) === 0 && 
        (trendData.leave_sick?.[i] ?? 0) === 0 && 
        (trendData.early_leave?.[i] ?? 0) === 0 && 
        (trendData.late_early_leave?.[i] ?? 0) === 0
      );

      
return isHoliday ? null : v;
    }) || [],
    absent: trendData.absent?.map((v: number, i: number) => {
      const isHoliday = (
        (trendData.present?.[i] ?? 0) === 0 && 
        (trendData.late?.[i] ?? 0) === 0 && 
        (trendData.absent?.[i] ?? 0) === 0 && 
        (trendData.leave_sick?.[i] ?? 0) === 0 && 
        (trendData.early_leave?.[i] ?? 0) === 0 && 
        (trendData.late_early_leave?.[i] ?? 0) === 0
      );

      
return isHoliday ? null : v;
    }) || [],
    leave_sick: trendData.leave_sick?.map((v: number, i: number) => {
      const isHoliday = (
        (trendData.present?.[i] ?? 0) === 0 && 
        (trendData.late?.[i] ?? 0) === 0 && 
        (trendData.absent?.[i] ?? 0) === 0 && 
        (trendData.leave_sick?.[i] ?? 0) === 0 && 
        (trendData.early_leave?.[i] ?? 0) === 0 && 
        (trendData.late_early_leave?.[i] ?? 0) === 0
      );

      
return isHoliday ? null : v;
    }) || [],
    early_leave: trendData.early_leave?.map((v: number, i: number) => {
      const isHoliday = (
        (trendData.present?.[i] ?? 0) === 0 && 
        (trendData.late?.[i] ?? 0) === 0 && 
        (trendData.absent?.[i] ?? 0) === 0 && 
        (trendData.leave_sick?.[i] ?? 0) === 0 && 
        (trendData.early_leave?.[i] ?? 0) === 0 && 
        (trendData.late_early_leave?.[i] ?? 0) === 0
      );

      
return isHoliday ? null : v;
    }) || [],
    late_early_leave: trendData.late_early_leave?.map((v: number, i: number) => {
      const isHoliday = (
        (trendData.present?.[i] ?? 0) === 0 && 
        (trendData.late?.[i] ?? 0) === 0 && 
        (trendData.absent?.[i] ?? 0) === 0 && 
        (trendData.leave_sick?.[i] ?? 0) === 0 && 
        (trendData.early_leave?.[i] ?? 0) === 0 && 
        (trendData.late_early_leave?.[i] ?? 0) === 0
      );

      
return isHoliday ? null : v;
    }) || []
  };

  const lineSeries = [
    { name: 'Hadir', data: processedTrendData.present },
    { name: 'Terlambat', data: processedTrendData.late },
    { name: 'Alpha', data: processedTrendData.absent },
    { name: 'Izin/Sakit', data: processedTrendData.leave_sick },
    { name: 'Pulang di jam kerja', data: processedTrendData.early_leave },
    { name: 'Terlambat & Pulang di jam kerja', data: processedTrendData.late_early_leave }
  ]

  const lineOptions = {
    chart: { toolbar: { show: false } },
    stroke: { curve: 'smooth', width: 3 },
    colors: [
        statusColors.present,
        statusColors.late,
        statusColors.absent,
        statusColors.leave_sick,
        statusColors.early_leave,
        statusColors.late_early_leave
    ],
    fill: {
        type: 'gradient',
        gradient: { shadeIntensity: 1, opacityFrom: 0.5, opacityTo: 0.1, stops: [0, 90, 100] }
    },
    xaxis: { 
        categories: trendData.labels || [],
        axisBorder: { show: false },
        axisTicks: { show: false },
        labels: {
          style: { colors: textColorSecondary, fontSize: '12px' }
        }
    },
    yaxis: {
        min: 0,
        forceNiceScale: true,
        labels: { 
          style: { colors: textColorSecondary, fontSize: '12px' },
          formatter: (val: number) => Math.round(val) 
        }
    },
    tooltip: { 
      theme: isDark ? 'dark' : 'light',
      custom: function({ series, seriesIndex, dataPointIndex, w }: any) {

        const labels = w.globals.labels;
        const date = labels[dataPointIndex];
        
        // All categories are null, 'null', undefined, 0 or NaN means it's a holiday
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
            <div class="flex items-center gap-2.5">
              <span class="h-2.5 w-2.5 rounded-full shadow-sm" style="background-color: ${color}"></span>
              <span class="text-[11px] font-semibold ${isDark ? 'text-slate-300' : 'text-slate-700'}">${name}</span>
            </div>
            <span class="text-[11px] font-bold ${isDark ? 'text-white' : 'text-slate-900'}">${val} Karyawan</span>
          </div>`;
        });
        
        html += `</div>`;
        
return html;
      }
    },
    legend: { 
      position: 'top', 
      horizontalAlign: 'right',
      labels: { colors: textColorPrimary }
    }
  }

  const getTrendTitle = () => {
    if (period === 'today') return 'Tren Kedatangan Hari Ini (Per Jam)'
    if (period === 'week') return 'Tren Kehadiran (7 Hari Terakhir)'
    if (period === 'month') return `Tren Kehadiran Bulanan (${getMonthName(month)})`
    
return `Tren Kehadiran Tahunan (${year})`
  }

  return (
    <Grid container spacing={6}>
      {/* 1. Ringkasan Kehadiran List (Fixing the center gap) */}
      <Grid item xs={12} md={3}>
        <Card sx={{ height: '100%', minHeight: 400 }}>
             <CardContent>
                 <div className="flex justify-between items-center mb-4">
                     <Typography variant="h6" fontWeight="bold">Ringkasan Kehadiran</Typography>
                     <Typography variant="caption" color="text.secondary">
                        {period === 'today' ? 'Hari Ini' : period === 'month' ? `${getMonthName(month)} ${year}` : `Tahun ${year}`}
                     </Typography>
                 </div>
                 <Typography variant="body2" color="text.secondary" sx={{ mb: 6 }}>
                    Status kehadiran karyawan {period === 'today' ? 'hari ini' : period === 'month' ? 'bulan ini' : 'tahun ini'}
                 </Typography>
                 
                 <div className="flex flex-col gap-5">
                    {detailedStats.map((item, idx) => (
                        <div key={idx} className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <span style={{ width: 12, height: 12, borderRadius: '2px', backgroundColor: item.color }}></span>
                                <Typography variant="body2" sx={{ color: textColorPrimary }}>{item.label}</Typography>
                            </div>
                            <Typography variant="body2" fontWeight="bold" sx={{ color: textColorPrimary }}>{item.count}</Typography>
                        </div>
                    ))}
                 </div>
             </CardContent>
         </Card>
      </Grid>

      {/* 2. Trends Chart */}
      <Grid item xs={12} md={6}>
        <Card sx={{ height: '100%' }}>
          <CardHeader title={getTrendTitle()} subheader='Data persentase kehadiran berdasarkan periode' />
          <CardContent>
            <Chart 
              type='area' 
              height={300} 
              series={lineSeries}
              options={lineOptions as any} 
            />
          </CardContent>
        </Card>
      </Grid>
      
      {/* 3. Distribution Chart */}
      <Grid item xs={12} md={3}>
        <Card sx={{ height: '100%' }}>
          <CardHeader 
            title='Status Kehadiran' 
            subheader={period === 'today' ? 'Proporsi real-time hari ini' : `Proporsi periode ${period === 'month' ? getMonthName(month) : 'tahun ' + year}`} 
          />
          <CardContent className="flex justify-center">
            <Chart type='donut' height={340} options={donutOptions as any} series={donutSeries} />
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  )
}

export default AttendanceCharts
