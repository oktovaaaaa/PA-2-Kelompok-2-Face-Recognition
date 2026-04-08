// src/views/operasional/PenaltyManager.tsx
'use client'

import { useState, useEffect, useCallback } from 'react'
import { 
  Card, CardHeader, CardContent, Grid, TextField, 
  Button, Typography, Box, CircularProgress, IconButton,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination,
  Paper, Avatar, MenuItem, InputAdornment, Divider
} from '@mui/material'
import { settingService, ManualPenalty } from '@/libs/settingService'
import { employeeService, Employee } from '@/libs/employeeService'
import { format } from 'date-fns'
import { useNotification } from '@/contexts/NotificationContext'
import { formatFullDate } from '@/utils/dateFormatter'
import ConfirmDialog from '@/components/ConfirmDialog'

const PenaltyManager = () => {
  const { showNotification } = useNotification()
  const [penalties, setPenalties] = useState<ManualPenalty[]>([])
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
  
  // Confirm Dialog State
  const [isConfirmOpen, setIsConfirmOpen] = useState(false)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const loadData = useCallback(async (currPage: number = 0, limit: number = 10, fMonth: string, fYear: string, fSearch: string) => {
    // We don't set global loading here to avoid flashing, only for initial load
    try {
      const [res, eData, yData] = await Promise.all([
        settingService.getManualPenalties(currPage + 1, limit, fMonth, fYear, fSearch),
        employeeService.getEmployees('ACTIVE'),
        settingService.getPenaltyYears()
      ])

      setPenalties(res.data || [])
      setTotalCount(res.total || 0)
      setEmployees(eData || [])
      
      if (yData && yData.length > 0) {
        setAvailableYears(yData)
        // Jika year saat ini tidak ada di yData dan yData tidak kosong, bisa pilih yang terbaru
        if (!yData.includes(year) && fYear === year) {
            // Biarkan saja defaultnya, backend akan return kosong jika memang tidak ada
        }
      } else {
        setAvailableYears([new Date().getFullYear().toString()])
      }
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }, [year])

  useEffect(() => {
    loadData(page, rowsPerPage, month, year, searchKeyword)
  }, [loadData, page, rowsPerPage, month, year, searchKeyword])

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

  const handleDelete = async (id: string) => {
    setSelectedId(id)
    setIsConfirmOpen(true)
  }

  const confirmDelete = async () => {
    if (!selectedId) return
    try {
      await settingService.deletePenalty(selectedId)
      showNotification('Data denda berhasil dihapus.', 'success')
      loadData(page, rowsPerPage, month, year, searchKeyword)
    } catch (error) {
      showNotification('Gagal menghapus data.', 'error')
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
                  <TextField
                    select fullWidth label="Pilih Karyawan" size="small" required
                    value={formData.user_id}
                    onChange={e => setFormData({...formData, user_id: e.target.value})}
                  >
                    {employees.map(emp => (
                      <MenuItem key={emp.id} value={emp.id}>{emp.name}</MenuItem>
                    ))}
                  </TextField>
                </Grid>
                <Grid item xs={12}>
                  <TextField 
                    fullWidth label="Judul / Jenis Pelanggaran" size="small" required
                    placeholder="Misal: Pecah Kaca, Kerusakan Alat"
                    value={formData.title}
                    onChange={e => setFormData({...formData, title: e.target.value})}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField 
                    fullWidth label="Besar Sanksi" type="text" size="small" required
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
                    fullWidth label="Tanggal Kejadian" type="date" size="small" required
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

      {/* 2. History Table */}
      <Grid item xs={12} md={8}>
        <Card variant="outlined">
          <CardHeader 
            title="Riwayat Pelanggaran Terbaru" 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-history-line' style={{ fontSize: '1.5rem', color: '#64748b' }} />}
            action={
              <Box sx={{ display: 'flex', gap: 2 }}>
                <TextField
                  size="small" 
                  placeholder="Cari Karyawan / Pelanggaran..."
                  value={searchKeyword}
                  onChange={e => { setSearchKeyword(e.target.value); setPage(0); }}
                  sx={{ width: 250 }}
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
                  sx={{ width: 150 }}
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
                  {!availableYears.includes(new Date().getFullYear().toString()) && (
                      <MenuItem value={new Date().getFullYear().toString()}>{new Date().getFullYear()}</MenuItem>
                  )}
                </TextField>
              </Box>
            }
          />
          <Divider />
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
                {penalties.map((row) => (
                  <TableRow key={row.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                        <Avatar sx={{ width: 32, height: 32, fontSize: '0.875rem', bgcolor: 'primary.light' }}>
                            {row.user?.name?.charAt(0) || '?'}
                        </Avatar>
                        <Typography variant="body2" fontWeight="600">{row.user?.name || 'Karyawan'}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell><Typography variant="body2">{row.title}</Typography></TableCell>
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
                      <IconButton size="small" color="error" onClick={() => handleDelete(row.id)}>
                        <i className="ri-delete-bin-7-line" />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
                {penalties.length === 0 && (
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
        title="Hapus Catatan Pelanggaran"
        message="Menghapus data sanksi akan mempengaruhi perhitungan gaji karyawan pada periode terkait. Apakah Anda yakin?"
        type="error"
      />
    </Grid>
  )
}

export default PenaltyManager
