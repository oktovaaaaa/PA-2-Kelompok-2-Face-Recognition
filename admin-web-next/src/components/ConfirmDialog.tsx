// src/components/ConfirmDialog.tsx
'use client'

import React from 'react'

import Dialog from '@mui/material/Dialog'
import DialogTitle from '@mui/material/DialogTitle'
import DialogContent from '@mui/material/DialogContent'
import DialogActions from '@mui/material/DialogActions'
import Button from '@mui/material/Button'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import CircularProgress from '@mui/material/CircularProgress'


interface ConfirmDialogProps {
  open: boolean
  onClose: () => void
  onConfirm: () => void
  title: string
  message: string
  type?: 'warning' | 'error' | 'info'
  confirmText?: string
  cancelText?: string
  loading?: boolean
}


const ConfirmDialog = ({
  open,
  onClose,
  onConfirm,
  title,
  message,
  type = 'warning',
  confirmText = 'Ya, Lanjutkan',
  cancelText = 'Batal',
  loading = false
}: ConfirmDialogProps) => {

  const getIcon = () => {
    switch (type) {
      case 'error': return <i className="ri-delete-bin-7-line text-5xl text-red-500 mb-2" />
      case 'info': return <i className="ri-information-line text-5xl text-blue-500 mb-2" />
      default: return <i className="ri-alert-line text-5xl text-orange-500 mb-2" />
    }
  }

  const getButtonColor = () => {
    switch (type) {
      case 'error': return 'error'
      case 'info': return 'info'
      default: return 'primary'
    }
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth PaperProps={{ sx: { borderRadius: 3, p: 2 } }}>
      <DialogContent sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', pt: 6 }}>
        {getIcon()}
        <Typography variant="h5" fontWeight="bold" sx={{ mt: 2, mb: 2 }}>{title}</Typography>
        <Typography color="text.secondary">{message}</Typography>
      </DialogContent>
      <DialogActions sx={{ justifyContent: 'center', pb: 6, gap: 2 }}>
        <Button onClick={onClose} variant="outlined" color="secondary" sx={{ minWidth: 100 }}>{cancelText}</Button>
        <Button 
          onClick={() => { onConfirm(); onClose(); }} 
          variant="contained" 
          color={getButtonColor()} 
          sx={{ minWidth: 100 }}
          autoFocus
          disabled={loading}
          startIcon={loading ? <CircularProgress size={16} color="inherit" /> : null}
        >
          {loading ? 'Memproses...' : confirmText}
        </Button>

      </DialogActions>
    </Dialog>
  )
}

export default ConfirmDialog
