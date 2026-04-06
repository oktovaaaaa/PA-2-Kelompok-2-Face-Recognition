// src/views/account-settings/account/AccountDelete.tsx
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Button from '@mui/material/Button'
import Typography from '@mui/material/Typography'
import TextField from '@mui/material/TextField'
import Box from '@mui/material/Box'
import Alert from '@mui/material/Alert'
import Dialog from '@mui/material/Dialog'
import DialogTitle from '@mui/material/DialogTitle'
import DialogContent from '@mui/material/DialogContent'
import DialogActions from '@mui/material/DialogActions'
import CircularProgress from '@mui/material/CircularProgress'
import Divider from '@mui/material/Divider'

import { settingService } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'

const AccountDelete = () => {
  const router = useRouter()
  const { showNotification } = useNotification()

  // Step states
  const [step1Open, setStep1Open] = useState(false)
  const [step2Open, setStep2Open] = useState(false)
  const [step3Open, setStep3Open] = useState(false)

  const [password, setPassword] = useState('')
  const [phrase, setPhrase] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleStep1Confirm = () => {
    setStep1Open(false)
    setTimeout(() => setStep2Open(true), 300)
  }

  const handleStep2Confirm = () => {
    if (!password.trim()) {
      setError('Password tidak boleh kosong')
      return
    }
    setError('')
    setStep2Open(false)
    setTimeout(() => setStep3Open(true), 300)
  }

  const handleFinalDelete = async () => {
    if (phrase !== 'SAYA YAKIN') {
      setError('Frasa konfirmasi harus persis: SAYA YAKIN')
      return
    }
    setError('')
    setLoading(true)

    try {
      await settingService.deleteAdminAccount(password, phrase)
      showNotification('Akun Anda telah berhasil dihapus secara permanen.', 'success')
      localStorage.removeItem('token')
      router.push('/login')
    } catch (err: any) {
      setError(err.message || 'Gagal menghapus akun.')
      setLoading(false)
    }
  }

  const handleReset = () => {
    setStep1Open(false)
    setStep2Open(false)
    setStep3Open(false)
    setPassword('')
    setPhrase('')
    setError('')
    setLoading(false)
  }

  return (
    <>
      <Card>
        <CardHeader title='Hapus Akun' titleTypographyProps={{ color: 'error.main', fontWeight: '700' }} />
        <Divider />
        <CardContent className='flex flex-col items-start gap-6'>
          <Alert severity='error' variant='outlined' sx={{ width: '100%' }}>
            <Typography variant='body2' fontWeight='600'>
              Menghapus akun bersifat <strong>permanen</strong> dan tidak dapat dibatalkan.
              Seluruh data riwayat absensi, denda, cuti, dan notifikasi Anda akan dihapus secara tuntas dari sistem.
            </Typography>
          </Alert>
          <Button variant='contained' color='error' startIcon={<i className='ri-delete-bin-7-line' />} onClick={() => setStep1Open(true)}>
            Hapus Akun Saya
          </Button>
        </CardContent>
      </Card>

      {/* STEP 1: Konfirmasi Awal */}
      <Dialog open={step1Open} onClose={handleReset} maxWidth='xs' fullWidth>
        <DialogTitle sx={{ fontWeight: '700', color: 'warning.main' }}>
          <Box className='flex items-center gap-3'>
            <i className='ri-error-warning-fill text-2xl' />
            Peringatan Penghapusan Akun
          </Box>
        </DialogTitle>
        <Divider />
        <DialogContent>
          <Typography variant='body2' sx={{ mt: 2 }}>
            Anda akan menghapus akun admin Anda secara <strong>permanen</strong>.
            Tindakan ini <strong>tidak dapat dibatalkan</strong>. Semua data pribadi, riwayat absensi, denda, dan catatan lainnya akan hilang selamanya.
          </Typography>
          <Typography variant='body2' sx={{ mt: 2, fontWeight: '700' }}>
            Apakah Anda yakin ingin melanjutkan?
          </Typography>
        </DialogContent>
        <DialogActions sx={{ px: 6, pb: 4 }}>
          <Button onClick={handleReset} variant='outlined'>Batalkan</Button>
          <Button onClick={handleStep1Confirm} variant='contained' color='warning'>Ya, Lanjutkan</Button>
        </DialogActions>
      </Dialog>

      {/* STEP 2: Verifikasi Password */}
      <Dialog open={step2Open} onClose={handleReset} maxWidth='xs' fullWidth>
        <DialogTitle sx={{ fontWeight: '700', color: 'error.main' }}>
          <Box className='flex items-center gap-3'>
            <i className='ri-lock-password-fill text-2xl' />
            Verifikasi Password
          </Box>
        </DialogTitle>
        <Divider />
        <DialogContent>
          <Typography variant='body2' sx={{ mt: 2, mb: 4 }}>
            Untuk keamanan, masukkan <strong>password akun</strong> Anda untuk membuktikan identitas Anda.
          </Typography>
          <TextField
            fullWidth type='password' label='Masukkan Password Anda'
            value={password}
            onChange={e => { setPassword(e.target.value); setError('') }}
            error={!!error}
            helperText={error}
            autoFocus
          />
        </DialogContent>
        <DialogActions sx={{ px: 6, pb: 4 }}>
          <Button onClick={handleReset} variant='outlined'>Batalkan</Button>
          <Button onClick={handleStep2Confirm} variant='contained' color='error'>Verifikasi</Button>
        </DialogActions>
      </Dialog>

      {/* STEP 3: Ketik "SAYA YAKIN" */}
      <Dialog open={step3Open} onClose={handleReset} maxWidth='xs' fullWidth>
        <DialogTitle sx={{ fontWeight: '700', color: 'error.main' }}>
          <Box className='flex items-center gap-3'>
            <i className='ri-skull-2-fill text-2xl' />
            Konfirmasi Terakhir
          </Box>
        </DialogTitle>
        <Divider />
        <DialogContent>
          <Alert severity='error' sx={{ mb: 4, mt: 2 }}>
            Ini adalah langkah terakhir yang tidak dapat diurungkan.
          </Alert>
          <Typography variant='body2' sx={{ mb: 4 }}>
            Ketik <strong style={{ letterSpacing: '2px' }}>SAYA YAKIN</strong> pada kotak di bawah untuk menghapus akun Anda secara permanen.
          </Typography>
          <TextField
            fullWidth label='Ketik "SAYA YAKIN"' placeholder='SAYA YAKIN'
            value={phrase}
            onChange={e => { setPhrase(e.target.value); setError('') }}
            error={!!error}
            helperText={error}
            autoFocus
          />
        </DialogContent>
        <DialogActions sx={{ px: 6, pb: 4 }}>
          <Button onClick={handleReset} variant='outlined'>Batalkan</Button>
          <Button
            onClick={handleFinalDelete} variant='contained' color='error'
            disabled={loading || phrase !== 'SAYA YAKIN'}
            startIcon={loading ? <CircularProgress size={16} color='inherit' /> : <i className='ri-delete-bin-7-line' />}
          >
            {loading ? 'Menghapus...' : 'Hapus Akun Permanen'}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

export default AccountDelete
