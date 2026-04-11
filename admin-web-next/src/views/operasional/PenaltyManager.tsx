// src/views/operasional/PenaltyManager.tsx
'use client'

import { useState, useEffect, useCallback } from 'react'
import { 
  Card, CardHeader, CardContent, Grid, TextField, 
  Button, Typography, Box, CircularProgress, IconButton,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination,
  Paper, Avatar, MenuItem, InputAdornment, Divider, Chip, Tabs, Tab, Autocomplete
} from '@mui/material'
import { settingService, ManualPenalty } from '@/libs/settingService'
import { employeeService, Employee } from '@/libs/employeeService'
import { attendanceService } from '@/libs/attendanceService'
import { format } from 'date-fns'
import { useNotification } from '@/contexts/NotificationContext'
import { formatFullDate } from '@/utils/dateFormatter'
import ConfirmDialog from '@/components/ConfirmDialog'

interface UnifiedViolation {
    id: string; // real ID for penalty, unique key for attendance
    type: 'MANUAL' | 'ABSENSI';
    user_id: string;
    user_name: string;
    user_email: string;
    photo_url?: string;
    title: string;
    amount: number;
    date: string;
    status: string; // Detail status for attendance (LATE, etc)
}

const PenaltyManager = () => {
  const { showNotification } = useNotification()
  const [unifiedViolations, setUnifiedViolations] = useState<UnifiedViolation[]>([])
  const [employees, setEmployees] = useState<Employee[]>([])
  const [loading, setLoading] = useState(true)
  const [saveLoading, setSaveLoading] = useState(false)
  
  // Form State
  const [formData, setFormData] = useState({ user_id: '', title: '', amount: 0, date: format(new Date(), 'yyyy-MM-dd') })
  
  // Pagination State
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [totalCount, setTotalCount] = useState(0)

  // Filter State
  const [month, setMonth] = useState<string>((new Date().getMonth() + 1).toString())
  const [year, setYear] = useState<string>(new Date().getFullYear().toString())
  const [availableYears, setAvailableYears] = useState<string[]>([])
  const [searchKeyword, setSearchKeyword] = useState<string>('')
  
  // Tab State
  const [tabValue, setTabValue] = useState(0) // 0: Semua, 1: Absensi, 2: Manual
  // Confirm Dialog State
  const [isConfirmOpen, setIsConfirmOpen] = useState(false)
  const [selectedViolation, setSelectedViolation] = useState<UnifiedViolation | null>(null)

  const loadData = useCallback(async (currPage: number = 0, limit: number = 10, fMonth: string, fYear: string, fSearch: string, fTab: number) => {
    try {
      const [pRes, aData, eData, yData] = await Promise.all([
        settingService.getManualPenalties(1, 1000, fMonth, fYear, fSearch), // Fetch more manual for merging
        attendanceService.getAttendanceHistory({ month: fMonth, year: fYear }),
        employeeService.getEmployees('ACTIVE'),
        settingService.getPenaltyYears()
      ])

      // 1. Process Manual Penalties
      const manualProps: UnifiedViolation[] = (pRes.data || []).map(p => ({
          id: p.id,
          type: 'MANUAL',
          user_id: p.user_id,
          user_name: p.user?.name || 'Karyawan',
          user_email: p.user?.email || '',
          title: p.title,
          amount: p.amount,
          date: p.date,
          status: 'MANUAL'
      }))

      // 2. Process Attendance Violations (LATE, ABSENT, EARLY_LEAVE)
      const attendanceProps: UnifiedViolation[] = (aData || [])
        .filter((a: any) => ['LATE', 'ABSENT', 'EARLY_LEAVE', 'LATE_EARLY_LEAVE'].includes(a.status))
        .map((a: any) => ({
            id: `att-${a.user_id}-${a.date}`, // Virtual unique ID
            type: 'ABSENSI',
            user_id: a.user_id,
            user_name: a.user_name || 'Karyawan',
            user_email: a.user_email || '',
            photo_url: a.photo_url,
            title: a.status === 'ABSENT' ? 'Alpha' : 
                   a.status === 'LATE' ? 'Terlambat' : 
                   a.status === 'EARLY_LEAVE' ? 'Pulang Awal' : 'Terlambat & Pulang Awal',
            amount: a.salary_deduction,
            date: a.date,
            status: a.status
        }))
        .filter((a: any) => a.amount > 0) // Only those with actual penalties

      // 3. Merge and Sort by Date (Descending)
      let combined = [...manualProps, ...attendanceProps]
      
      // 4. Apply Tab/Category Filter
      if (fTab === 1) {
          combined = combined.filter(v => v.type === 'ABSENSI')
      } else if (fTab === 2) {
          combined = combined.filter(v => v.type === 'MANUAL')
      }

      // 5. Client-side search keyword filtering
      combined = combined.filter(v => 
        v.user_name.toLowerCase().includes(fSearch.toLowerCase()) || 
        v.title.toLowerCase().includes(fSearch.toLowerCase())
      )

      combined.sort((a, b) => b.date.localeCompare(a.date))

      setTotalCount(combined.length)
      
      // 6. Simple offset-based pagination on filtered & merged data
      const startIndex = currPage * limit
      setUnifiedViolations(combined.slice(startIndex, startIndex + limit))
      setEmployees(eData || [])
      
      if (yData && yData.length > 0) {
        setAvailableYears(yData)
      } else {
        setAvailableYears([new Date().getFullYear().toString()])
      }
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData(page, rowsPerPage, month, year, searchKeyword, tabValue)
  }, [loadData, page, rowsPerPage, month, year, searchKeyword, tabValue])

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData.user_id || !formData.amount || !formData.title) {
        showNotification('Mohon lengkapi semua data.', 'error')
        return
    }
    setSaveLoading(true)
    try {
      await settingService.createManualPenalty(formData)
      showNotification('Denda manual berhasil dicatat!', 'success')
      setFormData({ user_id: '', title: '', amount: 0, date: format(new Date(), 'yyyy-MM-dd') })
      loadData(page, rowsPerPage, month, year, searchKeyword)
    } catch (error: any) {
      showNotification(error.message || 'Gagal menambahkan denda.', 'error')
    } finally {
      setSaveLoading(false)
    }
  }

  const handleDelete = async (violation: UnifiedViolation) => {
    setSelectedViolation(violation)
    setIsConfirmOpen(true)
  }

  const confirmDelete = async () => {
    if (!selectedViolation) return
    try {
      if (selectedViolation.type === 'MANUAL') {
        await settingService.deletePenalty(selectedViolation.id)
      } else {
        // Attendance pardon
        await attendanceService.pardonAttendance(selectedViolation.user_id, selectedViolation.date)
      }
      showNotification('Sanksi berhasil dihapus/diputihkan.', 'success')
      loadData(page, rowsPerPage, month, year, searchKeyword)
    } catch (error) {
      showNotification('Gagal menghapus data sanksi.', 'error')
    }
  }

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', p: 10 }}><CircularProgress /></Box>

  return (
    <Grid container spacing={6}>
      <Grid item xs={12}>
        <Divider sx={{ mb: 4 }} />
      </Grid>

      {/* 1. Form Input */}
      <Grid item xs={12} md={4}>
        <Card variant="outlined">
          <CardHeader 
            title="Catat Pelanggaran Manual" 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-edit-box-line' style={{ fontSize: '1.5rem', color: '#6366f1' }} />}
            subheader="Berikan sanksi denda di luar sistem absensi" 
          />
          <Divider />
          <CardContent sx={{ pt: 6 }}>
            <form onSubmit={handleAdd}>
              <Grid container spacing={5}>
                <Grid item xs={12}>
                  <Autocomplete
                    fullWidth
                    size="small"
                    options={employees}
                    getOptionLabel={(option) => option.name || ''}
                    value={employees.find(emp => emp.id === formData.user_id) || null}
                    onChange={(event, newValue) => {
                      setFormData({ ...formData, user_id: newValue ? newValue.id : '' });
                    }}
                    renderInput={(params) => (
                      <TextField 
                        {...params} 
                        label="Cari Karyawan" 
                        placeholder="Wajib diisi" 
                      />
                    )}
                    noOptionsText="Karyawan tidak ditemukan"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField 
                    fullWidth label="Judul / Jenis Pelanggaran" size="small"
                    placeholder="Wajib diisi (Misal: Kerusakan Alat)"
                    value={formData.title}
                    onChange={e => setFormData({...formData, title: e.target.value})}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField 
                    fullWidth label="Besar Sanksi" type="text" size="small"
                    placeholder="Wajib diisi"
                    value={formData.amount === 0 ? '' : formData.amount.toLocaleString('id-ID')}
                    onChange={e => {
                        const rawValue = e.target.value.replace(/[^0-9]/g, '')
                        const intValue = parseInt(rawValue, 10)
                        setFormData({...formData, amount: isNaN(intValue) ? 0 : intValue})
                    }}
                    InputProps={{ startAdornment: <InputAdornment position="start">Rp</InputAdornment> }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField 
                    fullWidth label="Tanggal Kejadian" type="date" size="small"
                    InputLabelProps={{ shrink: true }}
                    value={formData.date}
                    onChange={e => setFormData({...formData, date: e.target.value})}
                  />
                </Grid>
                <Grid item xs={12}>
                  <Button 
                    type="submit" variant="contained" fullWidth size="large"
                    disabled={saveLoading} startIcon={<i className='ri-send-plane-fill' />}
                  >
                    {saveLoading ? 'Mengirim...' : 'Kirim Sanksi'}
                  </Button>
                </Grid>
              </Grid>
            </form>
          </CardContent>
        </Card>
      </Grid>

      {/* 2. Unified History Table */}
      <Grid item xs={12} md={8}>
        <Card variant="outlined">
          <CardHeader 
            title="Riwayat Pelanggaran & Sanksi" 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-history-line' style={{ fontSize: '1.5rem', color: '#64748b' }} />}
            action={
              <Box sx={{ display: 'flex', gap: 2 }}>
                <TextField
                  size="small" 
                  placeholder="Cari Karyawan / Pelanggaran..."
                  value={searchKeyword}
                  onChange={e => { setSearchKeyword(e.target.value); setPage(0); }}
                  sx={{ width: 200 }}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <i className="ri-search-line"></i>
                      </InputAdornment>
                    ),
                  }}
                />
                <TextField
                  select size="small" label="Bulan"
                  value={month}
                  onChange={e => { setMonth(e.target.value); setPage(0); }}
                  sx={{ width: 140 }}
                >
                  <MenuItem value="">Semua Bulan</MenuItem>
                  {['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'].map((m, i) => (
                    <MenuItem key={i} value={(i + 1).toString()}>{m}</MenuItem>
                  ))}
                </TextField>
                <TextField
                  select size="small" label="Tahun"
                  value={year}
                  onChange={e => { setYear(e.target.value); setPage(0); }}
                  sx={{ width: 100 }}
                >
                  {availableYears.map(y => (
                    <MenuItem key={y} value={y}>{y}</MenuItem>
                  ))}
                </TextField>
              </Box>
            }
          />
            <Divider />
            
            {/* Tabs for Filtering Category */}
            <Box sx={{ borderBottom: 1, borderColor: 'divider', px: 4 }}>
                <Tabs 
                    value={tabValue} 
                    onChange={(e, v) => { setTabValue(v); setPage(0); }} 
                    textColor="primary"
                    indicatorColor="primary"
                >
                    <Tab label="Semua Pelanggaran" sx={{ fontWeight: 'bold' }} />
                    <Tab label="Otomatis Absensi" sx={{ fontWeight: 'bold' }} />
                    <Tab label="Sanksi Manual" sx={{ fontWeight: 'bold' }} />
                </Tabs>
            </Box>

          <TableContainer component={Paper} elevation={0}>
            <Table>
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: '700' }}>Karyawan</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Jenis Pelanggaran</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Jumlah Sanksi</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Tanggal</TableCell>
                  <TableCell align="right" sx={{ fontWeight: '700' }}>Aksi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {unifiedViolations.map((row) => (
                  <TableRow key={row.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                        <Avatar 
                          src={row.photo_url}
                          sx={{ width: 32, height: 32, fontSize: '0.875rem', bgcolor: 'primary.light' }}
                        >
                            {row.user_name?.charAt(0) || '?'}
                        </Avatar>
                        <Box>
                            <Typography variant="body2" fontWeight="600">{row.user_name}</Typography>
                            <Typography variant="caption" color="text.secondary">{row.user_email}</Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                        <Box className="flex flex-col gap-1">
                            <Typography variant="body2" fontWeight="500">{row.title}</Typography>
                            <Chip 
                                label={row.type === 'MANUAL' ? 'MANUAL' : 'ABSENSI'} 
                                size="small" 
                                variant="outlined"
                                color={row.type === 'MANUAL' ? 'info' : 'warning'}
                                sx={{ height: 20, fontSize: '9px', fontWeight: 'bold' }}
                            />
                        </Box>
                    </TableCell>
                    <TableCell>
                        <Typography variant="body2" color="error.main" fontWeight="800">
                            Rp {row.amount.toLocaleString('id-ID')}
                        </Typography>
                    </TableCell>
                    <TableCell>
                        <Typography variant="body2" color="text.secondary">
                            {row.date ? formatFullDate(row.date) : '-'}
                        </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <IconButton 
                        size="small" color="error" 
                        onClick={() => handleDelete(row)}
                        title={row.type === 'ABSENSI' ? 'Putihkan Sanksi' : 'Hapus Sanksi'}
                      >
                        <i className={row.type === 'ABSENSI' ? "ri-checkbox-circle-line" : "ri-delete-bin-7-line"} />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
                {unifiedViolations.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} align="center" sx={{ py: 15 }}>
                        <Box sx={{ color: 'text.secondary', opacity: 0.5 }}>
                            <i className="ri-inbox-line" style={{ fontSize: '3rem' }} />
                            <Typography variant="body2" sx={{ mt: 2 }}>Belum ada data pelanggaran tercatat.</Typography>
                        </Box>
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
          <TablePagination
            rowsPerPageOptions={[5, 10, 25]}
            component="div"
            count={totalCount}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
            labelRowsPerPage="Baris per halaman:"
          />
        </Card>
      </Grid>

      <ConfirmDialog 
        open={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={confirmDelete}
        title={selectedViolation?.type === 'ABSENSI' ? "Putihkan Sanksi Absensi" : "Hapus Catatan Pelanggaran"}
        message={
          selectedViolation?.type === 'ABSENSI' 
          ? `Apakah Anda yakin ingin memutihkan sanksi ${selectedViolation.title} untuk ${selectedViolation.user_name}? Status denda akan menjadi Rp 0 dan status kehadiran akan diperbarui.`
          : "Menghapus data sanksi akan mempengaruhi perhitungan gaji karyawan pada periode terkait. Apakah Anda yakin?"
        }
        type={selectedViolation?.type === 'ABSENSI' ? "info" : "error"}
      />
    </Grid>
  )
}

export default PenaltyManager
