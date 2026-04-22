// src/views/dashboard/RoleDistributionChart.tsx
'use client'

import dynamic from 'next/dynamic'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import { useTheme } from '@mui/material/styles'
import type { ApexOptions } from 'apexcharts'
import { useState, useEffect } from 'react'

const AppReactApexCharts = dynamic(() => import('@/libs/styles/AppReactApexCharts'))

interface Props {
  distribution: { [key: string]: number }
}

const RoleDistributionChart = ({ distribution }: Props) => {
  const theme = useTheme()
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])

  // Filter and Map labels
  const filteredData = Object.entries(distribution)
    .filter(([role]) => !role.toUpperCase().includes('SUPER_ADMIN') && !role.toUpperCase().includes('SUPER ADMIN'))
    .reduce((acc, [role, count]) => {
        let label = role.replace('ROLE_', '').replace('_', ' ')
        if (label === 'ADMIN') label = 'Boss'
        if (label === 'EMPLOYEE') label = 'Karyawan'
        return { ...acc, [label]: count }
    }, {} as { [key: string]: number })

  const labels = Object.keys(filteredData)
  const series = Object.values(filteredData)

  const options: ApexOptions = {
    chart: {
      parentHeightOffset: 0,
      toolbar: { show: false }
    },
    labels: labels,
    stroke: { width: 0 },
    colors: ['#6366F1', '#10B981', '#3B82F6'], // Custom colors: Indigo for Boss, Emerald for Karyawan
    dataLabels: { enabled: false },
    legend: {
        show: true,
        position: 'bottom',
        horizontalAlign: 'center',
        fontSize: '13px',
        fontWeight: 600,
        labels: {
            colors: 'var(--mui-palette-text-secondary)'
        },
        markers: {
            offsetY: 1,
            offsetX: -4,
            width: 10,
            height: 10,
            radius: 4
        },
        itemMargin: {
            horizontal: 15,
            vertical: 10
        }
    },
    plotOptions: {
      pie: {
        donut: {
          size: '72%',
          labels: {
            show: true,
            name: {
              fontSize: '16px',
              fontWeight: 500,
              color: 'var(--mui-palette-text-secondary)',
              offsetY: -10
            },
            value: {
              fontSize: '32px',
              fontWeight: 900,
              color: 'var(--mui-palette-text-primary)',
              offsetY: 5,
              formatter: val => val
            },
            total: {
              show: true,
              label: 'Total Pengguna',
              fontSize: '14px',
              fontWeight: 500,
              color: 'var(--mui-palette-text-secondary)',
              formatter: () => series.reduce((a, b) => a + b, 0).toString()
            }
          }
        }
      }
    },
    tooltip: {
      theme: theme.palette.mode as 'light' | 'dark'
    }
  }

  return (
    <Card className='shadow-lg rounded-[2rem] h-full border-none bg-[var(--mui-palette-background-paper)]'>
        <CardContent className='p-8 h-full flex flex-col'>
            <Typography variant='subtitle2' className='font-black uppercase tracking-[0.2em] text-[var(--mui-palette-text-primary)] mbe-8'>Distribusi Jabatan Pengguna</Typography>
            <Box className='flex-grow flex justify-center items-center'>
                {isMounted ? (
                    <AppReactApexCharts type='donut' height={400} options={options} series={series} />
                ) : (
                    <Box className='h-[400px] flex items-center justify-center'>
                         <i className='ri-loader-4-line animate-spin text-3xl text-primary' />
                    </Box>
                )}
            </Box>
        </CardContent>
    </Card>
  )
}

export default RoleDistributionChart
