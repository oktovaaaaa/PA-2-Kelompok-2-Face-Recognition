'use client'

import React, { useState, useEffect } from 'react'

import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Grid from '@mui/material/Grid'
import Stack from '@mui/material/Stack'
import Chip from '@mui/material/Chip'
import Typography from '@mui/material/Typography'
import FormControl from '@mui/material/FormControl'
import InputLabel from '@mui/material/InputLabel'
import Select from '@mui/material/Select'
import MenuItem from '@mui/material/MenuItem'
import Box from '@mui/material/Box'

import { attendanceService } from '@/libs/attendanceService'

interface AttendanceFilterProps {
  periodType: string
  setPeriodType: (val: string) => void
  selectedMonth: number
  setSelectedMonth: (val: number) => void
  selectedYear: number
  setSelectedYear: (val: number) => void
}

const AttendanceFilter = ({
  periodType,
  setPeriodType,
  selectedMonth,
  setSelectedMonth,
  selectedYear,
  setSelectedYear
}: AttendanceFilterProps) => {
  const [availableYears, setAvailableYears] = useState<string[]>([])

  const months = [
    { value: 1, label: 'Januari' }, { value: 2, label: 'Februari' }, { value: 3, label: 'Maret' },
    { value: 4, label: 'April' }, { value: 5, label: 'Mei' }, { value: 6, label: 'Juni' },
    { value: 7, label: 'Juli' }, { value: 8, label: 'Agustus' }, { value: 9, label: 'September' },
    { value: 10, label: 'Oktober' }, { value: 11, label: 'November' }, { value: 12, label: 'Desember' }
  ]

  useEffect(() => {
    const fetchYears = async () => {
      try {
        const years = await attendanceService.getAttendanceYears()

        setAvailableYears(years)


        // If current year is not in available years, pick the latest one if exists
        if (years.length > 0 && !years.map(String).includes(String(selectedYear))) {
          setSelectedYear(Number(years[0]))
        }
      } catch (error) {
        console.error('Error fetching available years:', error)
      }
    }

    fetchYears()
  }, [])

  return (
    <Card sx={{ mb: 6, border: '1px solid', borderColor: 'divider' }}>
      <CardContent>
        <Grid container spacing={6} alignItems="center">
          <Grid item xs={12} lg={5}>
            <Typography variant="subtitle2" sx={{ mb: 2, fontWeight: 600 }}>Tampilkan Laporan Berdasarkan:</Typography>
            <Stack direction="row" spacing={2}>
              {[
                { id: 'today', label: 'Hari Ini' },
                { id: 'week', label: 'Minggu Ini' },
                { id: 'month', label: 'Bulanan' },
                { id: 'year', label: 'Tahunan' }
              ].map((p) => (
                <Chip 
                  key={p.id}
                  label={p.label}
                  color={periodType === p.id ? 'primary' : 'default'}
                  onClick={() => setPeriodType(p.id)}
                  variant={periodType === p.id ? 'filled' : 'outlined'}
                  sx={{ 
                    cursor: 'pointer',
                    px: 3,
                    height: 36,
                    fontWeight: periodType === p.id ? 600 : 400,
                    transition: 'all 0.2s',
                    '&:hover': { transform: 'translateY(-1px)', boxShadow: (theme) => theme.shadows[2] }
                  }}
                />
              ))}
            </Stack>
          </Grid>

          {periodType !== 'today' && periodType !== 'week' && (
            <Grid item xs={12} sm={6} lg={3}>
              <FormControl fullWidth size="small">
                <InputLabel>Pilih Tahun</InputLabel>
                <Select
                  value={selectedYear}
                  label="Pilih Tahun"
                  onChange={(e) => setSelectedYear(Number(e.target.value))}
                >
                  {availableYears.length > 0 ? (
                    availableYears.map(y => <MenuItem key={y} value={y}>{y}</MenuItem>)
                  ) : (
                    <MenuItem value={new Date().getFullYear()}>{new Date().getFullYear()}</MenuItem>
                  )}
                </Select>
              </FormControl>
            </Grid>
          )}

          {periodType === 'month' && (
            <Grid item xs={12} sm={6} lg={4}>
              <FormControl fullWidth size="small">
                <InputLabel>Pilih Bulan</InputLabel>
                <Select
                  value={selectedMonth}
                  label="Pilih Bulan"
                  onChange={(e) => setSelectedMonth(Number(e.target.value))}
                >
                  {months.map(m => <MenuItem key={m.value} value={m.value}>{m.label}</MenuItem>)}
                </Select>
              </FormControl>
            </Grid>
          )}
        </Grid>
      </CardContent>
    </Card>
  )
}

export default AttendanceFilter
