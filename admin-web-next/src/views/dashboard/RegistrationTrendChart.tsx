// src/views/dashboard/RegistrationTrendChart.tsx
'use client'

import { useState, useEffect } from 'react'

import dynamic from 'next/dynamic'

import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import MenuItem from '@mui/material/MenuItem'
import TextField from '@mui/material/TextField'
import ToggleButton from '@mui/material/ToggleButton'
import ToggleButtonGroup from '@mui/material/ToggleButtonGroup'
import type { ApexOptions } from 'apexcharts'
import { useTheme } from '@mui/material/styles'

const AppReactApexCharts = dynamic(() => import('@/libs/styles/AppReactApexCharts'))

interface Props {
  data: number[] // 12 numbers
  year: number
  years: number[]
  onYearChange: (year: number) => void
}

const RegistrationTrendChart = ({ data, year, years, onYearChange }: Props) => {
  const theme = useTheme()
  const [isMounted, setIsMounted] = useState(false)
  const [chartType, setChartType] = useState<'bar' | 'area'>('bar')

  useEffect(() => {
    setIsMounted(true)
  }, [])

  const monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des']
  
  // Dynamic colors based on trend (Up = Green, Down = Red, Same = Blue)
  const barColors = data.map((val, index) => {
    if (index === 0) return '#10B981' // January default green
    const prevVal = data[index - 1]

    if (val > prevVal) return '#10B981' // Success/Growth Green
    if (val < prevVal) return '#EF4444' // Decline Red
    
return '#3B82F6' // Neutral/Same Blue
  })

  const options: ApexOptions = {
    chart: {
      toolbar: { show: false },
      parentHeightOffset: 0,
      animations: {
        enabled: true,
        easing: 'easeinout',
        speed: 800,
        animateGradually: {
            enabled: true,
            delay: 150
        },
        dynamicAnimation: {
            enabled: true,
            speed: 350
        }
      }
    },
    xaxis: {
      categories: monthLabels,
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
    colors: chartType === 'bar' ? barColors : ['#6366F1'],
    plotOptions: {
      bar: {
        borderRadius: 6,
        columnWidth: '35%',
        distributed: chartType === 'bar',
      }
    },
    fill: {
        type: chartType === 'area' ? 'gradient' : 'solid',
        gradient: {
            shadeIntensity: 1,
            opacityFrom: 0.5,
            opacityTo: 0.1,
            stops: [0, 90, 100]
        }
    },
    stroke: {
        curve: 'smooth',
        width: chartType === 'area' ? 3 : 0
    },
    dataLabels: { enabled: false },
    legend: { show: false },
    grid: {
      borderColor: 'var(--mui-palette-divider)',
      padding: { bottom: 12, left: -10, right: -10 }
    },
    tooltip: {
      theme: theme.palette.mode as 'light' | 'dark',
    }
  }

  const series = [{ name: 'Pendaftaran Pengguna', data }]

  return (
    <Card className='shadow-lg rounded-3xl h-full border-none bg-[var(--mui-palette-background-paper)]'>
        <CardContent className='p-6'>
            <Box className='flex flex-col sm:flex-row justify-between items-start sm:items-center gap-6 mbe-8'>
                <Box>
                    <Typography variant='subtitle2' className='font-black uppercase tracking-widest text-[var(--mui-palette-text-primary)]'>Tren Pertumbuhan Pengguna</Typography>
                    <Typography variant='caption' className='text-[var(--mui-palette-text-secondary)]'>Statistik jumlah pendaftaran per bulan</Typography>
                </Box>
                
                <Box className='flex items-center gap-4 w-full sm:w-auto overflow-x-auto pb-2 sm:pb-0'>
                    <ToggleButtonGroup
                        size="small"
                        value={chartType}
                        exclusive
                        onChange={(e, next) => next && setChartType(next)}
                        aria-label="Tipe Chart"
                        className='bg-[var(--mui-palette-action-hover)] rounded-xl border-none p-1'
                    >
                        <ToggleButton value="bar" className='border-none rounded-lg px-4 gap-2'>
                            <i className='ri-bar-chart-fill text-lg' />
                            <Typography variant='caption' className='font-bold hidden md:block'>Batang</Typography>
                        </ToggleButton>
                        <ToggleButton value="area" className='border-none rounded-lg px-4 gap-2'>
                            <i className='ri-area-chart-fill text-lg' />
                            <Typography variant='caption' className='font-bold hidden md:block'>Area</Typography>
                        </ToggleButton>
                    </ToggleButtonGroup>

                    <TextField
                        select
                        size='small'
                        value={year}
                        onChange={(e) => onYearChange(parseInt(e.target.value))}
                        sx={{ 
                            width: 100,
                            '& .MuiOutlinedInput-root': {
                                borderRadius: '12px',
                                backgroundColor: 'var(--mui-palette-action-hover)',
                                '& fieldset': { border: 'none' }
                            }
                        }}
                    >
                        {years.map((y) => (
                            <MenuItem key={y} value={y}>{y}</MenuItem>
                        ))}
                    </TextField>
                </Box>
            </Box>
            
            <Box className='min-h-[400px]'>
                {isMounted ? (
                    <AppReactApexCharts 
                        type={chartType} 
                        height={400} 
                        width='100%' 
                        options={options} 
                        series={series} 
                    />
                ) : (
                    <Box className='h-[400px] flex items-center justify-center text-center flex-col gap-3'>
                        <i className='ri-loader-4-line animate-spin text-3xl text-primary' />
                        <Typography variant='caption' className='font-bold uppercase tracking-widest text-slate-400'>Menyiapkan Visualisasi...</Typography>
                    </Box>
                )}
            </Box>
        </CardContent>
    </Card>
  )
}

export default RegistrationTrendChart
