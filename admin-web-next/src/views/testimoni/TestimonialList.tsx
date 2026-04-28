'use client'

import React, { useState, useEffect, useCallback } from 'react'
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
  TextField,
  InputAdornment,
  Box,
  Avatar,
  CircularProgress,
  TablePagination,
  IconButton,
  Tooltip,
  Dialog,
  DialogContent,
  Divider,
  Button,
  Rating
} from '@mui/material'
import { employeeService } from '../../libs/employeeService'
import { formatFullDate } from '@/utils/dateFormatter'
import ConfirmDialog from '@/components/ConfirmDialog'
import { useNotification } from '@/contexts/NotificationContext'

const TestimonialList = () => {
  // States
  const [testimonials, setTestimonials] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const { showNotification } = useNotification()

  // Modal States
  const [deleteConfirmId, setDeleteConfirmId] = useState<number | null>(null)
  const [isDeleting, setIsDeleting] = useState(false)

  // Pagination States
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const data = await employeeService.getAllTestimonials()
      setTestimonials(data || [])
      setPage(0)
    } catch (error) {
      console.error(error)
      showNotification('Gagal memuat testimoni', 'error')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData()
  }, [loadData])

  const handleDelete = async () => {
    if (deleteConfirmId === null) return
    setIsDeleting(true)
    try {
      await employeeService.deleteTestimonial(deleteConfirmId)
      showNotification('Testimoni berhasil dihapus', 'success')
      loadData()
      setDeleteConfirmId(null)
    } catch (error) {
      console.error(error)
      showNotification('Gagal menghapus testimoni', 'error')
    } finally {
      setIsDeleting(false)
    }
  }


  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const filteredTestimonials = testimonials.filter((t: any) => {
    const matchesSearch = t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.description.toLowerCase().includes(searchQuery.toLowerCase())
    return matchesSearch
  })

  const paginatedTestimonials = filteredTestimonials.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {/* Page Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', flexWrap: 'wrap', gap: 4 }}>
        <Box>
          <Typography variant='h4' fontWeight='900' color='primary' className='tracking-tight' gutterBottom>
            Kelola Testimoni Pelanggan
          </Typography>
          <Typography variant='body2' className='text-[var(--mui-palette-text-secondary)] font-medium'>
            Moderasi dan kelola testimoni yang diberikan oleh pengunjung di halaman landing.
          </Typography>
        </Box>
        <Box className='flex gap-3 bg-[var(--mui-palette-background-paper)] p-2 rounded-2xl border border-[var(--mui-palette-divider)]'>
          <Chip icon={<i className='ri-chat-heart-line' />} label={`${testimonials.length} Total Testimoni`} variant="outlined" className='font-bold' />
        </Box>
      </Box>

      {/* Filter Card */}
      <Card sx={{ border: 'none', borderRadius: '1.5rem', boxShadow: '0 4px 20px rgba(0,0,0,0.05)' }}>
        <Box sx={{ px: 6, py: 5, display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 6, flexWrap: 'wrap' }}>
          <TextField
            size='small'
            placeholder='Cari Nama / Isi Testimoni...'
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            sx={{
              width: { xs: '100%', sm: 350 },
              '& .MuiOutlinedInput-root': { borderRadius: '12px', bgcolor: 'action.hover', border: 'none' },
              '& .MuiOutlinedInput-notchedOutline': { border: 'none' }
            }}
            InputProps={{
              startAdornment: (
                <InputAdornment position='start'>
                  <i className='ri-search-2-line text-primary' />
                </InputAdornment>
              )
            }}
          />
        </Box>
      </Card>

      {/* Table Card */}
      <Card sx={{ border: 'none', borderRadius: '1.5rem', boxShadow: '0 4px 20px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
        <TableContainer component={Paper} elevation={0}>
          {loading ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', p: 15, gap: 4 }}>
              <CircularProgress size={48} thickness={4} />
              <Typography variant="caption" className='font-bold uppercase tracking-widest text-slate-400'>Memuat Testimoni...</Typography>
            </Box>
          ) : (
            <Table sx={{ minWidth: 800 }}>
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase', tracking: '0.1em' }}>Pelanggan</TableCell>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase', tracking: '0.1em' }}>Rating & Isi</TableCell>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase', tracking: '0.1em' }}>Tanggal</TableCell>
                  <TableCell align="center" sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase', tracking: '0.1em' }}>Aksi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginatedTestimonials.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={4} align='center' sx={{ py: 15 }}>
                      <Box className='flex flex-col items-center gap-2 opacity-30'>
                        <i className='ri-chat-history-line text-6xl' />
                        <Typography className='font-bold'>Tidak ada testimoni yang ditemukan.</Typography>
                      </Box>
                    </TableCell>
                  </TableRow>
                ) : paginatedTestimonials.map((row: any) => (
                  <TableRow hover key={row.id}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Avatar
                          src={row.photo_url 
                            ? `${process.env.NEXT_PUBLIC_API_URL?.split('/api')[0]}${row.photo_url}` 
                            : `/images/avatars/${(testimonials.indexOf(row) % 8) + 1}.png`}
                          sx={{ mr: 4, width: 44, height: 44, border: '2px solid var(--mui-palette-divider)' }}
                        >
                          {row.name.charAt(0)}
                        </Avatar>
                        <Typography variant='body2' fontWeight="900" color='text.primary'>{row.name}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell sx={{ maxWidth: 400 }}>
                      <Rating value={row.rating} readOnly size="small" sx={{ mb: 1 }} />
                      <Typography variant='body2' className='font-medium line-clamp-2' sx={{ display: 'block' }}>
                        {row.description}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant='body2' className='font-bold text-slate-600'>{formatFullDate(row.created_at)}</Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Box className='flex justify-center gap-2'>
                        <Tooltip title="Hapus Testimoni">
                          <IconButton 
                            size="small" 
                            color="error" 
                            onClick={() => setDeleteConfirmId(row.id)}
                            disabled={isDeleting}
                          >
                            <i className='ri-delete-bin-7-line' />
                          </IconButton>
                        </Tooltip>
                      </Box>
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
          count={filteredTestimonials.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Baris per halaman:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} dari ${count !== -1 ? count : `lebih dari ${to}`}`}
        />
      </Card>

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteConfirmId !== null}
        onClose={() => setDeleteConfirmId(null)}
        onConfirm={handleDelete}
        title="Hapus Testimoni?"
        message="Tindakan ini tidak dapat dibatalkan. Testimoni akan dihapus secara permanen dari sistem dan landing page."
        type="error"
        confirmText="Ya, Hapus"
      />
    </Box>
  )
}

export default TestimonialList
