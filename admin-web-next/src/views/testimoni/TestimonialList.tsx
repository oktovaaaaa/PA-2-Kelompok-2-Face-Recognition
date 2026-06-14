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
  Button,
  Rating,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Divider,
  Alert
} from '@mui/material'

import { employeeService } from '../../libs/employeeService'
import { settingService, formatImageUrl } from '@/libs/settingService'
import { formatFullDate } from '@/utils/dateFormatter'
import ConfirmDialog from '@/components/ConfirmDialog'
import { useNotification } from '@/contexts/NotificationContext'
import type { Profile } from '@/libs/settingService'

// ─── Types ──────────────────────────────────────────────────────────────────
interface Testimonial {
  id: number
  name: string
  rating: number
  description: string
  photo_url: string
  is_approved: boolean
  created_at: string
}

interface CreateForm {
  name: string
  rating: number
  description: string
  photo_url: string
}

const EMPTY_FORM: CreateForm = { name: '', rating: 0, description: '', photo_url: '' }

// ─── Component ──────────────────────────────────────────────────────────────
const TestimonialList = () => {
  // States
  const [testimonials, setTestimonials] = useState<Testimonial[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [adminProfile, setAdminProfile] = useState<Profile | null>(null)
  const { showNotification } = useNotification()

  // Delete States
  const [deleteConfirmId, setDeleteConfirmId] = useState<number | null>(null)
  const [isDeleting, setIsDeleting] = useState(false)

  // Create Dialog States
  const [openCreate, setOpenCreate] = useState(false)
  const [form, setForm] = useState<CreateForm>(EMPTY_FORM)
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Pagination States
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)

  // ─── Helpers ──────────────────────────────────────────────────────────
  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const [data, profile] = await Promise.all([
        employeeService.getAllTestimonials(),
        settingService.getProfile()
      ])
      setTestimonials(data || [])
      setAdminProfile(profile)
      setPage(0)
    } catch (error) {
      console.error(error)
      showNotification('Gagal memuat data testimoni', 'error')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadData() }, [loadData])

  // ─── Delete ───────────────────────────────────────────────────────────
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

  // ─── Create ───────────────────────────────────────────────────────────
  const handleOpenCreate = () => {
    // Pre-fill form with admin profile data
    setForm({
      name: adminProfile?.name || '',
      rating: 0,
      description: '',
      photo_url: adminProfile?.photo_url || '',
    })
    setOpenCreate(true)
  }

  const handleCloseCreate = () => {
    if (isSubmitting) return
    setOpenCreate(false)
    setForm(EMPTY_FORM)
  }

  const handleSubmitCreate = async () => {
    if (!form.name.trim()) { showNotification('Nama tidak boleh kosong', 'warning'); return }
    if (form.rating === 0) { showNotification('Pilih rating minimal 1 bintang', 'warning'); return }
    if (!form.description.trim()) { showNotification('Isi ulasan tidak boleh kosong', 'warning'); return }

    setIsSubmitting(true)
    try {
      await employeeService.createTestimonial({
        name: form.name.trim(),
        rating: form.rating,
        description: form.description.trim(),
        photo_url: form.photo_url || undefined,
      })
      showNotification('Testimoni berhasil ditambahkan!', 'success')
      setOpenCreate(false)
      setForm(EMPTY_FORM)
      loadData()
    } catch (error) {
      console.error(error)
      showNotification('Gagal menambahkan testimoni', 'error')
    } finally {
      setIsSubmitting(false)
    }
  }

  // ─── Pagination ───────────────────────────────────────────────────────
  const handleChangePage = (_: unknown, newPage: number) => setPage(newPage)
  const handleChangeRowsPerPage = (e: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(e.target.value, 10))
    setPage(0)
  }

  // ─── Filter & Paginate ────────────────────────────────────────────────
  const filtered = testimonials.filter((t) =>
    t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    t.description.toLowerCase().includes(searchQuery.toLowerCase())
  )
  const paginated = filtered.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)

  // ─── Render ───────────────────────────────────────────────────────────
  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 6 }}>

      {/* ── Page Header ── */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', flexWrap: 'wrap', gap: 4 }}>
        <Box>
          <Typography variant='h4' fontWeight='900' color='primary' className='tracking-tight' gutterBottom>
            Kelola Testimoni Pelanggan
          </Typography>
          <Typography variant='body2' className='text-[var(--mui-palette-text-secondary)] font-medium'>
            Moderasi dan kelola testimoni yang ditampilkan di halaman landing.
          </Typography>
        </Box>
        <Box className='flex gap-3 items-center bg-[var(--mui-palette-background-paper)] p-2 rounded-2xl border border-[var(--mui-palette-divider)]'>
          <Chip
            icon={<i className='ri-chat-heart-line' />}
            label={`${testimonials.length} Total Testimoni`}
            variant='outlined'
            className='font-bold'
          />
          <Button
            variant='contained'
            size='small'
            startIcon={<i className='ri-add-circle-line' />}
            onClick={handleOpenCreate}
            sx={{ borderRadius: '10px', fontWeight: 700, textTransform: 'none', px: 3 }}
          >
            Tambah Testimoni
          </Button>
        </Box>
      </Box>

      {/* ── Filter Card ── */}
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

      {/* ── Table Card ── */}
      <Card sx={{ border: 'none', borderRadius: '1.5rem', boxShadow: '0 4px 20px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
        <TableContainer component={Paper} elevation={0}>
          {loading ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', p: 15, gap: 4 }}>
              <CircularProgress size={48} thickness={4} />
              <Typography variant='caption' className='font-bold uppercase tracking-widest text-slate-400'>Memuat Testimoni...</Typography>
            </Box>
          ) : (
            <Table sx={{ minWidth: 800 }}>
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase' }}>Pelanggan</TableCell>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase' }}>Rating & Isi</TableCell>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase' }}>Status</TableCell>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase' }}>Tanggal</TableCell>
                  <TableCell align='center' sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase' }}>Aksi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginated.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} align='center' sx={{ py: 15 }}>
                      <Box className='flex flex-col items-center gap-2 opacity-30'>
                        <i className='ri-chat-history-line text-6xl' />
                        <Typography className='font-bold'>Tidak ada testimoni yang ditemukan.</Typography>
                      </Box>
                    </TableCell>
                  </TableRow>
                ) : paginated.map((row) => (
                  <TableRow hover key={row.id}>
                    {/* Avatar + Nama */}
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Avatar
                          src={formatImageUrl(row.photo_url) || `/images/avatars/${(testimonials.indexOf(row) % 8) + 1}.png`}
                          sx={{ mr: 4, width: 44, height: 44, border: '2px solid var(--mui-palette-divider)' }}
                        >
                          {row.name.charAt(0)}
                        </Avatar>
                        <Typography variant='body2' fontWeight='900' color='text.primary'>{row.name}</Typography>
                      </Box>
                    </TableCell>

                    {/* Rating + Deskripsi */}
                    <TableCell sx={{ maxWidth: 400 }}>
                      <Rating value={row.rating} readOnly size='small' sx={{ mb: 1 }} />
                      <Typography variant='body2' className='font-medium line-clamp-2' sx={{ display: 'block' }}>
                        {row.description}
                      </Typography>
                    </TableCell>

                    {/* Status */}
                    <TableCell>
                      <Chip
                        size='small'
                        label={row.is_approved ? 'Tayang' : 'Pending'}
                        color={row.is_approved ? 'success' : 'warning'}
                        variant='tonal'
                        sx={{ fontWeight: 700 }}
                      />
                    </TableCell>

                    {/* Tanggal */}
                    <TableCell>
                      <Typography variant='body2' className='font-bold text-slate-600'>{formatFullDate(row.created_at)}</Typography>
                    </TableCell>

                    {/* Aksi */}
                    <TableCell align='center'>
                      <Box className='flex justify-center gap-2'>
                        <Tooltip title='Hapus Testimoni'>
                          <IconButton
                            size='small'
                            color='error'
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
          count={filtered.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage='Baris per halaman:'
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} dari ${count !== -1 ? count : `lebih dari ${to}`}`}
        />
      </Card>

      {/* ── Create Testimonial Dialog ── */}
      <Dialog
        open={openCreate}
        onClose={handleCloseCreate}
        maxWidth='sm'
        fullWidth
        PaperProps={{ sx: { borderRadius: '1.5rem', p: 1 } }}
      >
        <DialogTitle sx={{ fontWeight: 900, fontSize: '1.2rem', pb: 1 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <i className='ri-chat-heart-line text-primary text-2xl' />
            Tambah Testimoni Baru
          </Box>
        </DialogTitle>
        <Divider />
        <DialogContent sx={{ pt: 4, display: 'flex', flexDirection: 'column', gap: 4 }}>

          {/* Foto Profil Otomatis */}
          <Alert
            icon={
              <Avatar
                src={formatImageUrl(adminProfile?.photo_url)}
                sx={{ width: 36, height: 36 }}
              >
                {adminProfile?.name?.charAt(0)}
              </Avatar>
            }
            severity='info'
            variant='outlined'
            sx={{ borderRadius: '12px', alignItems: 'center' }}
          >
            <Typography variant='body2' fontWeight={700}>
              Foto profil Anda akan otomatis digunakan sebagai foto testimoni.
            </Typography>
            <Typography variant='caption' color='text.secondary'>
              Untuk mengubah foto, perbarui foto profil Anda terlebih dahulu di menu Profil.
            </Typography>
          </Alert>

          {/* Nama */}
          <TextField
            label='Nama Pelanggan'
            required
            fullWidth
            value={form.name}
            onChange={e => setForm(p => ({ ...p, name: e.target.value }))}
            placeholder='Contoh: Budi Santoso'
            InputProps={{ sx: { borderRadius: '12px' } }}
          />

          {/* Rating */}
          <Box>
            <Typography variant='body2' fontWeight={700} sx={{ mb: 1 }}>
              Rating Kepuasan <span style={{ color: 'red' }}>*</span>
            </Typography>
            <Rating
              value={form.rating}
              onChange={(_, val) => setForm(p => ({ ...p, rating: val ?? 0 }))}
              size='large'
            />
            {form.rating > 0 && (
              <Typography variant='caption' color='text.secondary' sx={{ ml: 1 }}>
                {form.rating} Bintang
              </Typography>
            )}
          </Box>

          {/* Deskripsi */}
          <TextField
            label='Isi Ulasan'
            required
            fullWidth
            multiline
            rows={4}
            value={form.description}
            onChange={e => setForm(p => ({ ...p, description: e.target.value }))}
            placeholder='Tuliskan ulasan pelanggan...'
            InputProps={{ sx: { borderRadius: '12px' } }}
          />
        </DialogContent>

        <DialogActions sx={{ px: 6, pb: 4, gap: 2 }}>
          <Button
            onClick={handleCloseCreate}
            variant='outlined'
            disabled={isSubmitting}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 700 }}
          >
            Batal
          </Button>
          <Button
            onClick={handleSubmitCreate}
            variant='contained'
            disabled={isSubmitting}
            startIcon={isSubmitting ? <CircularProgress size={16} color='inherit' /> : <i className='ri-send-plane-2-line' />}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 700, px: 4 }}
          >
            {isSubmitting ? 'Menyimpan...' : 'Simpan Testimoni'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* ── Delete Confirmation ── */}
      <ConfirmDialog
        open={deleteConfirmId !== null}
        onClose={() => setDeleteConfirmId(null)}
        onConfirm={handleDelete}
        title='Hapus Testimoni?'
        message='Tindakan ini tidak dapat dibatalkan. Testimoni akan dihapus secara permanen dari sistem dan landing page.'
        type='error'
        confirmText='Ya, Hapus'
      />
    </Box>
  )
}

export default TestimonialList
