// src/views/operasional/AttendanceSettings.tsx
'use client'

import { useState, useEffect } from 'react'

import { 
  Card, CardHeader, CardContent, Grid, TextField, 
  Button, Typography, Box, CircularProgress, IconButton,
  Divider, InputAdornment, Tooltip
} from '@mui/material'

import type { AttendanceSettings, PenaltyTier } from '@/libs/settingService';
import { settingService } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'

const AttendanceSettingsTab = () => {
  const { showNotification } = useNotification()
  const [settings, setSettings] = useState<AttendanceSettings | null>(null)
  const [localTiers, setLocalTiers] = useState<PenaltyTier[]>([])
  const [loading, setLoading] = useState(true)
  const [saveLoading, setSaveLoading] = useState(false)

  // Helper untuk format angka dengan titik
  const formatNumber = (val: number | string) => {
    if (val === undefined || val === null || val === '') return ''
    const str = val.toString().replace(/\D/g, '')

    
return str.replace(/\B(?=(\d{3})+(?!\d))/g, '.')
  }

  // Helper untuk parse string ber-titik kembali ke number
  const parseNumber = (val: string) => {
    const clean = val.replace(/\./g, '')

    
return parseInt(clean, 10) || 0
  }

  const loadSettings = async () => {
    try {
      const data = await settingService.getAttendanceSettings()

      setSettings(data)
      
      // Parse late_penalty_tiers JSON string from backend: [{"hours": 1, "penalty": 10000}]
      if (data.late_penalty_tiers) {
        try {
          const parsed = JSON.parse(data.late_penalty_tiers)

          setLocalTiers(parsed)
        } catch (e) {
          console.error("Error parsing tiers:", e)
          setLocalTiers([])
        }
      }
    } catch (error) {
      console.error(error)
      showNotification('Gagal memuat pengaturan operasional.', 'error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadSettings()
  }, [])

  const handleSave = async () => {
    if (!settings) return
    setSaveLoading(true)

    try {
      const payload = {
        ...settings,
        late_penalty_tiers: JSON.stringify(localTiers)
      }

      await settingService.updateAttendanceSettings(payload)
      showNotification('Pengaturan operasional berhasil diperbarui!', 'success')
      loadSettings()
    } catch (error) {
      showNotification('Gagal menyimpan pengaturan.', 'error')
    } finally {
      setSaveLoading(false)
    }
  }

  const addTier = () => {
    setLocalTiers([...localTiers, { hours: 0, penalty: 0 }])
  }

  const removeTier = (index: number) => {
    const newTiers = [...localTiers]

    newTiers.splice(index, 1)
    setLocalTiers(newTiers)
  }

  const updateTier = (index: number, field: keyof PenaltyTier, value: number) => {
    const newTiers = [...localTiers]

    newTiers[index] = { ...newTiers[index], [field]: value }
    setLocalTiers(newTiers)
  }

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', p: 10 }}><CircularProgress /></Box>

  return (
    <Grid container spacing={6}>
      {/* 1. Jam Kerja & Toleransi */}
      <Grid item xs={12} md={7}>
        <Card variant="outlined" sx={{ height: '100%' }}>
          <CardHeader 
            title="Siklus Waktu Kerja" 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-time-line' style={{ fontSize: '1.5rem', color: '#3b82f6' }} />}
            subheader="Tentukan jendela waktu absensi masuk dan pulang" 
          />
          <Divider />
          <CardContent sx={{ pt: 6 }}>
            <Grid container spacing={6}>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2" sx={{ mb: 2, fontWeight: '600' }}>Sesi Masuk (Check-in)</Typography>
                <Box sx={{ display: 'flex', gap: 3 }}>
                    <TextField 
                        fullWidth label="Mulai" type="time" size="small" InputLabelProps={{ shrink: true }}
                        value={settings?.check_in_start || ''}
                        onChange={e => setSettings(s => s ? {...s, check_in_start: e.target.value} : null)}
                    />
                    <TextField 
                        fullWidth label="Selesai" type="time" size="small" InputLabelProps={{ shrink: true }}
                        value={settings?.check_in_end || ''}
                        onChange={e => setSettings(s => s ? {...s, check_in_end: e.target.value} : null)}
                    />
                </Box>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2" sx={{ mb: 2, fontWeight: '600' }}>Sesi Pulang (Check-out)</Typography>
                <Box sx={{ display: 'flex', gap: 3 }}>
                    <TextField 
                        fullWidth label="Mulai" type="time" size="small" InputLabelProps={{ shrink: true }}
                        value={settings?.check_out_start || ''}
                        onChange={e => setSettings(s => s ? {...s, check_out_start: e.target.value} : null)}
                    />
                    <TextField 
                        fullWidth label="Selesai" type="time" size="small" InputLabelProps={{ shrink: true }}
                        value={settings?.check_out_end || ''}
                        onChange={e => setSettings(s => s ? {...s, check_out_end: e.target.value} : null)}
                    />
                </Box>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>

      {/* 2. Denda Dasar */}
      <Grid item xs={12} md={5}>
        <Card variant="outlined" sx={{ height: '100%' }}>
          <CardHeader 
            title="Denda Dasar Absensi" 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-money-dollar-circle-line' style={{ fontSize: '1.5rem', color: '#ef4444' }} />}
            subheader="Kebijakan denda ketidakhadiran" 
          />
          <Divider />
          <CardContent sx={{ pt: 6 }}>
            <Grid container spacing={5}>
              <Grid item xs={12}>
                <TextField 
                  fullWidth label="Denda Alpha / Tidak Hadir"
                  placeholder="Contoh: 150.000"
                  value={formatNumber(settings?.alpha_penalty || 0)}
                  onChange={e => setSettings(s => s ? {...s, alpha_penalty: parseNumber(e.target.value)} : null)}
                  InputProps={{
                    startAdornment: <InputAdornment position="start">Rp</InputAdornment>,
                  }}
                  helperText="Denda per hari jika tidak ada record absensi"
                />
              </Grid>
              <Grid item xs={12}>
                <TextField 
                  fullWidth label="Denda Keterlambatan Dasar"
                  value={formatNumber(settings?.late_penalty || 0)}
                  onChange={e => setSettings(s => s ? {...s, late_penalty: parseNumber(e.target.value)} : null)}
                  InputProps={{
                    startAdornment: <InputAdornment position="start">Rp</InputAdornment>,
                  }}
                  helperText="Denda yang dikenakan segera setelah telat 1 menit"
                />
              </Grid>
              <Grid item xs={12}>
                <TextField 
                  fullWidth label="Denda Pulang di Jam Kerja"
                  value={formatNumber(settings?.early_leave_penalty || 0)}
                  onChange={e => setSettings(s => s ? {...s, early_leave_penalty: parseNumber(e.target.value)} : null)}
                  InputProps={{
                    startAdornment: <InputAdornment position="start">Rp</InputAdornment>,
                  }}
                  helperText="Denda jika pulang sebelum waktu sesi pulang dibuka"
                />
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>

      {/* 3. Denda Berjenjang */}
      <Grid item xs={12}>
        <Card variant="outlined">
          <CardHeader 
            title="Denda Keterlambatan Berjenjang (Opsional)" 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-line-chart-line' style={{ fontSize: '1.5rem', color: '#f59e0b' }} />}
            subheader="Tambahkan denda tambahan berdasarkan durasi jam terlambat"
            action={
              <Button 
                variant="outlined" size="small" startIcon={<i className='ri-add-line'/>} 
                onClick={addTier} sx={{ mt: 1, mr: 2 }}
              >
                Tambah Aturan
              </Button>
            }
          />
          <Divider />
          <CardContent>
            {localTiers.length === 0 ? (
                <Box sx={{ py: 10, textAlign: 'center', bgcolor: 'action.hover', borderRadius: 2, border: '1px dashed', borderColor: 'divider' }}>
                    <i className="ri-information-line" style={{ fontSize: '2rem', color: '#94a3b8' }} />
                    <Typography color="textSecondary" sx={{ mt: 2 }}>Belum ada aturan denda berjenjang.</Typography>
                </Box>
            ) : (
                <Grid container spacing={4}>
                  {localTiers.map((tier, idx) => (
                    <Grid item xs={12} key={idx} sx={{ display: 'flex', gap: 4, alignItems: 'center', py: 2, borderBottom: idx !== localTiers.length - 1 ? '1px solid' : 'none', borderColor: 'divider' }}>
                      <Box sx={{ width: 40, height: 40, borderRadius: '50%', bgcolor: 'primary.main', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
                        {idx + 1}
                      </Box>
                      <TextField 
                        label="Jam Ke-" type="number" size="small" sx={{ width: 200 }}
                        value={tier.hours}
                        onChange={e => updateTier(idx, 'hours', parseInt(e.target.value))}
                      />
                      <TextField 
                        label="Denda Tambahan" size="small" sx={{ width: 250 }}
                        value={formatNumber(tier.penalty)}
                        onChange={e => updateTier(idx, 'penalty', parseNumber(e.target.value))}
                        InputProps={{ startAdornment: <InputAdornment position="start">Rp</InputAdornment> }}
                      />
                      <Tooltip title="Hapus Aturan">
                        <IconButton color="error" onClick={() => removeTier(idx)} sx={{ ml: 'auto' }}>
                            <i className="ri-delete-bin-7-line" />
                        </IconButton>
                      </Tooltip>
                    </Grid>
                  ))}
                </Grid>
            )}
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={12} sx={{ display: 'flex', justifyContent: 'flex-end', gap: 4, mt: 4 }}>
        <Button variant="outlined" color="secondary" onClick={loadSettings} disabled={saveLoading}>Atur Ulang</Button>
        <Button 
          variant="contained" size="large" onClick={handleSave} disabled={saveLoading}
          startIcon={saveLoading ? <CircularProgress size={20} color="inherit"/> : <i className='ri-save-3-line'/>}
          sx={{ px: 10 }}
        >
          {saveLoading ? 'Menyimpan...' : 'Simpan Konfigurasi'}
        </Button>
      </Grid>
    </Grid>
  )
}

export default AttendanceSettingsTab
