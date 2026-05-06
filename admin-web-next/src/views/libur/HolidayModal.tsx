// src/views/libur/HolidayModal.tsx
'use client'

import React, { useState, useEffect } from 'react'

import Dialog from '@mui/material/Dialog'
import DialogTitle from '@mui/material/DialogTitle'
import DialogContent from '@mui/material/DialogContent'
import DialogActions from '@mui/material/DialogActions'
import Button from '@mui/material/Button'
import TextField from '@mui/material/TextField'
import Grid from '@mui/material/Grid'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'

import { format } from 'date-fns'

import type { Holiday } from '@/libs/holidayService'

interface Props {
  open: boolean
  onClose: () => void
  holiday: Holiday | null
  onSubmit: (data: any) => void
}

const HolidayModal = ({ open, onClose, holiday, onSubmit }: Props) => {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    start_date: format(new Date(), 'yyyy-MM-dd'),
    end_date: format(new Date(), 'yyyy-MM-dd')
  })

  useEffect(() => {
    if (holiday) {
      setFormData({
        name: holiday.name,
        description: holiday.description || '',
        start_date: format(new Date(holiday.start_date), 'yyyy-MM-dd'),
        end_date: format(new Date(holiday.end_date), 'yyyy-MM-dd')
      })
    } else {
      setFormData({
        name: '',
        description: '',
        start_date: format(new Date(), 'yyyy-MM-dd'),
        end_date: format(new Date(), 'yyyy-MM-dd')
      })
    }
  }, [holiday, open])

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target

    setFormData(prev => ({ ...prev, [name]: value }))
  }

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth='sm'>
      <DialogTitle>
        <Typography variant='h6' fontWeight='700'>{holiday ? 'Edit Hari Libur' : 'Tambah Hari Libur Khusus'}</Typography>
        <Typography variant='caption' color='text.secondary'>Masukkan rincian hari libur perusahaan Anda</Typography>
      </DialogTitle>
      
      <DialogContent dividers>
        <Grid container spacing={4} sx={{ mt: 1 }}>
          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Nama Libur"
              name="name"
              placeholder="Contoh: Libur Lebaran / Anniversary Perusahaan"
              value={formData.name}
              onChange={handleChange}
              size='small'
              required
            />
          </Grid>
          
          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              type="date"
              label="Mulai Libur"
              name="start_date"
              value={formData.start_date}
              onChange={handleChange}
              size='small'
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              fullWidth
              type="date"
              label="Selesai Libur"
              name="end_date"
              value={formData.end_date}
              onChange={handleChange}
              size='small'
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Deskripsi / Keterangan"
              name="description"
              placeholder="Berikan info tambahan jika diperlukan..."
              value={formData.description}
              onChange={handleChange}
              size='small'
            />
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions sx={{ p: 4 }}>
        <Button onClick={onClose} color='secondary'>Batal</Button>
        <Button 
            variant='contained' 
            color='primary' 
            onClick={() => onSubmit(formData)}
            disabled={!formData.name}
        >
            {holiday ? 'Simpan Perubahan' : 'Tambahkan Libur'}
        </Button>
      </DialogActions>
    </Dialog>
  )
}

export default HolidayModal
