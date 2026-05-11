// src/views/account-settings/security/index.tsx
'use client'

import { useState, useEffect } from 'react'

import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Button from '@mui/material/Button'
import TextField from '@mui/material/TextField'
import InputAdornment from '@mui/material/InputAdornment'
import IconButton from '@mui/material/IconButton'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'

import { settingService } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'
import OTPInput from '@/components/OTPInput'

const SecurityTab = () => {
  const { showNotification } = useNotification()

  // States
  const [role, setRole] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [countdown, setCountdown] = useState(0)

  // Password States
  const [showOldPassword, setShowOldPassword] = useState(false)
  const [showNewPassword, setShowNewPassword] = useState(false)
  const [passwordData, setPasswordData] = useState({ old: '', new: '', otp: '' })

  // PIN States
  const [pinData, setPinData] = useState({ old: '', new: '', otp: '' })

  useEffect(() => {
    setRole(localStorage.getItem('role'))
  }, [])

  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000)

      
return () => clearTimeout(timer)
    }
  }, [countdown])

  const handleRequestOTP = async () => {
    if (countdown > 0) return

    setLoading(true)

    try {
      await settingService.requestOTP()
      showNotification('Kode verifikasi OTP telah dikirim ke email Anda. Silakan cek kotak masuk.', 'info')
      setCountdown(30)
    } catch (error) {
      showNotification('Gagal mengirim kode OTP. Silakan coba lagi nanti.', 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!passwordData.old) return showNotification('Harap masukkan kata sandi lama Anda.', 'warning')
    if (!passwordData.new) return showNotification('Harap masukkan kata sandi baru Anda.', 'warning')
    if (!passwordData.otp) return showNotification('Harap masukkan kode OTP verifikasi.', 'warning')

    setLoading(true)

    try {
      await settingService.changePassword({
        old_password: passwordData.old,
        otp_code: passwordData.otp,
        new_password: passwordData.new
      })
      showNotification('Kata sandi Anda berhasil diperbarui!', 'success')
      setPasswordData({ old: '', new: '', otp: '' })
    } catch (error: any) {
      showNotification(error.message || 'Gagal memperbarui kata sandi.', 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleChangePIN = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!pinData.old) return showNotification('Harap masukkan PIN lama Anda.', 'warning')
    if (pinData.new.length !== 6) return showNotification('PIN baru harus terdiri dari tepat 6 digit angka.', 'warning')
    if (!pinData.otp) return showNotification('Harap masukkan kode OTP verifikasi.', 'warning')

    setLoading(true)

    try {
      await settingService.changePIN({
        old_pin: pinData.old,
        otp_code: pinData.otp,
        new_pin: pinData.new
      })
      showNotification('PIN Transaksi Anda berhasil diperbarui!', 'success')
      setPinData({ old: '', new: '', otp: '' })
    } catch (error: any) {
      showNotification(error.message || 'Gagal memperbarui PIN.', 'error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Grid container spacing={6}>
      <Grid item xs={12}>
        <Card className='shadow-sm border-none'>
          <CardHeader
            title='Keamanan Kata Sandi'
            subheader='Pastikan Anda menggunakan kombinasi karakter yang kuat agar akun tetap aman.'
            titleTypographyProps={{ variant: 'h6', fontWeight: 'bold' }}
          />
          <CardContent>
            <form onSubmit={handleChangePassword}>
              <Grid container spacing={5}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label='Kata Sandi Lama'
                    placeholder='············'
                    type={showOldPassword ? 'text' : 'password'}
                    value={passwordData.old}
                    onChange={e => setPasswordData({ ...passwordData, old: e.target.value })}
                    InputProps={{
                      endAdornment: (
                        <InputAdornment position='end'>
                          <IconButton onClick={() => setShowOldPassword(!showOldPassword)}>
                            <i className={showOldPassword ? 'ri-eye-off-line' : 'ri-eye-line'} />
                          </IconButton>
                        </InputAdornment>
                      )
                    }}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth label='Kata Sandi Baru'
                    placeholder='············'
                    type={showNewPassword ? 'text' : 'password'}
                    value={passwordData.new}
                    onChange={e => setPasswordData({ ...passwordData, new: e.target.value })}
                    InputProps={{
                      endAdornment: (
                        <InputAdornment position='end'>
                          <IconButton onClick={() => setShowNewPassword(!showNewPassword)}>
                            <i className={showNewPassword ? 'ri-eye-off-line' : 'ri-eye-line'} />
                          </IconButton>
                        </InputAdornment>
                      )
                    }}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box className='flex flex-col gap-2'>
                    <Typography variant='caption' className='font-bold uppercase tracking-widest text-slate-500'>Kode OTP Verifikasi</Typography>
                    <OTPInput
                      value={passwordData.otp}
                      onChange={val => setPasswordData({ ...passwordData, otp: val })}
                      disabled={loading}
                    />
                    <Typography variant='caption' className='text-slate-400'>Wajib diisi sebagai verifikasi lapisan kedua (2FA).</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} className='flex gap-4 items-center flex-wrap'>
                  <Button variant='contained' type='submit' disabled={loading} startIcon={<i className='ri-save-3-line' />}>
                    {loading ? 'Memproses...' : 'Ubah Kata Sandi'}
                  </Button>
                  <Button variant='outlined' color='secondary' onClick={handleRequestOTP} disabled={loading || countdown > 0}>
                    {countdown > 0 ? `Kirim Ulang (${countdown}s)` : 'Minta Kode OTP'}
                  </Button>
                </Grid>
              </Grid>
            </form>
          </CardContent>
        </Card>
      </Grid>

      {/* PIN Section - Only shown for non-Super Admins */}
      {role !== 'SUPER_ADMIN' && (
        <Grid item xs={12}>
          <Card className='shadow-sm border-none'>
            <CardHeader
              title='PIN Transaksi & Keamanan Lanjut'
              subheader='PIN digunakan untuk verifikasi cepat pada aplikasi mobile dan transaksi sistem.'
              titleTypographyProps={{ variant: 'h6', fontWeight: 'bold' }}
            />
            <CardContent>
              <form onSubmit={handleChangePIN}>
                <Grid container spacing={5}>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth label='PIN Lama'
                      placeholder='······'
                      type='password'
                      value={pinData.old}
                      onChange={e => setPinData({ ...pinData, old: e.target.value })}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth label='PIN Baru (6 Angka)'
                      placeholder='······'
                      inputProps={{ maxLength: 6 }}
                      value={pinData.new}
                      onChange={e => setPinData({ ...pinData, new: e.target.value })}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Box className='flex flex-col gap-2'>
                      <Typography variant='caption' className='font-bold uppercase tracking-widest text-slate-500'>Kode OTP Verifikasi</Typography>
                      <OTPInput
                        value={pinData.otp}
                        onChange={val => setPinData({ ...pinData, otp: val })}
                        disabled={loading}
                      />
                      <Typography variant='caption' className='text-slate-400'>Wajib diisi sebagai verifikasi lapisan kedua (2FA).</Typography>
                    </Box>
                  </Grid>
                  <Grid item xs={12} className='flex gap-4 items-center flex-wrap'>
                    <Button variant='contained' color='info' type='submit' disabled={loading} startIcon={<i className='ri-key-2-line' />}>
                      {loading ? 'Memproses...' : 'Ubah PIN'}
                    </Button>
                    <Button variant='outlined' color='info' onClick={handleRequestOTP} disabled={loading || countdown > 0}>
                      {countdown > 0 ? `Kirim Ulang (${countdown}s)` : 'Minta Kode OTP'}
                    </Button>
                  </Grid>
                </Grid>
              </form>
            </CardContent>
          </Card>
        </Grid>
      )}
    </Grid>
  )
}

export default SecurityTab
