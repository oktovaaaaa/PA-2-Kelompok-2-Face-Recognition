"use client"
// src/views/karyawan/EmployeeDetailModal.tsx
import React, { useEffect, useState } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Avatar,
  Typography,
  Divider,
  Grid,
  Chip,
  IconButton,
  CircularProgress,
  ToggleButton,
  ToggleButtonGroup,
  useTheme,
  Stack,
  Card,
  CardContent,
  Tooltip,
  FormControl,
  InputLabel,
  Select,
  MenuItem
} from '@mui/material'
import dynamic from 'next/dynamic'
import { Employee, employeeService } from '../../libs/employeeService'
import { ApexOptions } from 'apexcharts'

const ReactApexChart = dynamic(() => import('react-apexcharts'), { ssr: false })

interface Props {
  open: boolean
  onClose: () => void
  employee: Employee | null
  onAction: (action: 'reset' | 'position' | 'status') => void
}

const statusColors = {
  PRESENT: '#4CAF50',        // Hadir (Green)
  LATE: '#FF9800',           // Terlambat (Orange)
  WORKING: '#3F51B5',        // Sedang Bekerja (Indigo/Blue)
  LEAVE_SICK: '#03A9F4',     // Izin/Sakit (Light Blue)
  NOT_YET: '#9E9E9E',        // Belum Hadir (Grey)
  ABSENT: '#F44336',         // Alpha (Red)
  EARLY_LEAVE: '#F97316',    // Pulang di jam kerja (Orange)
  LATE_EARLY_LEAVE: '#D946EF' // Terlambat & Pulang di jam kerja (Magenta)
}

const months = [
  { value: 'all', label: 'Semua Bulan' },
  { value: '1', label: 'Januari' },
  { value: '2', label: 'Februari' },
  { value: '3', label: 'Maret' },
  { value: '4', label: 'April' },
  { value: '5', label: 'Mei' },
  { value: '6', label: 'Juni' },
  { value: '7', label: 'Juli' },
  { value: '8', label: 'Agustus' },
  { value: '9', label: 'September' },
  { value: '10', label: 'Oktober' },
  { value: '11', label: 'November' },
  { value: '12', label: 'Desember' }
]

const EmployeeDetailModal = ({ open, onClose, employee, onAction }: Props) => {
  const theme = useTheme()
  const [chartType, setChartType] = useState<'donut' | 'line'>('donut')
  
  // Filter States
  const [filterType, setFilterType] = useState<string>('month')
  const [selectedMonth, setSelectedMonth] = useState<string>((new Date().getMonth() + 1).toString())
  const [selectedYear, setSelectedYear] = useState<string>(new Date().getFullYear().toString())
  const [availableYears, setAvailableYears] = useState<string[]>([])
  
  const [stats, setStats] = useState<any>(null)
  const [loading, setLoading] = useState(false)
  const [attendanceRecords, setAttendanceRecords] = useState<any[]>([])

  useEffect(() => {
    if (open && employee) {
      loadInitialData()
    }
  }, [open, employee])

  useEffect(() => {
    if (open && employee) {
      loadStats()
    }
  }, [filterType, selectedMonth, selectedYear])

  const loadInitialData = async () => {
    try {
      const yearsData = await employeeService.getAttendanceYears()
      setAvailableYears(yearsData)
      if (yearsData.length > 0 && !yearsData.includes(new Date().getFullYear().toString())) {
          setSelectedYear(yearsData[0])
      }
    } catch (error) {
      console.error('Error loading years:', error)
    }
  }

  const loadStats = async () => {
    if (!employee) return
    setLoading(true)
    try {
      const data = await employeeService.getEmployeeAttendance(employee.id, filterType, selectedMonth, selectedYear)
      const records = data || []
      setAttendanceRecords(records)
      
      const newStats = {
          present: 0,
          late: 0,
          absent: 0,
          leave: 0,
          sick: 0,
          early_leave: 0,
          working: 0,
          not_yet: 0,
          total: records.length
      }

      records.forEach((r: any) => {
          const s = r.status.toUpperCase()
          if (s === 'PRESENT') newStats.present++
          else if (s === 'LATE') newStats.late++
          else if (s === 'ABSENT') newStats.absent++
          else if (s === 'LEAVE') newStats.leave++
          else if (s === 'SICK') newStats.sick++
          else if (s === 'EARLY_LEAVE') newStats.early_leave++
          else if (s === 'LATE_EARLY_LEAVE') newStats.late_early_leave++
          else if (s === 'WORKING') newStats.working++
          else if (s === 'NOT_YET') newStats.not_yet++
      })

      setStats(newStats)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  if (!employee) return null

  const isActive = employee.status === 'ACTIVE'
  const isTodayFilter = filterType === 'today'

  // --- PREPARE CHART DATA ---

  // EXCLUDE Working & Not Yet if not today
  const donutLabels = ['Hadir', 'Terlambat', 'Izin/Sakit', 'Alpha', 'Pulang di jam kerja', 'Terlambat & Pulang di jam kerja']
  const donutColors = [statusColors.PRESENT, statusColors.LATE, statusColors.LEAVE_SICK, statusColors.ABSENT, statusColors.EARLY_LEAVE, statusColors.LATE_EARLY_LEAVE]
  const donutSeries = stats ? [
    stats.present || 0,
    stats.late || 0,
    (stats.leave || 0) + (stats.sick || 0),
    stats.absent || 0,
    stats.early_leave || 0,
    stats.late_early_leave || 0
  ] : []

  if (isTodayFilter && stats) {
    donutLabels.push('Sedang Bekerja', 'Belum Hadir')
    donutColors.push(statusColors.WORKING, statusColors.NOT_YET)
    donutSeries.push(stats.working || 0, stats.not_yet || 0)
  }

  const donutOptions: ApexOptions = {
    chart: { type: 'donut' },
    labels: donutLabels,
    colors: donutColors,
    dataLabels: { enabled: false },
    legend: { show: false },
    plotOptions: {
      pie: {
        donut: {
          size: '75%',
          labels: {
            show: true,
            total: {
              show: true,
              label: 'Total Record',
              fontSize: '12px',
              color: '#64748B',
              formatter: () => stats ? (stats.total || 0).toString() : '0'
            }
          }
        }
      }
    }
  }

  // --- LINE CHART WITH MULTI-COLOR MARKERS ---
  const lineData = attendanceRecords.slice(0, 15).reverse()
  
  const getStatusColor = (status: string) => {
      const s = status.toUpperCase();
      if (s === 'PRESENT') return statusColors.PRESENT;
      if (s === 'LATE') return statusColors.LATE;
      if (s === 'LEAVE' || s === 'SICK') return statusColors.LEAVE_SICK;
      if (s === 'EARLY_LEAVE') return statusColors.EARLY_LEAVE;
      if (s === 'LATE_EARLY_LEAVE') return statusColors.LATE_EARLY_LEAVE;
      if (s === 'WORKING') return statusColors.WORKING;
      if (s === 'NOT_YET') return statusColors.NOT_YET;
      return statusColors.ABSENT;
  }

  const discreteMarkers: any[] = lineData.map((r, index) => ({
      seriesIndex: 0,
      dataPointIndex: index,
      fillColor: getStatusColor(r.status),
      strokeColor: '#FFF',
      size: 6
  }))

  const lineSeries = [
      {
          name: 'Kehadiran',
          data: lineData.map(r => {
              const s = r.status.toUpperCase();
              if (s === 'PRESENT') return 100;
              if (s === 'LATE') return 80;
              if (s === 'LEAVE' || s === 'SICK') return 60;
              if (s === 'EARLY_LEAVE') return 40;
              if (s === 'LATE_EARLY_LEAVE') return 20;
              return 0; // ABSENT / WORKING / NOT_YET
          })
      }
  ]

  const lineOptions: ApexOptions = {
    chart: { type: 'line', toolbar: { show: false }, zoom: { enabled: false } },
    stroke: { curve: 'smooth', width: 3, colors: ['#CBD5E1'] }, 
    markers: { 
        size: 0, // Base size 0, will be overridden by discrete
        discrete: discreteMarkers,
        hover: { size: 8 } 
    },
    xaxis: {
        categories: lineData.map(r => r.date.substring(5)),
        labels: { style: { fontSize: '10px' } }
    },
    yaxis: {
        max: 100, min: 0,
        tickAmount: 4, // 5 levels: 0, 25, 50, 75, 100
        labels: {
            style: { fontWeight: '600' },
            formatter: (val) => {
                if (val >= 100) return 'Hadir';
                if (val >= 80) return 'Telat';
                if (val >= 60) return 'Izin';
                if (val >= 40) return 'Plg Kerja';
                if (val >= 20) return 'Telat&Plg';
                return 'Alpha';
            }
        }
    }
  }

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth='md'>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', bgcolor: '#F1F5F9' }}>
        <Typography variant='h6' fontWeight='700'>Detail Karyawan</Typography>
        <IconButton size='small' onClick={onClose} sx={{ bgcolor: 'white' }}><i className='ri-close-line' /></IconButton>
      </DialogTitle>
      <DialogContent sx={{ p: 6 }}>
        <Grid container spacing={6}>
          {/* Left Column */}
          <Grid item xs={12} md={5}>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 6, mt: 2 }}>
              <Avatar
                src={employee.photo_url ? `http://localhost:8080${employee.photo_url}` : undefined}
                sx={{ width: 80, height: 80, mr: 4, borderRadius: 2, border: '3px solid #F1F5F9' }}
              >
                {employee.name.charAt(0)}
              </Avatar>
              <Box>
                <Typography variant='h5' fontWeight='800'>{employee.name}</Typography>
                <Typography variant='body2' color='textSecondary' mb={1}>{employee.email}</Typography>
                <Chip label={employee.status} color={isActive ? 'success' : 'error'} size='small' variant='outlined' />
              </Box>
            </Box>

            <Stack spacing={4}>
              <InfoRow icon='ri-briefcase-line' label='Jabatan' value={employee.position_name || '-'} />
              <InfoRow icon='ri-phone-line' label='Telepon' value={employee.phone || '-'} />
              <InfoRow icon='ri-map-pin-line' label='Alamat' value={employee.address || '-'} />
              <InfoRow icon='ri-smartphone-line' label='Device ID' value={employee.device_id ? 'Linked' : 'Not Linked'} />
            </Stack>

            <Divider sx={{ my: 6 }} />
            
            <Typography variant='caption' fontWeight='800' sx={{ textTransform: 'uppercase', color: 'text.secondary', display: 'block', mb: 3 }}>
                Aksi Cepat
            </Typography>
            <Stack direction='row' spacing={3}>
                <ActionButton icon='ri-key-line' label='Reset Perangkat' color='warning' onClick={() => onAction('reset')} />
                <ActionButton icon='ri-edit-box-line' label='Set Jabatan' color='primary' onClick={() => onAction('position')} />
                <ActionButton icon='ri-user-unfollow-line' label='Pecat/Nonaktif' color='error' onClick={() => onAction('status')} />
            </Stack>
          </Grid>

          {/* Right Column: Analytics */}
          <Grid item xs={12} md={7}>
            <Card variant='outlined' sx={{ borderRadius: 3, border: '1px solid #E2E8F0' }}>
              <CardContent sx={{ p: 5 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 5 }}>
                  <Typography variant='subtitle1' fontWeight='800'>Statistik Kehadiran</Typography>
                  <ToggleButtonGroup value={chartType} exclusive onChange={(_, v) => v && setChartType(v)} size='small'>
                    <ToggleButton value='donut'><i className='ri-pie-chart-2-line' /></ToggleButton>
                    <ToggleButton value='line'><i className='ri-line-chart-line' /></ToggleButton>
                  </ToggleButtonGroup>
                </Box>

                <Grid container spacing={3} sx={{ mb: 6 }}>
                    <Grid item xs={6} sm={4}>
                        <FormControl fullWidth size='small'>
                            <InputLabel>Periode</InputLabel>
                            <Select value={filterType} label="Periode" onChange={(e) => setFilterType(e.target.value)}>
                                <MenuItem value="today">Hari Ini</MenuItem>
                                <MenuItem value="week">Minggu Ini</MenuItem>
                                <MenuItem value="month">Per Bulan</MenuItem>
                                <MenuItem value="year">Per Tahun</MenuItem>
                            </Select>
                        </FormControl>
                    </Grid>
                    {(filterType === 'month' || filterType === 'year') && (
                        <Grid item xs={6} sm={4}>
                            <FormControl fullWidth size='small'>
                                <InputLabel>Bulan</InputLabel>
                                <Select value={selectedMonth} label="Bulan" onChange={(e) => setSelectedMonth(e.target.value)}>
                                    {months.map(m => (<MenuItem key={m.value} value={m.value}>{m.label}</MenuItem>))}
                                </Select>
                            </FormControl>
                        </Grid>
                    )}
                    <Grid item xs={12} sm={4}>
                        <FormControl fullWidth size='small'>
                            <InputLabel>Tahun</InputLabel>
                            <Select value={selectedYear} label="Tahun" onChange={(e) => setSelectedYear(e.target.value)}>
                                {availableYears.map(y => (<MenuItem key={y} value={y}>{y}</MenuItem>))}
                            </Select>
                        </FormControl>
                    </Grid>
                </Grid>

                {loading ? (
                    <Box sx={{ height: 280, display: 'flex', justifyContent: 'center', alignItems: 'center' }}><CircularProgress size={30} /></Box>
                ) : (
                    <Box sx={{ height: 280 }}>
                        <ReactApexChart options={chartType === 'donut' ? donutOptions : lineOptions} series={chartType === 'donut' ? donutSeries : lineSeries} type={chartType} height='100%' />
                    </Box>
                )}

                <Box sx={{ mt: 6 }}>
                    <Typography variant='caption' fontWeight='800' sx={{ color: 'text.secondary', display: 'block', mb: 3 }}>
                        KETERANGAN STATUS
                    </Typography>
                    <Grid container spacing={2}>
                        <StatLegend color={statusColors.PRESENT} label='Hadir' count={stats?.present} />
                        <StatLegend color={statusColors.LATE} label='Terlambat' count={stats?.late} />
                        <StatLegend color={statusColors.LEAVE_SICK} label='Izin/Sakit' count={(stats?.leave || 0) + (stats?.sick || 0)} />
                        <StatLegend color={statusColors.ABSENT} label='Alpha' count={stats?.absent} />
                        <StatLegend color={statusColors.EARLY_LEAVE} label='Pulang di jam kerja' count={stats?.early_leave} />
                        <StatLegend color={statusColors.LATE_EARLY_LEAVE} label='Terlambat & Pulang di jam kerja' count={stats?.late_early_leave} />
                        
                        {/* CONDITIONAL LEGEND */}
                        {isTodayFilter && (
                            <>
                                <StatLegend color={statusColors.NOT_YET} label='Belum Hadir' count={stats?.not_yet} />
                                <StatLegend color={statusColors.WORKING} label='Sedang Bekerja' count={stats?.working} />
                            </>
                        )}
                    </Grid>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </DialogContent>
      <DialogActions sx={{ p: 4, bgcolor: '#F8FAFC' }}>
        <Button onClick={onClose} variant='outlined' color='secondary' sx={{ px: 6, fontWeight: '700' }}>Tutup</Button>
      </DialogActions>
    </Dialog>
  )
}

const InfoRow = ({ icon, label, value }: { icon: string, label: string, value: string }) => (
    <Box sx={{ display: 'flex', alignItems: 'center' }}>
        <Box sx={{ mr: 4, display: 'flex', p: 2, borderRadius: 2, bgcolor: '#F1F5F9' }}><i className={icon} style={{ fontSize: '20px', color: '#475569' }} /></Box>
        <Box><Typography variant='caption' sx={{ display: 'block', color: 'text.secondary' }}>{label}</Typography><Typography variant='body2' fontWeight='700'>{value}</Typography></Box>
    </Box>
)

const StatLegend = ({ color, label, count }: { color: string, label: string, count?: number }) => (
    <Grid item xs={6}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', p: 2, borderRadius: 1.5, border: '1px solid #F1F5F9', bgcolor: 'white' }}>
            <Stack direction='row' spacing={2} alignItems='center'>
                <Box sx={{ width: 10, height: 10, borderRadius: '3px', bgcolor: color }} />
                <Typography variant='body2' fontSize='11px' fontWeight='600'>{label}</Typography>
            </Stack>
            <Typography variant='body2' fontWeight='800'>{count || 0}</Typography>
        </Box>
    </Grid>
)

const ActionButton = ({ icon, label, color, onClick }: { icon: string, label: string, color: any, onClick: () => void }) => (
    <Tooltip title={label}>
        <Button variant='outlined' color={color} onClick={onClick} sx={{ minWidth: 48, height: 48, borderRadius: 2, border: '2px solid' }}><i className={icon} style={{ fontSize: '22px' }} /></Button>
    </Tooltip>
)

export default EmployeeDetailModal
