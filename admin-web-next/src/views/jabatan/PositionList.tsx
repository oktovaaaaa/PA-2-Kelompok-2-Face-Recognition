"use client"

// src/views/jabatan/PositionList.tsx
import React, { useEffect, useState, useCallback } from 'react'

import {
  Card,
  Typography,
  Button,
  IconButton,
  TextField,
  InputAdornment,
  Box,
  Grid,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Tooltip,
  Paper,
  Stack,
  CardContent,
  Divider
} from '@mui/material'

import type { Position } from '../../libs/employeeService';
import { employeeService } from '../../libs/employeeService'
import { useNotification } from '../../contexts/NotificationContext'
import PositionFormModal from './PositionFormModal'

const PositionList = () => {
  const { showNotification } = useNotification()
  const [positions, setPositions] = useState<Position[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  
  // Modal States
  const [selectedPosition, setSelectedPosition] = useState<Position | null>(null)
  const [isFormOpen, setIsFormOpen] = useState(false)
  const [isDeleteConfirmOpen, setIsDeleteConfirmOpen] = useState(false)

  const loadData = useCallback(async () => {
    setLoading(true)

    try {
      const data = await employeeService.getPositions()

      setPositions(data || [])
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData()
  }, [loadData])

  const handleEdit = (pos: Position) => {
    setSelectedPosition(pos)
    setIsFormOpen(true)
  }

  const handleDeleteClick = (pos: Position) => {
    setSelectedPosition(pos)
    setIsDeleteConfirmOpen(true)
  }

  const confirmDelete = async () => {
    if (!selectedPosition) return

    try {
      await employeeService.deletePosition(selectedPosition.id)
      showNotification('Jabatan berhasil dihapus', 'success')
      loadData()
      setIsDeleteConfirmOpen(false)
    } catch (error: any) {
      showNotification(error.message || 'Gagal menghapus jabatan', 'error')
      console.error(error)
    }
  }

  const filteredPositions = positions.filter(pos => 
    pos.name.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      maximumFractionDigits: 0
    }).format(amount)
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {/* Premium Header Section */}
      <Paper 
        elevation={0}
        sx={{ 
          p: 6, 
          borderRadius: 3,
          background: 'linear-gradient(135deg, #0F172A 0%, #1E3A8A 50%, #2563EB 100%)',
          color: 'white',
          position: 'relative',
          overflow: 'hidden'
        }}
      >
        <Box sx={{ position: 'relative', zIndex: 2 }}>
            <Typography variant='h4' fontWeight='800' gutterBottom sx={{ color: 'common.white' }}>
                Manajemen Jabatan
            </Typography>
            <Typography variant='body1' sx={{ opacity: 0.8, mb: 6, maxWidth: 600, color: 'common.white' }}>
                Kelola struktur jabatan, tingkatan karir, dan besaran gaji pokok karyawan dalam perusahaan secara efisien.
            </Typography>
            
            <Stack direction='row' spacing={4} sx={{ mt: 2 }}>
                <Box sx={{ bgcolor: 'rgba(255,255,255,0.1)', px: 4, py: 2, borderRadius: 2 }}>
                    <Typography variant='h5' fontWeight='700' sx={{ color: 'common.white' }}>{positions.length}</Typography>
                    <Typography variant='caption' sx={{ color: 'rgba(255,255,255,0.7)' }}>Total Jabatan</Typography>
                </Box>
                <Button 
                    variant='contained' 
                    color='inherit'
                    onClick={() => { setSelectedPosition(null); setIsFormOpen(true); }}
                    startIcon={<i className='ri-add-line' />}
                    sx={{ 
                        bgcolor: 'background.paper', 
                        color: 'primary.main', 
                        fontWeight: '700',
                        '&:hover': { bgcolor: 'action.hover' }
                    }}
                >
                    Tambah Jabatan
                </Button>
            </Stack>
        </Box>
        {/* Decorative Circles */}
        <Box sx={{ position: 'absolute', right: -50, top: -50, width: 200, height: 200, borderRadius: '50%', background: 'rgba(255,255,255,0.05)' }} />
        <Box sx={{ position: 'absolute', right: 100, bottom: -80, width: 150, height: 150, borderRadius: '50%', background: 'rgba(255,255,255,0.03)' }} />
      </Paper>

      {/* Filter & Search Bar */}
      <Card sx={{ p: 4, display: 'flex', alignItems: 'center', gap: 4 }}>
          <TextField
            size='small'
            placeholder='Cari Jabatan...'
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            sx={{ flex: 1 }}
            InputProps={{
              startAdornment: (
                <InputAdornment position='start'>
                  <i className='ri-search-line' />
                </InputAdornment>
              )
            }}
          />
          <IconButton onClick={loadData} color='primary'>
              <i className='ri-refresh-line' />
          </IconButton>
      </Card>

      {/* List Content */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 10 }}>
          <CircularProgress size={40} />
        </Box>
      ) : (
        <Grid container spacing={5}>
          {filteredPositions.length === 0 ? (
            <Grid item xs={12}>
                <Paper sx={{ p: 10, textAlign: 'center', bgcolor: theme => theme.palette.action.hover }}>
                    <Typography color='textSecondary'>Data jabatan tidak ditemukan.</Typography>
                </Paper>
            </Grid>
          ) : filteredPositions.map((pos) => (
            <Grid item xs={12} sm={6} md={4} key={pos.id}>
              <Card 
                sx={{ 
                    height: '100%', 
                    borderRadius: 3,
                    transition: 'all 0.3s',
                    '&:hover': { transform: 'translateY(-5px)', boxShadow: 10 },
                    position: 'relative',
                    overflow: 'visible'
                }}
              >
                <CardContent sx={{ p: 5 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 4, mb: 4 }}>
                    <Box sx={{ 
                        p: 3, 
                        borderRadius: 2, 
                        background: 'linear-gradient(45deg, #1E3A8A, #2563EB)',
                        color: 'white'
                    }}>
                        <i className='ri-briefcase-line' style={{ fontSize: '24px' }} />
                    </Box>
                    <Box>
                        <Typography variant='h6' fontWeight='700'>{pos.name}</Typography>
                        <Typography variant='caption' color='textSecondary'>Gaji Pokok</Typography>
                    </Box>
                  </Box>

                  <Typography variant='h5' fontWeight='800' color='primary' sx={{ mb: 2 }}>
                    {formatCurrency(pos.salary)}
                  </Typography>

                  {pos.description ? (
                    <Typography 
                      variant='body2' 
                      color='textSecondary' 
                      sx={{ 
                        mb: 4, 
                        display: '-webkit-box', 
                        WebkitLineClamp: 2, 
                        WebkitBoxOrient: 'vertical', 
                        overflow: 'hidden',
                        height: '40px',
                        lineHeight: '20px'
                      }}
                    >
                      {pos.description}
                    </Typography>
                  ) : (
                    <Typography variant='body2' color='text.disabled' fontStyle='italic' sx={{ mb: 4, height: '40px' }}>
                        Tidak ada deskripsi.
                    </Typography>
                  )}

                  <Divider sx={{ my: 4, borderStyle: 'dashed' }} />

                  <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
                    <Tooltip title="Edit Jabatan">
                        <IconButton size='small' color='primary' onClick={() => handleEdit(pos)}>
                            <i className='ri-edit-2-line' />
                        </IconButton>
                    </Tooltip>
                    <Tooltip title="Hapus Jabatan">
                        <IconButton size='small' color='error' onClick={() => handleDeleteClick(pos)}>
                            <i className='ri-delete-bin-line' />
                        </IconButton>
                    </Tooltip>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Modals */}
      <PositionFormModal 
        open={isFormOpen}
        onClose={() => setIsFormOpen(false)}
        position={selectedPosition}
        onSuccess={loadData}
      />

      <Dialog open={isDeleteConfirmOpen} onClose={() => setIsDeleteConfirmOpen(false)}>
        <DialogTitle>Konfirmasi Hapus</DialogTitle>
        <DialogContent dividers>
            <Typography>
                Apakah Anda yakin ingin menghapus jabatan <b>{selectedPosition?.name}</b>?
            </Typography>
            <Typography variant='caption' color='error' sx={{ mt: 2, display: 'block' }}>
                *Jabatan tidak dapat dihapus jika masih ada karyawan yang menggunakannya.
            </Typography>
        </DialogContent>
        <DialogActions>
            <Button onClick={() => setIsDeleteConfirmOpen(false)} color='secondary'>Batal</Button>
            <Button onClick={confirmDelete} variant='contained' color='error'>Hapus Sekarang</Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default PositionList
