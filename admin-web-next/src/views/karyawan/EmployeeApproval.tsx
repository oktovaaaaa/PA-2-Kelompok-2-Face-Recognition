// src/views/karyawan/EmployeeApproval.tsx
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
  Box,
  Avatar,
  CircularProgress,
  TablePagination,
  TextField,
  InputAdornment
} from '@mui/material'
import { employeeService, Employee } from '../../libs/employeeService'
import ConfirmDialog from '@/components/ConfirmDialog'
import { useNotification } from '@/contexts/NotificationContext'

const EmployeeApproval = () => {
  const { showNotification } = useNotification()
  
  // States
  const [employees, setEmployees] = useState<Employee[]>([])
  const [loading, setLoading] = useState(true)
  const [actionLoading, setActionLoading] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  
  // Modal States
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null)
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

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const data = await employeeService.getPendingEmployees()
      setEmployees(data || [])
      setPage(0)
    } catch (error) {
      console.error(error)
      showNotification('Gagal mengambil data pendaftaran.', 'error')
    } finally {
      setLoading(false)
    }
  }, [showNotification])

  useEffect(() => {
    loadData()
  }, [loadData])

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const handleApprove = (emp: Employee) => {
    setSelectedEmployee(emp)
    setConfirmConfig({
      title: 'Setujui Karyawan',
      type: 'info',
      message: `Apakah Anda yakin ingin menyetujui pendaftaran ${emp.name}? Karyawan akan dapat mulai melakukan absensi.`,
      action: async () => {
        setActionLoading(true)
        try {
          await employeeService.approveEmployee(emp.id)
          showNotification('Karyawan berhasil disetujui!', 'success')
          loadData()
        } catch (e) {
          showNotification('Gagal menyetujui karyawan.', 'error')
        } finally {
          setActionLoading(false)
        }
      }
    })
    setIsConfirmOpen(true)
  }

  const handleReject = (emp: Employee) => {
    setSelectedEmployee(emp)
    setConfirmConfig({
      title: 'Tolak Pendaftaran',
      type: 'error',
      message: `Tolak pendaftaran ${emp.name}? Data karyawan akan dihapus secara permanen sehingga email mereka bisa digunakan kembali.`,
      action: async () => {
        setActionLoading(true)
        try {
          await employeeService.rejectEmployee(emp.id)
          showNotification('Pendaftaran ditolak dan data dihapus.', 'info')
          loadData()
        } catch (e) {
          showNotification('Gagal menolak pendaftaran.', 'error')
        } finally {
          setActionLoading(false)
        }
      }
    })
    setIsConfirmOpen(true)
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
            Persetujuan Karyawan
          </Typography>
          <Typography variant='body2' color='text.secondary'>
            Daftar pendaftar baru yang memerlukan verifikasi ({employees.length} pending)
          </Typography>
        </Box>
      </Box>

      <Card sx={{ border: '1px solid', borderColor: 'divider' }}>
        <Box sx={{ p: 5, display: 'flex', alignItems: 'center', justifyContent: 'flex-end', flexWrap: 'wrap', gap: 4 }}>
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
                  <TableCell sx={{ fontWeight: '600' }}>Pendaftar</TableCell>
                  <TableCell sx={{ fontWeight: '600' }}>Email</TableCell>
                  <TableCell sx={{ fontWeight: '600' }}>Telepon</TableCell>
                  <TableCell align="center" sx={{ fontWeight: '600' }}>Status</TableCell>
                  <TableCell align="right" sx={{ fontWeight: '600' }}>Aksi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginatedEmployees.length === 0 ? (
                    <TableRow>
                        <TableCell colSpan={5} align='center' sx={{ py: 10 }}>
                            <Typography color='textSecondary'>Tidak ada pendaftaran baru yang ditemukan.</Typography>
                        </TableCell>
                    </TableRow>
                ) : paginatedEmployees.map((row) => (
                  <TableRow key={row.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Avatar 
                          src={row.photo_url ? `http://localhost:8080${row.photo_url}` : undefined}
                          sx={{ mr: 3, width: 34, height: 34 }} 
                        >
                          {row.name?.charAt(0)}
                        </Avatar>
                        <Typography variant='body2' fontWeight="600" color='text.primary'>{row.name}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                        <Typography variant='body2'>{row.email}</Typography>
                    </TableCell>
                    <TableCell>
                        <Typography variant='body2'>{row.phone || '-'}</Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Chip label="PENDING" color="warning" size='small' variant='outlined' />
                    </TableCell>
                    <TableCell align="right">
                      <IconButton 
                        color='success' 
                        size='small' 
                        onClick={() => handleApprove(row)}
                        disabled={actionLoading}
                      >
                        <i className='ri-check-line' />
                      </IconButton>
                      <IconButton 
                        color='error' 
                        size='small' 
                        onClick={() => handleReject(row)}
                        disabled={actionLoading}
                      >
                        <i className='ri-close-line' />
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
          component="div"
          count={filteredEmployees.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Baris per halaman"
        />
      </Card>

      <ConfirmDialog
        open={isConfirmOpen}
        onClose={() => !actionLoading && setIsConfirmOpen(false)}
        title={confirmConfig?.title || ''}
        message={confirmConfig?.message || ''}
        onConfirm={confirmConfig?.action || (() => {})}
        type={confirmConfig?.type || 'info'}
        loading={actionLoading}
      />
    </Box>
  )
}

export default EmployeeApproval
