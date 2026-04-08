// src/views/payroll/SalaryDetailModal.tsx
'use client'

import React, { useState, useEffect } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Grid,
  Typography,
  Divider,
  Box,
  TextField,
  IconButton,
  Alert,
  Avatar,
  Chip
} from '@mui/material'
import { payrollService, Salary } from '@/libs/payrollService'
import { useNotification } from '@/contexts/NotificationContext'
import { formatFullDate, formatDateInString } from '@/utils/dateFormatter'

interface Props {
  open: boolean
  onClose: () => void
  salary: Salary | null
  onSuccess: () => void
}

const SalaryDetailModal = ({ open, onClose, salary, onSuccess }: Props) => {
  const { showNotification } = useNotification()
  const [payAmount, setPayAmount] = useState<string>('')
  const [proofFile, setProofFile] = useState<File | null>(null)
  const [loading, setLoading] = useState(false)

  const balance = salary ? (salary.total_salary - salary.paid_amount) : 0

  useEffect(() => {
    if (open && salary) {
        setPayAmount((salary.total_salary - salary.paid_amount).toString())
        setProofFile(null)
    }
  }, [open, salary])

  const formatIDR = (amount: number) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(amount)
  }

  const parseDeductions = (detail: string) => {
    if (!detail) return []
    // Also use the date formatting utility to clean up any nested dates
    const formattedDetail = formatDateInString(detail)
    return formattedDetail.split(';').filter(d => d.trim() !== '')
  }

  const handlePay = async () => {
    if (!salary || !payAmount) return
    const amountNum = parseFloat(payAmount)
    if (isNaN(amountNum) || amountNum <= 0) return showNotification('Nominal bayar tidak valid.', 'error')
    if (amountNum > balance) return showNotification('Nominal melebihi sisa sisa saldo.', 'error')

    setLoading(true)
    try {
      await payrollService.paySalary(salary.id, payAmount, proofFile || undefined)
      showNotification('Pembayaran berhasil dicatatkan!', 'success')
      onSuccess()
      onClose()
    } catch (error: any) {
      showNotification(error.message || 'Gagal memproses pembayaran.', 'error')
    } finally {
      setLoading(false)
    }
  }

  if (!salary) return null

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle sx={{ pb: 0 }}>
        <Typography variant="h6" fontWeight="800">Rincian & Pembayaran Gaji</Typography>
        <Typography variant="caption" color="text.secondary">Periode: {['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'][salary.month]} {salary.year}</Typography>
      </DialogTitle>
      
      <DialogContent sx={{ pt: 4 }}>
        <Box sx={{ p: 4, bgcolor: 'background.default', borderRadius: 2, mb: 4, display: 'flex', alignItems: 'center', gap: 4 }}>
          <Avatar 
                src={salary.user?.photo_url ? `http://localhost:8080${salary.user.photo_url}` : undefined}
                sx={{ width: 44, height: 44 }}
            >
                {salary.user?.name?.charAt(0)}
            </Avatar>
            <Box>
                <Typography variant="subtitle1" fontWeight="700">{salary.user.name}</Typography>
                <Typography variant="body2" color="text.secondary">{salary.user?.position?.name || 'Staf'}</Typography>
            </Box>
        </Box>

        {/* 1. Salary Summary */}
        <Typography variant="overline" color="text.secondary" fontWeight="700">Rincian Nominal</Typography>
        <Box sx={{ mt: 2, mb: 4 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1.5 }}>
                <Typography variant="body2">Gaji Pokok (+)</Typography>
                <Typography variant="body2" fontWeight="600">{formatIDR(salary.base_salary)}</Typography>
            </Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1.5 }}>
                <Typography variant="body2" color="error">Total Potongan (-)</Typography>
                <Typography variant="body2" color="error" fontWeight="600">{formatIDR(salary.deductions)}</Typography>
            </Box>
            <Divider sx={{ my: 2 }} />
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Typography variant="subtitle2" fontWeight="800">Take Home Pay (Total Net)</Typography>
                <Typography variant="subtitle2" fontWeight="800" color="primary">{formatIDR(salary.total_salary)}</Typography>
            </Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 1.5 }}>
                <Typography variant="body2" color="success.main">Sudah Terbayar (+)</Typography>
                <Typography variant="body2" color="success.main" fontWeight="600">{formatIDR(salary.paid_amount)}</Typography>
            </Box>
            <Divider sx={{ my: 2 }} />
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Typography variant="h6" fontWeight="900" color="error.main">Sisa Gaji</Typography>
                <Typography variant="h6" fontWeight="900" color="error.main">{formatIDR(balance)}</Typography>
            </Box>
        </Box>

        {/* 2. Deductions Detail */}
        {salary.deductions > 0 && (
          <Box sx={{ mb: 4 }}>
            <Typography variant="overline" color="text.secondary" fontWeight="700">Detail Pelanggaran</Typography>
            <Box sx={{ mt: 2, pl: 2, borderLeft: '2px solid', borderColor: 'error.main' }}>
                {parseDeductions(salary.deductions_detail).map((item, i) => (
                    <Typography key={i} variant="caption" display="block" color="error.dark" sx={{ mb: 0.5 }}>
                        • {item.trim()}
                    </Typography>
                ))}
            </Box>
          </Box>
        )}

        {/* 3. Bank & Payment History */}
        <Grid container spacing={4} sx={{ mb: 4 }}>
            <Grid item xs={12}>
                <Alert icon={<i className="ri-bank-line" />} severity="info" variant="outlined" sx={{ borderRadius: 2 }}>
                    <Typography variant="caption" fontWeight="700" display="block">Rekening Tujuan:</Typography>
                    <Typography variant="body2">
                        {salary.user.bank_name || 'Bank belum diatur'} - {salary.user.bank_account_number || '-'}
                    </Typography>
                </Alert>
            </Grid>
            {salary.payments && salary.payments.length > 0 && (
              <Grid item xs={12}>
                <Typography variant="overline" color="text.secondary" fontWeight="700">Riwayat Cicilan</Typography>
                {salary.payments.map((p, i) => (
                  <Box key={p.id} sx={{ display: 'flex', justifyContent: 'space-between', mt: 1 }}>
                     <Typography variant="caption">Cicilan ke-{i+1} ({formatFullDate(p.paid_at)})</Typography>
                     <Typography variant="caption" fontWeight="700">{formatIDR(p.amount)}</Typography>
                  </Box>
                ))}
              </Grid>
            )}
        </Grid>

        {/* 4. Payment Form */}
        {salary.status !== 'PAID' && (
          <Box sx={{ p: 4, border: '1px dashed', borderColor: 'divider', borderRadius: 2, bgcolor: 'action.hover' }}>
             <Typography variant="subtitle2" fontWeight="700" sx={{ mb: 2 }}>Proses Pembayaran</Typography>
             <Box sx={{ display: 'flex', gap: 2, mb: 4 }}>
                <TextField 
                    fullWidth size="small" label="Nominal Bayar" type="number"
                    value={payAmount} onChange={(e) => setPayAmount(e.target.value)}
                    InputProps={{ startAdornment: <Typography sx={{ mr: 2, fontSize: '0.875rem' }}>Rp</Typography> }}
                />
                <Button 
                    variant="outlined" size="small" sx={{ whiteSpace: 'nowrap' }}
                    onClick={() => setPayAmount(balance.toString())}
                >
                    Penuh
                </Button>
             </Box>
             
             <Typography variant="caption" fontWeight="700" display="block" sx={{ mb: 1 }}>Unggah Bukti (Opsional)</Typography>
             <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Button
                    component="label" variant="outlined" size="small"
                    startIcon={<i className="ri-upload-line" />}
                >
                    {proofFile ? 'Ganti File' : 'Pilih File'}
                    <input type="file" hidden accept="image/*" onChange={(e) => setProofFile(e.target.files?.[0] || null)} />
                </Button>
                {proofFile && <Typography variant="caption" color="primary">{proofFile.name}</Typography>}
             </Box>
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ p: 4, pt: 0 }}>
        <Button onClick={onClose} color="inherit">Batal</Button>
        {salary.status !== 'PAID' && (
          <Button 
            variant="contained" onClick={handlePay} disabled={loading}
            color={parseFloat(payAmount) >= balance ? 'success' : 'primary'}
          >
            {loading ? 'Memproses...' : (parseFloat(payAmount) >= balance ? 'Konfirmasi Pelunasan' : 'Konfirmasi Cicilan')}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  )
}

export default SalaryDetailModal
