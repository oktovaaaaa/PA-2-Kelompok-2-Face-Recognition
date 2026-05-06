// src/views/cuti/LeaveRequestModal.tsx
'use client'

import React, { useState, useEffect } from 'react'

import Dialog from '@mui/material/Dialog'
import DialogTitle from '@mui/material/DialogTitle'
import DialogContent from '@mui/material/DialogContent'
import DialogActions from '@mui/material/DialogActions'
import Button from '@mui/material/Button'
import TextField from '@mui/material/TextField'
import MenuItem from '@mui/material/MenuItem'
import Grid from '@mui/material/Grid'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'
import Autocomplete from '@mui/material/Autocomplete'

import { format } from 'date-fns'

import type { Employee } from '@/libs/employeeService';
import { employeeService } from '@/libs/employeeService'


import { useNotification } from '@/contexts/NotificationContext'

interface Props {
  open: boolean
  onClose: () => void
  selectedDate: Date | null
  onSubmit: (data: any) => void
}

const LeaveRequestModal = ({ open, onClose, selectedDate, onSubmit }: Props) => {
  const { showNotification } = useNotification()
  const [employees, setEmployees] = useState<Employee[]>([])

  const [formData, setFormData] = useState({
    user_id: '',
    type: 'IZIN',
    title: '',
    description: '',
    date: selectedDate ? format(selectedDate, 'yyyy-MM-dd') : format(new Date(), 'yyyy-MM-dd'),
    status: 'APPROVED'
  })

  useEffect(() => {
    if (open) {
      employeeService.getEmployees('ACTIVE')
        .then(setEmployees)
        .catch(err => {
          console.error("Gagal mengambil karyawan:", err)
          showNotification('Gagal memuat daftar karyawan.', 'error')
        })

      if (selectedDate) {
        setFormData(prev => ({ ...prev, date: format(selectedDate, 'yyyy-MM-dd') }))
      }
    }
  }, [open, selectedDate])

  const handleChange = (e: React.ChangeEvent<any>) => {
    const { name, value } = e.target

    setFormData(prev => ({ ...prev, [name]: value }))
  }

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth='sm'>
      <DialogTitle sx={{ pb: 0 }}>
        <Typography variant='h6' fontWeight='600'>Tambah Izin Baru</Typography>
        <Typography variant='caption' color='text.secondary'>Admin menambahkan izin untuk karyawan</Typography>
      </DialogTitle>
      
      <DialogContent sx={{ pt: 4 }}>
        <Grid container spacing={4} sx={{ mt: 1 }}>
          <Grid item xs={12}>
            <Autocomplete
              fullWidth
              size="small"
              options={employees}
              getOptionLabel={(option) => option.name ? `${option.name} (${option.position_name || 'No Position'})` : ''}
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
          
          <Grid item xs={12} sm={6}>
            <TextField
              select
              fullWidth
              label="Tipe Izin"
              name="type"
              value={formData.type}
              onChange={handleChange}
              size='small'
            >
              <MenuItem value="IZIN">IZIN</MenuItem>
              <MenuItem value="SAKIT">SAKIT</MenuItem>
              <MenuItem value="CUTI">CUTI</MenuItem>
            </TextField>
          </Grid>

          <Grid item xs={12} sm={6}>
             <TextField
              fullWidth
              type="date"
              label="Tanggal"
              name="date"
              value={formData.date}
              onChange={handleChange}
              size='small'
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Judul / Subjek"
              name="title"
              placeholder="Wajib diisi (Contoh: Izin Kedukaan)"
              value={formData.title}
              onChange={handleChange}
              size='small'
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Keterangan"
              name="description"
              value={formData.description}
              onChange={handleChange}
              size='small'
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              select
              fullWidth
              label="Status Akhir"
              name="status"
              value={formData.status}
              onChange={handleChange}
              size='small'
            >
              <MenuItem value="PENDING">Menunggu (Draf)</MenuItem>
              <MenuItem value="APPROVED">Langsung Disetujui</MenuItem>
            </TextField>
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions sx={{ p: 4, pt: 0 }}>
        <Button onClick={onClose} color='secondary'>Batal</Button>
        <Button 
            variant='contained' 
            color='primary' 
            onClick={() => onSubmit(formData)}
            disabled={!formData.user_id || !formData.title}
        >
            Simpan Izin
        </Button>
      </DialogActions>
    </Dialog>
  )
}

export default LeaveRequestModal
