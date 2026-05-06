// src/views/account-settings/company/index.tsx
'use client'

import { useState, useEffect } from 'react'

import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Button from '@mui/material/Button'
import Typography from '@mui/material/Typography'
import TextField from '@mui/material/TextField'
import CircularProgress from '@mui/material/CircularProgress'
import Box from '@mui/material/Box'

import type { Company } from '@/libs/settingService';
import { settingService } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'
import LocationSettings from './LocationSettings'

const CompanyTab = () => {
  const [formData, setFormData] = useState<Company | null>(null)
  const [loading, setLoading] = useState(true)
  const [saveLoading, setSaveLoading] = useState(false)
  const { showNotification } = useNotification()
  
  const loadCompany = async () => {
    try {
      const data = await settingService.getCompany()

      setFormData(data)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadCompany()
  }, [])

  const handleFormChange = (field: keyof Company, value: string) => {
    if (formData) {
      setFormData({ ...formData, [field]: value })
    }
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData) return
    setSaveLoading(true)

    try {
      await settingService.updateCompany({
        Name: formData.name,
        Address: formData.address,
        Email: formData.email,
        Phone: formData.phone
      } as any)
      showNotification('Profil instansi berhasil diperbarui!', 'success')
      loadCompany()
    } catch (error) {
      showNotification('Gagal memperbarui profil instansi.', 'error')
    } finally {
      setSaveLoading(false)
    }
  }

  if (loading) return <CircularProgress sx={{ display: 'block', m: 'auto', mt: 10 }} />

  return (
    <Box>
      <Card>
      <CardContent>
        <Typography variant='h5' fontWeight='800' className='mbe-5'>Informasi Instansi</Typography>
        <form onSubmit={handleSave}>
          <Grid container spacing={5}>
            <Grid item xs={12} sm={12}>
              <TextField 
                fullWidth label='Nama Perusahaan / Instansi' 
                placeholder='Masukkan nama instansi'
                value={formData?.name || ''} 
                onChange={e => handleFormChange('name', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Email Resmi Kantor' 
                placeholder='office@company.com'
                type='email'
                value={formData?.email || ''} 
                onChange={e => handleFormChange('email', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Telepon Kantor' 
                placeholder='(021) 123456'
                value={formData?.phone || ''} 
                onChange={e => handleFormChange('phone', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth label='Alamat Lengkap' 
                placeholder='Masukkan alamat kantor'
                multiline
                rows={3}
                value={formData?.address || ''} 
                onChange={e => handleFormChange('address', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} className='flex gap-4 flex-wrap'>
              <Button variant='contained' type='submit' disabled={saveLoading}>
                {saveLoading ? 'Menyimpan...' : 'Simpan Perubahan'}
              </Button>
              <Button variant='outlined' color='secondary' onClick={loadCompany}>
                Batalkan
              </Button>
            </Grid>
          </Grid>
        </form>
      </CardContent>
      </Card>

      <Box sx={{ mt: 8 }}>
        <LocationSettings />
      </Box>
    </Box>
  )
}

export default CompanyTab
