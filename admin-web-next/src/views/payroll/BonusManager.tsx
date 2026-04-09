// src/views/payroll/BonusManager.tsx

'use client'

import { useState, useEffect, useCallback } from 'react'
import { 
  Card, CardHeader, CardContent, Grid, TextField, 
  Button, Typography, Box, CircularProgress, IconButton,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination,
  Paper, Avatar, MenuItem, InputAdornment, Divider
} from '@mui/material'
import { bonusService, Bonus } from '@/libs/bonusService'
import { employeeService, Employee } from '@/libs/employeeService'
import { format } from 'date-fns'
import { useNotification } from '@/contexts/NotificationContext'
import { formatFullDate } from '@/utils/dateFormatter'
import ConfirmDialog from '@/components/ConfirmDialog'

const BonusManager = () => {
  const { showNotification } = useNotification()
  const [bonuses, setBonuses] = useState<Bonus[]>([])
  const [employees, setEmployees] = useState<Employee[]>([])
  const [loading, setLoading] = useState(true)
  const [saveLoading, setSaveLoading] = useState(false)
  
  // Form State
  const [formData, setFormData] = useState({ user_id: '', title: '', amount: 0, date: format(new Date(), 'yyyy-MM-dd'), description: '' })
  
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
    try {
      // 1. Fetch Employees separately to ensure dropdown is populated even if others fail
      const eData = await employeeService.getEmployees().catch(() => [])
      setEmployees(eData || [])

      // 2. Fetch Bonuses and Years
      const [res, yData] = await Promise.all([
        bonusService.getBonuses(currPage + 1, limit, fMonth, fYear, fSearch).catch(() => ({ data: [], total: 0 })),
        bonusService.getBonusYears().catch(() => [new Date().getFullYear().toString()])
      ])

      setBonuses(res.data || [])
      setTotalCount(res.total || 0)
      setAvailableYears(yData || [new Date().getFullYear().toString()])
    } catch (error) {
      console.error('Error loading bonus data:', error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData(page, rowsPerPage, month, year, searchKeyword)
  }, [loadData, page, rowsPerPage, month, year, searchKeyword])

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData.user_id || !formData.amount || !formData.title) {
        showNotification('Mohon lengkapi semua data.', 'error')
        return
    }
    setSaveLoading(true)
    try {
      await bonusService.createBonus(formData)
      showNotification('Bonus berhasil dicatatkan!', 'success')
      setFormData({ user_id: '', title: '', amount: 0, date: format(new Date(), 'yyyy-MM-dd'), description: '' })
      loadData(page, rowsPerPage, month, year, searchKeyword)
    } catch (error: any) {
      showNotification(error.message || 'Gagal menambahkan bonus.', 'error')
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
      await bonusService.deleteBonus(selectedId)
      showNotification('Catatan bonus berhasil dihapus.', 'success')
      loadData(page, rowsPerPage, month, year, searchKeyword)
    } catch (error) {
      showNotification('Gagal menghapus data.', 'error')
    }
  }

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', p: 10 }}><CircularProgress /></Box>

  return (
    <Grid container spacing={6}>
      {/* 1. Form Input */}
      <Grid item xs={12} md={4}>
        <Card variant="outlined">
          <CardHeader 
            title="Berikan Bonus / Insentif" 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-medal-fill' style={{ fontSize: '1.5rem', color: '#10b981' }} />}
            subheader="Tambahkan nominal positif ke gaji karyawan" 
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
                    fullWidth label="Nama Bonus" size="small" required
                    placeholder="Misal: Bonus Performa, Insentif Lembur"
                    value={formData.title}
                    onChange={e => setFormData({...formData, title: e.target.value})}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField 
                    fullWidth label="Besar Nominal" type="text" size="small" required
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
                    fullWidth label="Tanggal" type="date" size="small" required
                    InputLabelProps={{ shrink: true }}
                    value={formData.date}
                    onChange={e => setFormData({...formData, date: e.target.value})}
                  />
                </Grid>
                <Grid item xs={12}>
                  <Button 
                    type="submit" variant="contained" color="success" fullWidth size="large"
                    disabled={saveLoading} startIcon={<i className='ri-add-circle-fill' />}
                  >
                    {saveLoading ? 'Memproses...' : 'Tambahkan Bonus'}
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
            title="Riwayat Bonus & Insentif" 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-history-line' style={{ fontSize: '1.5rem', color: '#64748b' }} />}
            action={
              <Box sx={{ display: 'flex', gap: 2 }}>
                <TextField
                  size="small" placeholder="Cari..."
                  value={searchKeyword}
                  onChange={e => { setSearchKeyword(e.target.value); setPage(0); }}
                  sx={{ width: 180 }}
                />
                <TextField
                  select size="small" value={month}
                  onChange={e => { setMonth(e.target.value); setPage(0); }}
                  sx={{ width: 130 }}
                >
                  <MenuItem value="">Semua Bulan</MenuItem>
                  {['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'].map((m, i) => (
                    <MenuItem key={i} value={(i + 1).toString()}>{m}</MenuItem>
                  ))}
                </TextField>
              </Box>
            }
          />
          <Divider />
          <TableContainer>
            <Table size="small">
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: '700' }}>Karyawan</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Bonus</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Jumlah</TableCell>
                  <TableCell sx={{ fontWeight: '700' }}>Tanggal</TableCell>
                  <TableCell align="right" sx={{ fontWeight: '700' }}>Aksi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {bonuses.map((row) => (
                  <TableRow key={row.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Avatar sx={{ width: 28, height: 28, fontSize: '0.75rem' }}>{row.user?.name?.charAt(0)}</Avatar>
                        <Typography variant="body2" fontWeight="600">{row.user?.name}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell><Typography variant="body2">{row.title}</Typography></TableCell>
                    <TableCell>
                        <Typography variant="body2" color="success.main" fontWeight="800">
                             + Rp {row.amount.toLocaleString('id-ID')}
                        </Typography>
                    </TableCell>
                    <TableCell>
                        <Typography variant="body2" color="text.secondary">
                            {formatFullDate(row.date)}
                        </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <IconButton size="small" color="error" onClick={() => handleDelete(row.id)}>
                        <i className="ri-delete-bin-line" />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
          <TablePagination
            component="div" count={totalCount} rowsPerPage={rowsPerPage} page={page}
            onPageChange={(e, p) => setPage(p)}
            onRowsPerPageChange={e => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
          />
        </Card>
      </Grid>

      <ConfirmDialog 
        open={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={confirmDelete}
        title="Hapus Catatan Bonus"
        message="Menghapus bonus akan langsung mengurangi total gaji karyawan pada periode terkait. Lanjutkan?"
        type="error"
      />
    </Grid>
  )
}

export default BonusManager
