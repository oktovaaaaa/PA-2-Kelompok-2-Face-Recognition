// src/views/payroll/PayrollList.tsx
'use client'

import React, { useEffect, useState, useCallback } from 'react'
import {
  Card,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Typography,
  Button,
  CardHeader,
  IconButton,
  TextField,
  InputAdornment,
  Box,
  Avatar,
  Grid,
  MenuItem,
  CircularProgress,
  TablePagination
} from '@mui/material'
import { payrollService, Salary } from '@/libs/payrollService'
import { employeeService, Position } from '@/libs/employeeService'
import SalaryDetailModal from './SalaryDetailModal'
import { useNotification } from '@/contexts/NotificationContext'

const PayrollList = () => {
  const { showNotification } = useNotification()
  
  // Data States
  const [salaries, setSalaries] = useState<Salary[]>([])
  const [positions, setPositions] = useState<Position[]>([])
  const [years, setYears] = useState<string[]>([new Date().getFullYear().toString()])
  const [loading, setLoading] = useState(true)

  // Filter States
  const [month, setMonth] = useState<number>(new Date().getMonth() + 1)
  const [year, setYear] = useState<number>(new Date().getFullYear())
  const [positionId, setPositionId] = useState<string>('all')
  const [search, setSearch] = useState('')

  // Modal States
  const [selectedSalary, setSelectedSalary] = useState<Salary | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)

  // Pagination
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)

  const loadInitialData = useCallback(async () => {
    try {
      const [posData, yearData] = await Promise.all([
        employeeService.getPositions(),
        payrollService.getPayrollYears()
      ])
      setPositions(posData || [])
      if (yearData && yearData.length > 0) setYears(yearData)
    } catch (error) {
      console.error(error)
    }
  }, [])

  const loadSalaries = useCallback(async () => {
    setLoading(true)
    try {
      const data = await payrollService.getAdminSalaries({
        month,
        year,
        position_id: positionId === 'all' ? undefined : positionId,
        search: search || undefined
      })
      setSalaries(data || [])
      setPage(0)
    } catch (error) {
       showNotification('Gagal mengambil data gaji.', 'error')
    } finally {
      setLoading(false)
    }
  }, [month, year, positionId, search, showNotification])

  useEffect(() => {
    loadInitialData()
  }, [loadInitialData])

  useEffect(() => {
    loadSalaries()
  }, [loadSalaries])

  const formatIDR = (amount: number) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(amount)
  }

  const getStatusChip = (status: string) => {
    switch (status) {
      case 'PAID': return <Chip label="Lunas" color="success" size="small" variant="outlined" />
      case 'PARTIAL': return <Chip label="Dicicil" color="info" size="small" variant="outlined" />
      default: return <Chip label="Pending" color="warning" size="small" variant="outlined" />
    }
  }

  const paginatedData = salaries.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {/* Page Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant='h4' fontWeight='800' color='primary' gutterBottom>
            Laporan Payroll
          </Typography>
          <Typography variant='body2' color='text.secondary'>
            Kelola pembayaran gaji tepat waktu, pantau rincian potongan, dan status pelunasan karyawan.
          </Typography>
        </Box>
      </Box>

      {/* 1. Filters Card */}
      <Card sx={{ border: '1px solid', borderColor: 'divider' }}>
        <Box sx={{ px: 5, pb: 5, pt: 5 }}>
          <Grid container spacing={4} alignItems="center">
            <Grid item xs={12} sm={2.4}>
              <TextField
                select fullWidth size="small" label="Bulan"
                value={month} onChange={(e) => setMonth(Number(e.target.value))}
              >
                {['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'].map((m, i) => (
                  <MenuItem key={i+1} value={i+1}>{m}</MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid item xs={12} sm={2.4}>
                <TextField
                  select fullWidth size="small" label="Tahun"
                  value={year} onChange={(e) => setYear(Number(e.target.value))}
                >
                  {years.map(y => <MenuItem key={y} value={Number(y)}>{y}</MenuItem>)}
                </TextField>
            </Grid>
            <Grid item xs={12} sm={2.4}>
                <TextField
                  select fullWidth size="small" label="Jabatan"
                  value={positionId} onChange={(e) => setPositionId(e.target.value)}
                >
                  <MenuItem value="all">Semua Jabatan</MenuItem>
                  {positions.map(p => <MenuItem key={p.id} value={p.id}>{p.name}</MenuItem>)}
                </TextField>
            </Grid>
            <Grid item xs={12} sm={4.8}>
                <TextField
                  fullWidth size="small" placeholder="Cari nama karyawan..."
                  value={search} onChange={(e) => setSearch(e.target.value)}
                  InputProps={{
                    startAdornment: <InputAdornment position="start"><i className="ri-search-line" /></InputAdornment>
                  }}
                />
            </Grid>
          </Grid>
        </Box>
      </Card>

      {/* 2. Salary Table */}
      <Card>
        <TableContainer component={Paper} elevation={0}>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 10 }}><CircularProgress /></Box>
          ) : (
            <Table sx={{ minWidth: 900 }}>
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: '700' }}>Karyawan</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Gaji Pokok</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Bonus</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Potongan</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Total Net</TableCell>
                  <TableCell align="center" sx={{ fontWeight: '700' }}>Status</TableCell>
                  <TableCell align="right" sx={{ fontWeight: '700' }}>Aksi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginatedData.length === 0 ? (
                  <TableRow><TableCell colSpan={7} align="center" sx={{ py: 10 }}>Tidak ada data payroll untuk periode ini.</TableCell></TableRow>
                ) : paginatedData.map((row) => {
                  const balance = row.total_salary - row.paid_amount
                  return (
                    <TableRow key={row.id} hover>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <Avatar 
                            src={row.user?.photo_url ? `http://localhost:8080${row.user.photo_url}` : undefined}
                            sx={{ mr: 3, width: 34, height: 34, bgcolor: 'primary.light' }}
                          >
                            {row.user?.name?.charAt(0)}
                          </Avatar>
                          <Box>
                            <Typography variant="body2" fontWeight="700" color="text.primary">{row.user?.name}</Typography>
                            <Typography variant="caption" color="text.secondary">{row.user?.position?.name || 'Staf'}</Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell><Typography variant="body2">{formatIDR(row.base_salary)}</Typography></TableCell>
                      <TableCell><Typography variant="body2" color="success.main" fontWeight="600">+{formatIDR(row.bonuses)}</Typography></TableCell>
                      <TableCell><Typography variant="body2" color="error.main">-{formatIDR(row.deductions)}</Typography></TableCell>
                      <TableCell>
                        <Typography variant="body2" fontWeight="800" color="primary.main">
                          {formatIDR(row.total_salary)}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">{getStatusChip(row.status)}</TableCell>
                      <TableCell align="right">
                        <Button 
                          size="small" variant="contained" color={row.status === 'PAID' ? 'secondary' : 'primary'}
                          onClick={() => { setSelectedSalary(row); setIsDetailOpen(true); }}
                          startIcon={<i className={row.status === 'PAID' ? 'ri-eye-line' : 'ri-bank-card-line'} />}
                        >
                          {row.status === 'PAID' ? 'Lihat Detail' : 'Proses Bayar'}
                        </Button>
                      </TableCell>
                    </TableRow>
                  )
                })}
              </TableBody>
            </Table>
          )}
        </TableContainer>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component='div'
          count={salaries.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
          labelRowsPerPage="Baris per halaman:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} dari ${count !== -1 ? count : `lebih dari ${to}`}`}
        />
      </Card>

      {/* 3. Detail & Payment Modal */}
      {selectedSalary && (
        <SalaryDetailModal 
          open={isDetailOpen}
          onClose={() => setIsDetailOpen(false)}
          salary={selectedSalary}
          onSuccess={() => { loadSalaries(); }}
        />
      )}
    </Box>
  )
}

export default PayrollList
