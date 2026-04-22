'use client'

import React, { useState } from 'react'
import Grid from '@mui/material/Grid'
import Typography from '@mui/material/Typography'
import AttendanceStats from '@views/absensi/AttendanceStats'
import AttendanceCharts from '@views/absensi/AttendanceCharts'
import AttendanceTable from '@views/absensi/AttendanceTable'
import AttendanceFilter from '@views/absensi/AttendanceFilter'
import RoleGuard from '@/hocs/RoleGuard'

export default function AbsensiPage() {
  // Global filter state
  const [periodType, setPeriodType] = useState('today')
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1)
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear())

  return (
    <RoleGuard allowedRoles={['ADMIN', 'OWNER']}>
      <Grid container spacing={6}>
        <Grid item xs={12} className="flex justify-between items-center">
          <Typography variant="h4" fontWeight="600" color="primary">Laporan & Analitik Absensi</Typography>
        </Grid>

        {/* 0. Global Filters (Filling the top space) */}
        <Grid item xs={12}>
          <AttendanceFilter 
              periodType={periodType} setPeriodType={setPeriodType}
              selectedMonth={selectedMonth} setSelectedMonth={setSelectedMonth}
              selectedYear={selectedYear} setSelectedYear={setSelectedYear}
          />
        </Grid>

        {/* 1. Statistics Cards */}
        <Grid item xs={12}>
          <AttendanceStats period={periodType} month={selectedMonth} year={selectedYear} />
        </Grid>

        {/* 2. Visual Analytics (Charts) */}
        <Grid item xs={12}>
          <AttendanceCharts period={periodType} month={selectedMonth} year={selectedYear} />
        </Grid>

        {/* 3. Detailed Management Table */}
        <Grid item xs={12}>
          <AttendanceTable parentPeriod={periodType} parentMonth={selectedMonth} parentYear={selectedYear} />
        </Grid>
      </Grid>
    </RoleGuard>
  )
}
