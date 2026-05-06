"use client"

// src/views/jabatan/PositionFormModal.tsx
import React, { useEffect, useState } from 'react'

import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  InputAdornment,
  CircularProgress
} from '@mui/material'

import type { Position} from '../../libs/employeeService';
import { employeeService } from '../../libs/employeeService'
import { useNotification } from '../../contexts/NotificationContext'

interface Props {
  open: boolean
  onClose: () => void
  position: Position | null
  onSuccess: () => void
}

const PositionFormModal = ({ open, onClose, position, onSuccess }: Props) => {
  const { showNotification } = useNotification()
  const [name, setName] = useState('')
  const [salary, setSalary] = useState('')
  const [description, setDescription] = useState('')
  const [loading, setLoading] = useState(false)

  const isEdit = !!position

  useEffect(() => {
    if (open) {
      if (position) {
        setName(position.name)
        setSalary(position.salary.toString())
        setDescription(position.description || '')
      } else {
        setName('')
        setSalary('')
        setDescription('')
      }
    }
  }, [open, position])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!name || !salary) {
      showNotification('Nama dan Gaji wajib diisi', 'warning')
      
return
    }

    setLoading(true)

    try {
      if (isEdit) {
        await employeeService.updatePosition(position.id, { 
          name, 
          salary: Number(salary.replace(/\./g, '')),
          description: description 
        })
        showNotification('Jabatan berhasil diperbarui', 'success')
      } else {
        await employeeService.createPosition({ 
          name, 
          salary: Number(salary.replace(/\./g, '')),
          description: description 
        })
        showNotification('Jabatan baru berhasil ditambahkan', 'success')
      }

      onSuccess()
      onClose()
    } catch (error: any) {
      showNotification(error.message || 'Terjadi kesalahan sistem', 'error')
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth='xs'>
      <DialogTitle fontWeight='700'>
        {isEdit ? 'Edit Jabatan' : 'Tambah Jabatan Baru'}
      </DialogTitle>
      <form onSubmit={handleSubmit}>
        <DialogContent dividers>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            <Box>
                <Typography variant='caption' fontWeight='700' color='textSecondary' sx={{ mb: 1, display: 'block' }}>
                    NAMA JABATAN
                </Typography>
                <TextField
                    fullWidth
                    size='small'
                    placeholder='Contoh: Project Manager, HR Staff'
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    autoFocus
                />
            </Box>

            <Box>
                <Typography variant='caption' fontWeight='700' color='textSecondary' sx={{ mb: 1, display: 'block' }}>
                    GAJI POKOK
                </Typography>
                <TextField
                    fullWidth
                    size='small'
                    type='text'
                    placeholder='Contoh: 5.000.000'
                    value={salary === '0' ? '' : salary}
                    onChange={(e) => {
                        const raw = e.target.value.replace(/[^0-9]/g, '')

                        if (!raw) {
                            setSalary('')
                            
return
                        }

                        const num = parseInt(raw, 10)

                        setSalary(num.toLocaleString('id-ID'))
                    }}
                    InputProps={{
                        startAdornment: <InputAdornment position="start">Rp</InputAdornment>,
                    }}
                />
            </Box>

            <Box>
                <Typography variant='caption' fontWeight='700' color='textSecondary' sx={{ mb: 1, display: 'block' }}>
                    DESKRIPSI JABATAN (OPSIONAL)
                </Typography>
                <TextField
                    fullWidth
                    size='small'
                    multiline
                    rows={3}
                    placeholder='Jelaskan tugas dan tanggung jawab jabatan ini...'
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                />
            </Box>
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 4 }}>
          <Button onClick={onClose} disabled={loading} color='secondary'>Batal</Button>
          <Button 
            type='submit' 
            variant='contained' 
            disabled={loading}
            startIcon={loading && <CircularProgress size={16} color='inherit' />}
          >
            {isEdit ? 'Simpan Perubahan' : 'Tambah Jabatan'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  )
}

export default PositionFormModal
