"use client"
// src/views/karyawan/PositionAssignModal.tsx
import React, { useEffect, useState } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
  CircularProgress,
  Box,
  Radio
} from '@mui/material'
import { employeeService, Position } from '../../libs/employeeService'
import { useNotification } from '../../contexts/NotificationContext'

interface Props {
  open: boolean
  onClose: () => void
  onAssign: (positionId: string) => void
  currentPositionId?: string
  employeeName: string
}

const PositionAssignModal = ({ open, onClose, onAssign, currentPositionId, employeeName }: Props) => {
  const { showNotification } = useNotification()
  const [positions, setPositions] = useState<Position[]>([])
  const [loading, setLoading] = useState(false)
  const [selectedId, setSelectedId] = useState(currentPositionId || '')

  useEffect(() => {
    if (open) {
      loadPositions()
      setSelectedId(currentPositionId || '')
    }
  }, [open, currentPositionId])

  const loadPositions = async () => {
    setLoading(true)
    try {
      const data = await employeeService.getPositions()
      setPositions(data)
    } catch (error) {
      console.error(error)
      showNotification('Gagal memuat daftar jabatan.', 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleSave = () => {
    onAssign(selectedId)
  }

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth='xs'>
      <DialogTitle>
        Set Jabatan Karyawan
        <Typography variant='body2' color='textSecondary'>
          {employeeName}
        </Typography>
      </DialogTitle>
      <DialogContent dividers>
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
            <CircularProgress size={32} />
          </Box>
        ) : (
          <List sx={{ pt: 0 }}>
            {/* Opsi Kosongkan Jabatan */}
            <ListItem disablePadding>
              <ListItemButton onClick={() => setSelectedId('')} selected={selectedId === ''}>
                <ListItemIcon>
                  <Radio checked={selectedId === ''} color='primary' size='small' />
                </ListItemIcon>
                <ListItemText primary='Tidak ada jabatan' secondary='-' />
              </ListItemButton>
            </ListItem>
            
            {positions.map((pos) => (
              <ListItem key={pos.id} disablePadding>
                <ListItemButton onClick={() => setSelectedId(pos.id)} selected={selectedId === pos.id}>
                  <ListItemIcon>
                    <Radio checked={selectedId === pos.id} color='primary' size='small' />
                  </ListItemIcon>
                  <ListItemText 
                    primary={pos.name} 
                    secondary={`Rp ${pos.salary.toLocaleString('id-ID')}`} 
                  />
                </ListItemButton>
              </ListItem>
            ))}
          </List>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} color='secondary'>Batal</Button>
        <Button onClick={handleSave} variant='contained' disabled={loading}>Simpan Perubahan</Button>
      </DialogActions>
    </Dialog>
  )
}

export default PositionAssignModal
