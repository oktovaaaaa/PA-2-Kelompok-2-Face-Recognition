// src/views/account-settings/account/AccountDetails.tsx
'use client'

import { useState, useEffect, ChangeEvent } from 'react'
import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Button from '@mui/material/Button'
import Typography from '@mui/material/Typography'
import TextField from '@mui/material/TextField'
import CircularProgress from '@mui/material/CircularProgress'
import Box from '@mui/material/Box'
import { settingService, Profile } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'

const AccountDetails = () => {
  const [formData, setFormData] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [saveLoading, setSaveLoading] = useState(false)
  const [imgSrc, setImgSrc] = useState<string>('/images/avatars/1.png')
  const { showNotification } = useNotification()

  const baseUrl = process.env.NEXT_PUBLIC_API_URL?.replace('/api', '') || 'http://localhost:8080'

  const loadProfile = async () => {
    try {
      const data = await settingService.getProfile()
      setFormData(data)
      if (data.photo_url) {
        setImgSrc(`${baseUrl}${data.photo_url}`)
      }
    } catch (error) {
      console.error(error)
      showNotification('Gagal memuat profil pengguna.', 'error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadProfile()
  }, [])

  const handleFormChange = (field: keyof Profile, value: string) => {
    if (formData) {
      setFormData({ ...formData, [field]: value })
    }
  }

  const handleFileInputChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file && formData) {
      setSaveLoading(true)
      try {
        const res = await settingService.uploadFile(file)
        const photoUrl = res.url
        await settingService.updateProfile({ ...formData, photo_url: photoUrl })
        setImgSrc(`${baseUrl}${photoUrl}`)
        setFormData({ ...formData, photo_url: photoUrl })
        showNotification('Foto profil berhasil diperbarui!', 'success')
      } catch (error) {
        showNotification('Gagal mengunggah foto profil.', 'error')
      } finally {
        setSaveLoading(false)
      }
    }
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData) return
    setSaveLoading(true)
    try {
      await settingService.updateProfile(formData)
      showNotification('Perubahan profil berhasil disimpan!', 'success')
    } catch (error) {
      showNotification('Gagal menyimpan perubahan profil.', 'error')
    } finally {
      setSaveLoading(false)
    }
  }

  if (loading) return (
    <Box className='flex flex-col items-center justify-center p-10 gap-4'>
        <CircularProgress size={40} thickness={4} />
        <Typography variant='caption' className='font-bold text-slate-400 uppercase tracking-widest'>Memuat Data Profil...</Typography>
    </Box>
  )

  return (
    <Card className='shadow-sm border-none'>
      <CardContent className='mbe-5'>
        <Box className='flex max-sm:flex-col items-center gap-6'>
          <img height={100} width={100} className='rounded-2xl bg-slate-100 object-cover shadow-inner border-4 border-white' src={imgSrc} alt='Profil' />
          <Box className='flex flex-grow flex-col gap-2'>
            <Box className='flex flex-col sm:flex-row gap-4'>
              <Button component='label' size='medium' variant='contained' htmlFor='account-settings-upload-image' startIcon={<i className='ri-upload-2-line' />}>
                Unggah Foto Baru
                <input hidden type='file' accept='image/*' onChange={handleFileInputChange} id='account-settings-upload-image' />
              </Button>
              <Button variant='outlined' color='secondary' onClick={() => setImgSrc('/images/avatars/1.png')}>
                Reset
              </Button>
            </Box>
            <Typography variant='caption' color='text.secondary' className='font-medium'>
                Format yang diizinkan: JPG, GIF, atau PNG. Ukuran maksimal 800KB.
            </Typography>
          </Box>
        </Box>
      </CardContent>
      <CardContent>
        <form onSubmit={handleSave}>
          <Grid container spacing={5}>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Nama Lengkap' 
                placeholder='Masukkan nama lengkap Anda'
                variant='outlined'
                value={formData?.name || ''} 
                onChange={e => handleFormChange('name', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Alamat Email' 
                value={formData?.email || ''} 
                disabled
                helperText='Email tidak dapat diubah untuk keamanan akun.'
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Nomor Telepon' 
                placeholder='Contoh: 08123456789'
                value={formData?.phone || ''} 
                onChange={e => handleFormChange('phone', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Tempat Lahir' 
                placeholder='Kota kelahiran'
                value={formData?.birth_place || ''} 
                onChange={e => handleFormChange('birth_place', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Tanggal Lahir' 
                type='date'
                InputLabelProps={{ shrink: true }}
                value={formData?.birth_date || ''} 
                onChange={e => handleFormChange('birth_date', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Alamat Domisili' 
                placeholder='Alamat lengkap saat ini'
                value={formData?.address || ''} 
                onChange={e => handleFormChange('address', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} className='flex gap-4 flex-wrap mt-4'>
              <Button variant='contained' size='large' type='submit' disabled={saveLoading} className='min-w-[150px]'>
                {saveLoading ? 'Menyimpan...' : 'Simpan Perubahan'}
              </Button>
              <Button variant='outlined' size='large' color='secondary' onClick={loadProfile}>
                Batalkan
              </Button>
            </Grid>
          </Grid>
        </form>
      </CardContent>
    </Card>
  )
}

export default AccountDetails
