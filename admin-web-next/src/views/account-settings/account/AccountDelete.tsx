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
import InputAdornment from '@mui/material/InputAdornment'
import IconButton from '@mui/material/IconButton'
import Checkbox from '@mui/material/Checkbox'
import FormControlLabel from '@mui/material/FormControlLabel'

import type { Profile } from '@/libs/settingService';
import { settingService } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'

const AccountDelete = () => {
  const router = useRouter()
  const { showNotification } = useNotification()

  // Step states
  const [step1Open, setStep1Open] = useState(false)
  const [step2Open, setStep2Open] = useState(false)
  const [step3Open, setStep3Open] = useState(false)
  const [step4Open, setStep4Open] = useState(false)
  const [profile, setProfile] = useState<Profile | null>(null)

  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [phrase, setPhrase] = useState('')
  const [loading, setLoading] = useState(false)
  const [verifying, setVerifying] = useState(false)
  const [finalAgreed, setFinalAgreed] = useState(false)
  const [error, setError] = useState('')

  const confirmationPhrase = profile ? `SAYA YAKIN MENGHAPUS AKUN ${profile.name.toUpperCase()}` : 'SAYA YAKIN MENGHAPUS AKUN'

  const fetchProfile = async () => {
    try {
      const data = await settingService.getProfile()

      setProfile(data)
    } catch (err: any) {
      console.error('Gagal mengambil profil:', err.message)
    }
  }

  useState(() => {
    fetchProfile()
  })

  const handleStep1Confirm = () => {
    setStep1Open(false)
    setTimeout(() => setStep2Open(true), 300)
  }

  const handleStep2Confirm = async () => {
    if (!password.trim()) {
      setError('Password tidak boleh kosong')
      
return
    }
    
    setError('')
    setVerifying(true)
    
    try {
      await settingService.verifyPassword(password)
      setStep2Open(false)
      setTimeout(() => setStep3Open(true), 300)
    } catch (err: any) {
      setError(err.message || 'Password yang Anda masukkan salah.')
    } finally {
      setVerifying(false)
    }
  }

  const handleStep3Confirm = () => {
    if (phrase !== confirmationPhrase) {
      setError(`Frasa konfirmasi harus persis: ${confirmationPhrase}`)
      
return
    }

    setError('')
    setStep3Open(false)
    setTimeout(() => setStep4Open(true), 300)
  }

  const handleFinalDelete = async () => {
    if (!finalAgreed) return

    setLoading(true)
    setError('')

    try {
      await settingService.deleteAdminAccount(password, phrase)
      showNotification('Akun dan seluruh data instansi telah berhasil dihapus secara permanen.', 'success')
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
    setStep4Open(false)
    setPassword('')
    setShowPassword(false)
    setPhrase('')
    setFinalAgreed(false)
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
            fullWidth 
            type={showPassword ? 'text' : 'password'} 
            label='Masukkan Password Anda'
            value={password}
            onChange={e => { setPassword(e.target.value); setError('') }}
            error={!!error}
            helperText={error}
            autoFocus
            InputProps={{
              endAdornment: (
                <InputAdornment position='end'>
                  <IconButton edge='end' onClick={() => setShowPassword(!showPassword)} onMouseDown={e => e.preventDefault()}>
                    <i className={showPassword ? 'ri-eye-off-line' : 'ri-eye-line'} />
                  </IconButton>
                </InputAdornment>
              )
            }}
          />
        </DialogContent>
        <DialogActions sx={{ px: 6, pb: 4 }}>
          <Button onClick={handleReset} variant='outlined' disabled={verifying}>Batalkan</Button>
          <Button 
            onClick={handleStep2Confirm} 
            variant='contained' 
            color='error' 
            disabled={verifying}
            startIcon={verifying ? <CircularProgress size={16} color='inherit' /> : null}
          >
            {verifying ? 'Memverifikasi...' : 'Verifikasi'}
          </Button>
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
            Ketik <strong style={{ letterSpacing: '2px' }}>{confirmationPhrase}</strong> pada kotak di bawah untuk menghapus akun Anda secara permanen.
          </Typography>
          <TextField
            fullWidth label={`Ketik "${confirmationPhrase}"`} placeholder={confirmationPhrase}
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
            onClick={handleStep3Confirm} variant='contained' color='error'
            disabled={phrase !== confirmationPhrase}
          >
            Lanjutkan ke Kesepakatan Akhir
          </Button>
        </DialogActions>
      </Dialog>

      {/* STEP 4: Persetujuan Akhir & Checkbox */}
      <Dialog open={step4Open} onClose={handleReset} maxWidth='sm' fullWidth>
        <DialogTitle sx={{ fontWeight: '700', color: 'error.main' }}>
          <Box className='flex items-center gap-3'>
            <i className='ri-shield-flash-fill text-2xl' />
            Persetujuan Akhir Penghapusan Data
          </Box>
        </DialogTitle>
        <Divider />
        <DialogContent>
          <Alert severity='warning' variant='filled' sx={{ mb: 4, mt: 2 }}>
            <Typography variant='body2' fontWeight='700' sx={{ color: 'white' }}>
              PERHATIAN: Ini adalah konfirmasi terakhir sebelum data dihapus secara fisik dari database.
            </Typography>
          </Alert>
          
          <Box sx={{ bgcolor: 'error.lighter', p: 4, borderRadius: 2, mb: 4, border: '1px solid', borderColor: 'error.light' }}>
            <Typography variant='body1' color='error.main' fontWeight='700' gutterBottom>
              Dampak Penghapusan:
            </Typography>
            <ul style={{ paddingLeft: '20px', margin: 0, color: '#f44336' }}>
              <li><Typography variant='body2' fontWeight='600'>Akun perusahaan Anda akan terhapus total.</Typography></li>
              <li><Typography variant='body2' fontWeight='600'>SELURUH data akun karyawan Anda akan dimusnahkan.</Typography></li>
              <li><Typography variant='body2' fontWeight='600'>Data yang sudah dihapus TIDAK DAPAT dipulihkan kembali dengan cara apa pun.</Typography></li>
            </ul>
          </Box>

          <FormControlLabel
            control={<Checkbox checked={finalAgreed} onChange={e => setFinalAgreed(e.target.checked)} color='error' />}
            label={
              <Typography variant='body2' fontWeight='700'>
                Saya mengerti dan setuju bahwa dengan menghapus akun ini, seluruh data perusahaan dan data seluruh karyawan saya akan terhapus permanen dan tidak dapat dipulihkan kembali.
              </Typography>
            }
          />
          
          {error && <Typography variant='caption' color='error' sx={{ mt: 2, display: 'block' }}>{error}</Typography>}
        </DialogContent>
        <DialogActions sx={{ px: 6, pb: 6 }}>
          <Button onClick={handleReset} variant='outlined' sx={{ mr: 'auto' }}>Batalkan</Button>
          <Button
            onClick={handleFinalDelete} variant='contained' color='error'
            disabled={loading || !finalAgreed}
            size='large'
            startIcon={loading ? <CircularProgress size={16} color='inherit' /> : <i className='ri-delete-bin-7-line' />}
          >
            {loading ? 'Sedang Memproses...' : 'HAPUS PERUSAHAAN & DATA SEKARANG'}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

export default AccountDelete
