// src/views/karyawan/EmployeeList.tsx
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
  Tab,
  Tabs,
  CircularProgress,
  TablePagination
} from '@mui/material'
import { employeeService, Employee } from '../../libs/employeeService'
import EmployeeDetailModal from './EmployeeDetailModal'
import PositionAssignModal from './PositionAssignModal'
import ConfirmDialog from '@/components/ConfirmDialog'
import { useNotification } from '@/contexts/NotificationContext'
import { Dialog, DialogTitle, DialogContent, DialogActions, Alert, Divider } from '@mui/material'

const EmployeeList = () => {
  const { showNotification } = useNotification()

  // States
  const [employees, setEmployees] = useState<Employee[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState<'ACTIVE' | 'RESIGNED'>('ACTIVE')
  const [searchQuery, setSearchQuery] = useState('')

  // Modal States
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)
  const [isPositionOpen, setIsPositionOpen] = useState(false)
  const [isConfirmOpen, setIsConfirmOpen] = useState(false)
  const [confirmConfig, setConfirmConfig] = useState<{
    title: string,
    message: string,
    type: 'warning' | 'error' | 'info',
    action: () => void
  } | null>(null)

  // Pagination States
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)

  // Double Confirm States for Firing
  const [isFireConfirmOpen, setIsFireConfirmOpen] = useState(false)
  const [firePhrase, setFirePhrase] = useState('')
  const [fireError, setFireError] = useState('')
  const [fireLoading, setFireLoading] = useState(false)

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const data = await employeeService.getEmployees(statusFilter)
      setEmployees(data || [])
      setPage(0)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }, [statusFilter])

  useEffect(() => {
    loadData()
  }, [loadData])

  const handleOpenDetail = (emp: Employee) => {
    setSelectedEmployee(emp)
    setIsDetailOpen(true)
  }

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const handleAction = async (type: 'reset' | 'position' | 'status') => {
    if (!selectedEmployee) return

    if (type === 'reset') {
      setConfirmConfig({
        title: 'Reset Perangkat',
        type: 'warning',
        message: `Apakah Anda yakin ingin mereset perangkat untuk ${selectedEmployee.name}? Karyawan dapat login kembali dari HP baru.`,
        action: async () => {
          try {
            await employeeService.resetDevice(selectedEmployee.id)
            showNotification('Perangkat berhasil direset!', 'success')
            loadData()
          } catch (e) {
            showNotification('Gagal mereset perangkat.', 'error')
          }
        }
      })
      setIsConfirmOpen(true)
    } else if (type === 'position') {
      setIsPositionOpen(true)
    } else if (type === 'status') {
      const isFiring = selectedEmployee.status === 'ACTIVE'
      setConfirmConfig({
        title: isFiring ? 'Pecat Karyawan' : 'Aktifkan Kembali',
        type: isFiring ? 'error' : 'info',
        message: isFiring
          ? `Apakah Anda yakin ingin memecat ${selectedEmployee.name}? Status akan menjadi RESIGNED.`
          : `Aktifkan kembali ${selectedEmployee.name}?`,
        action: async () => {
          if (isFiring) {
            // If firing, show step 2
            setFirePhrase('')
            setFireError('')
            setIsFireConfirmOpen(true)
          } else {
            // reactivation is fine with 1 step
            try {
              await employeeService.reactivateEmployee(selectedEmployee.id)
              showNotification('Karyawan telah diaktifkan kembali.', 'success')
              loadData()
            } catch (e) {
              showNotification('Gagal mengaktifkan karyawan.', 'error')
            }
          }
        }
      })
      setIsConfirmOpen(true)
    }
  }

  const handleFinalFire = async () => {
    if (!selectedEmployee) return
    const requiredPhrase = `SAYA YAKIN UNTUK MEMBERHENTIKAN KARYAWAN YANG BERNAMA ${selectedEmployee.name.toUpperCase()}`

    if (firePhrase.trim().toUpperCase() !== requiredPhrase) {
      setFireError(`Harap ketik frasa konfirmasi dengan benar.`)
      return
    }

    setFireLoading(true)
    try {
      await employeeService.fireEmployee(selectedEmployee.id)
      showNotification('Karyawan telah dinonaktifkan.', 'success')
      setIsFireConfirmOpen(false)
      loadData()
    } catch (e) {
      showNotification('Gagal memecat karyawan.', 'error')
    } finally {
      setFireLoading(false)
    }
  }

  const handleAssignPosition = async (posId: string) => {
    if (!selectedEmployee) return
    try {
      await employeeService.assignPosition(selectedEmployee.id, posId)
      setIsPositionOpen(false)
      showNotification('Jabatan berhasil diperbarui!', 'success')
      loadData()
      const updated = employees.find(e => e.id === selectedEmployee.id)
      if (updated) setSelectedEmployee({ ...updated, position_id: posId })
    } catch (error) {
      showNotification('Gagal memperbarui jabatan.', 'error')
    }
  }

  const filteredEmployees = employees.filter(emp =>
    emp.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    emp.email.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const paginatedEmployees = filteredEmployees.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {/* Page Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant='h4' fontWeight='800' color='primary' gutterBottom>
            Data Karyawan
          </Typography>
          <Typography variant='body2' color='text.secondary'>
            Kelola data, status, dan jabatan {employees.length} karyawan di perusahaan Anda.
          </Typography>
        </Box>
      </Box>

      <Card sx={{ border: '1px solid', borderColor: 'divider' }}>
        <Box sx={{ px: 5, py: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 4, flexWrap: 'wrap' }}>
          <Tabs
            value={statusFilter}
            onChange={(_, val) => setStatusFilter(val)}
            sx={{ borderBottom: 0 }}
          >
            <Tab label="Aktif" value="ACTIVE" />
            <Tab label="Diberhentikan" value="RESIGNED" />
          </Tabs>

          <TextField
            size='small'
            placeholder='Cari Nama / Email...'
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            sx={{ width: { xs: '100%', sm: 300 } }}
            InputProps={{
              startAdornment: (
                <InputAdornment position='start'>
                  <i className='ri-search-line' />
                </InputAdornment>
              )
            }}
          />
        </Box>
      </Card>

      <Card>
        <TableContainer component={Paper} elevation={0}>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 10 }}>
              <CircularProgress size={40} />
            </Box>
          ) : (
            <Table sx={{ minWidth: 800 }}>
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: '600' }}>Karyawan</TableCell>
                  <TableCell sx={{ fontWeight: '600' }}>Email</TableCell>
                  <TableCell sx={{ fontWeight: '600' }}>Jabatan</TableCell>
                  <TableCell align="center" sx={{ fontWeight: '600' }}>Status</TableCell>
                  <TableCell align="right" sx={{ fontWeight: '600' }}>Aksi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginatedEmployees.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} align='center' sx={{ py: 10 }}>
                      <Typography color='textSecondary'>Tidak ada data karyawan ditemukan.</Typography>
                    </TableCell>
                  </TableRow>
                ) : paginatedEmployees.map((row) => (
                  <TableRow
                    key={row.id}
                    hover
                    onClick={() => handleOpenDetail(row)}
                    sx={{ cursor: 'pointer', '&:last-child td, &:last-child th': { border: 0 } }}
                  >
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Avatar
                          src={row.photo_url ? `http://localhost:8080${row.photo_url}` : undefined}
                          sx={{ mr: 3, width: 34, height: 34 }}
                        >
                          {row.name.charAt(0)}
                        </Avatar>
                        <Typography variant='body2' fontWeight="600" color='text.primary'>{row.name}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant='body2'>{row.email}</Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={row.position_name || 'Belum Ditentukan'}
                        size='small'
                        variant='outlined'
                        sx={{ bgcolor: 'background.paper', color: 'primary.main' }}
                        color={row.position_name ? 'primary' : 'default'}
                      />
                    </TableCell>
                    <TableCell align="center">
                      <Chip
                        label={row.status === 'ACTIVE' ? 'Aktif' : 'Diberhentikan'}
                        color={row.status === 'ACTIVE' ? 'success' : 'error'}
                        size='small'
                        variant='outlined'
                      />
                    </TableCell>
                    <TableCell align="right">
                      <IconButton color='primary' size='small' onClick={(e) => { e.stopPropagation(); handleOpenDetail(row); }}>
                        <i className='ri-eye-line' />
                      </IconButton>
                      <IconButton color={row.status === 'ACTIVE' ? 'error' : 'success'} size='small' onClick={(e) => { e.stopPropagation(); setSelectedEmployee(row); handleAction('status'); }}>
                        <i className={row.status === 'ACTIVE' ? 'ri-user-unfollow-line' : 'ri-user-add-line'} />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </TableContainer>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component='div'
          count={filteredEmployees.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Baris per halaman:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} dari ${count !== -1 ? count : `lebih dari ${to}`}`}
        />
      </Card>

      {/* Modals & Dialogs */}
      <EmployeeDetailModal
        open={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        employee={selectedEmployee}
        onAction={handleAction}
      />

      <PositionAssignModal
        open={isPositionOpen}
        onClose={() => setIsPositionOpen(false)}
        employeeName={selectedEmployee?.name || ''}
        currentPositionId={selectedEmployee?.position_id}
        onAssign={handleAssignPosition}
      />

      <ConfirmDialog
        open={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={confirmConfig?.action || (() => { })}
        title={confirmConfig?.title || ''}
        message={confirmConfig?.message || ''}
        type={confirmConfig?.type}
      />

      {/* Confirmation Step 2: Firing ONLY */}
      <Dialog open={isFireConfirmOpen} onClose={() => setIsFireConfirmOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: '700', color: 'error.main' }}>
          <Box className="flex items-center gap-3">
            <i className="ri-error-warning-fill text-2xl" />
            Konfirmasi Pemeceatan
          </Box>
        </DialogTitle>
        <Divider />
        <DialogContent>
          <Alert severity="error" variant="outlined" sx={{ mb: 4, mt: 2 }}>
            Tindakan ini akan menonaktifkan akun karyawan <strong>{selectedEmployee?.name}</strong>.
          </Alert>
          <Typography variant="body2" sx={{ mb: 4 }}>
            Ketik frasa di bawah ini untuk memproses pemecatan:
            <Box sx={{
              display: 'block',
              fontWeight: '800',
              color: '#991b1b',
              mt: 2,
              letterSpacing: 1,
              textAlign: 'center',
              p: 3,
              bgcolor: '#fef2f2',
              borderRadius: 2,
              border: '1px solid #fecaca',
              fontSize: '0.85rem',
              lineHeight: 1.5,
              wordBreak: 'break-word'
            }}>
              SAYA YAKIN UNTUK MEMBERHENTIKAN KARYAWAN YANG BERNAMA {selectedEmployee?.name.toUpperCase()}
            </Box>
          </Typography>
          <TextField
            fullWidth
            label="Ketik Frasa Konfirmasi"
            placeholder="Ketik frasa di atas"
            value={firePhrase}
            onChange={(e) => {
              setFirePhrase(e.target.value)
              setFireError('')
            }}
            error={!!fireError}
            helperText={fireError}
            autoFocus
          />
        </DialogContent>
        <DialogActions sx={{ px: 6, pb: 4 }}>
          <Button onClick={() => setIsFireConfirmOpen(false)} variant="outlined">Batal</Button>
          <Button
            onClick={handleFinalFire}
            variant="contained"
            color="error"
            disabled={fireLoading || firePhrase.trim().toUpperCase() !== `SAYA YAKIN UNTUK MEMBERHENTIKAN KARYAWAN YANG BERNAMA ${selectedEmployee?.name.toUpperCase()}`}
            startIcon={fireLoading ? <CircularProgress size={16} color="inherit" /> : <i className="ri-delete-bin-7-line" />}
          >
            {fireLoading ? 'Memproses...' : 'Pecat Karyawan'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default EmployeeList
