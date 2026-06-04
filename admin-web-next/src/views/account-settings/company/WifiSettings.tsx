// src/views/account-settings/company/WifiSettings.tsx
'use client'

import { useState, useEffect } from 'react'
import {
  Card, CardHeader, CardContent, Grid, TextField,
  Button, Typography, Box, CircularProgress, IconButton,
  Divider, Tooltip, Switch, FormControlLabel, List, ListItem,
  ListItemText, Chip, FormControl, InputLabel, Select, MenuItem
} from '@mui/material'

import type { CompanyWifi, CompanyLocation } from '@/libs/settingService'
import { settingService } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'
import ConfirmDialog from '@/components/ConfirmDialog'

const WifiSettings = () => {
  const { showNotification } = useNotification()
  const [wifis, setWifis] = useState<CompanyWifi[]>([])
  const [locations, setLocations] = useState<CompanyLocation[]>([])
  const [loading, setLoading] = useState(true)
  const [actionLoading, setActionLoading] = useState(false)

  // Editor State
  const [isEditing, setIsEditing] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)

  const [form, setForm] = useState({
    name: '',
    bssid: '',
    location_id: '',
    is_active: true
  })

  // Confirmation State
  const [confirmState, setConfirmState] = useState<{
    open: boolean;
    title: string;
    message: string;
    onConfirm: () => void;
    type: 'warning' | 'error' | 'info';
  }>({
    open: false,
    title: '',
    message: '',
    onConfirm: () => {},
    type: 'warning'
  })

  const loadData = async () => {
    try {
      const [wifisData, locationsData] = await Promise.all([
        settingService.getWifis(),
        settingService.getLocations()
      ])
      setWifis(wifisData || [])
      setLocations(locationsData || [])
    } catch (error) {
      console.error(error)
      showNotification('Gagal memuat data pengaturan Wi-Fi.', 'error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [])

  const executeSave = async () => {
    setActionLoading(true)
    try {
      // Validasi format MAC Address (BSSID) sederhana: xx:xx:xx:xx:xx:xx (case insensitive, alphanumeric)
      const bssidPattern = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/
      if (!bssidPattern.test(form.bssid.trim())) {
        showNotification('Format BSSID (MAC Address) tidak valid. Contoh: AA:BB:CC:DD:EE:FF', 'error')
        setActionLoading(false)
        return
      }

      const payload = {
        name: form.name.trim(),
        bssid: form.bssid.trim().toLowerCase(), // Normalkan ke huruf kecil
        location_id: form.location_id || undefined,
        is_active: form.is_active
      }

      if (isEditing && editingId) {
        await settingService.updateWifi(editingId, payload)
        showNotification('Data Wi-Fi berhasil diperbarui!', 'success')
      } else {
        await settingService.createWifi(payload)
        showNotification('Jaringan Wi-Fi baru berhasil ditambahkan!', 'success')
      }

      setIsEditing(false)
      setEditingId(null)
      setForm({ name: '', bssid: '', location_id: '', is_active: true })
      loadData()
    } catch (error) {
      console.error(error)
      showNotification('Gagal menyimpan konfigurasi Wi-Fi.', 'error')
    } finally {
      setActionLoading(false)
    }
  }

  const handleSave = () => {
    if (!form.name.trim()) {
      showNotification('Nama Wi-Fi / SSID wajib diisi.', 'error')
      return
    }
    if (!form.bssid.trim()) {
      showNotification('Alamat MAC / BSSID wajib diisi.', 'error')
      return
    }

    setConfirmState({
      open: true,
      title: isEditing ? 'Perbarui Wi-Fi?' : 'Simpan Wi-Fi?',
      message: `Apakah Anda yakin ingin ${isEditing ? 'memperbarui' : 'menyimpan'} jaringan Wi-Fi "${form.name}"?`,
      onConfirm: executeSave,
      type: 'info'
    })
  }

  const handleEdit = (wifi: CompanyWifi) => {
    setForm({
      name: wifi.name,
      bssid: wifi.bssid,
      location_id: wifi.location_id || '',
      is_active: wifi.is_active
    })
    setEditingId(wifi.id)
    setIsEditing(true)

    const editor = document.getElementById('wifi-editor')
    if (editor) editor.scrollIntoView({ behavior: 'smooth' })
  }

  const handleDelete = (id: string, name: string) => {
    setConfirmState({
      open: true,
      title: 'Hapus Wi-Fi Resmi?',
      message: `Tindakan ini akan menghapus jaringan Wi-Fi "${name}" secara permanen dari sistem absensi kantor.`,
      onConfirm: async () => {
        try {
          await settingService.deleteWifi(id)
          showNotification('Jaringan Wi-Fi berhasil dihapus.', 'success')
          loadData()
        } catch (e) {
          showNotification('Gagal menghapus jaringan Wi-Fi.', 'error')
        }
      },
      type: 'error'
    })
  }

  const getLocationName = (locationId?: string) => {
    if (!locationId) return 'Semua Lokasi / Global'
    const loc = locations.find(l => l.id === locationId)
    return loc ? loc.name : 'Lokasi Tidak Ditemukan'
  }

  if (loading) return null

  return (
    <Grid container spacing={6}>
      {/* Editor Section */}
      <Grid item xs={12} id="wifi-editor">
        <Card variant="outlined">
          <CardHeader
            title={isEditing ? 'Ubah Jaringan Wi-Fi Kantor' : 'Tambah Wi-Fi Resmi Baru'}
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-wifi-line' style={{ fontSize: '1.5rem', color: '#2563EB' }} />}
            subheader="Daftarkan detail Wi-Fi resmi yang dapat digunakan karyawan untuk absensi"
          />
          <Divider />
          <CardContent>
            <Grid container spacing={5}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nama Wi-Fi (SSID)"
                  placeholder="Contoh: WiFi_Kantor_Utama"
                  size="small"
                  value={form.name}
                  onChange={e => setForm({ ...form, name: e.target.value })}
                  helperText="Nama jaringan Wi-Fi yang terlihat di perangkat (Case Sensitive)"
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Alamat MAC Router (BSSID)"
                  placeholder="Contoh: AA:BB:CC:DD:EE:FF"
                  size="small"
                  value={form.bssid}
                  onChange={e => setForm({ ...form, bssid: e.target.value })}
                  helperText="MAC Address fisik router access point. Wajib format xx:xx:xx:xx:xx:xx"
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth size="small">
                  <InputLabel id="location-select-label">Tautkan ke Lokasi Kantor</InputLabel>
                  <Select
                    labelId="location-select-label"
                    label="Tautkan ke Lokasi Kantor"
                    value={form.location_id}
                    onChange={e => setForm({ ...form, location_id: e.target.value })}
                  >
                    <MenuItem value=""><em>Semua Lokasi / Global</em></MenuItem>
                    {locations.map(loc => (
                      <MenuItem key={loc.id} value={loc.id}>
                        {loc.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={6} sx={{ display: 'flex', alignItems: 'center' }}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={form.is_active}
                      onChange={e => setForm({ ...form, is_active: e.target.checked })}
                    />
                  }
                  label="Status Jaringan Aktif"
                />
              </Grid>

              <Grid item xs={12} sx={{ display: 'flex', gap: 2, mt: 2 }}>
                {isEditing && (
                  <Button
                    variant="outlined"
                    color="secondary"
                    onClick={() => {
                      setIsEditing(false)
                      setEditingId(null)
                      setForm({ name: '', bssid: '', location_id: '', is_active: true })
                    }}
                  >
                    Batal
                  </Button>
                )}
                <Button
                  variant="contained"
                  onClick={handleSave}
                  disabled={actionLoading}
                >
                  {actionLoading ? 'Menyimpan...' : (isEditing ? 'Perbarui Jaringan' : 'Daftarkan Wi-Fi')}
                </Button>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>

      {/* List Section */}
      <Grid item xs={12}>
        <Card variant="outlined">
          <CardHeader
            title="Daftar Wi-Fi Absensi Resmi"
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-wifi-line' style={{ fontSize: '1.5rem', color: '#10B981' }} />}
            subheader="Daftar router/access point resmi kantor yang diperbolehkan untuk absensi"
          />
          <Divider />
          <CardContent>
            {wifis.length === 0 ? (
              <Box sx={{ py: 10, textAlign: 'center' }}>
                <Typography color="textSecondary">Belum ada jaringan Wi-Fi kantor yang ditambahkan.</Typography>
                <Typography variant="body2" color="textSecondary" sx={{ mt: 2 }}>
                  * Jika tidak ada Wi-Fi terdaftar, sistem akan otomatis default hanya memvalidasi geofencing GPS.
                </Typography>
              </Box>
            ) : (
              <List sx={{ width: '100%', bgcolor: 'background.paper' }}>
                {wifis.map((wifi) => (
                  <ListItem
                    key={wifi.id}
                    sx={{ px: 4, py: 3, borderBottom: '1px solid', borderColor: 'divider' }}
                    secondaryAction={
                      <Box>
                        <Tooltip title="Ubah">
                          <IconButton edge="end" onClick={() => handleEdit(wifi)} sx={{ mr: 1 }}>
                            <i className="ri-edit-line" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Hapus">
                          <IconButton edge="end" color="error" onClick={() => handleDelete(wifi.id, wifi.name)}>
                            <i className="ri-delete-bin-7-line" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    }
                  >
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
                          <Typography variant="subtitle1" sx={{ fontWeight: 'bold' }}>{wifi.name}</Typography>
                          <Chip label={wifi.bssid.toUpperCase()} size="small" variant="outlined" color="primary" />
                          <Chip label={getLocationName(wifi.location_id)} size="small" variant="filled" color="secondary" />
                          {wifi.is_active ?
                            <Chip label="Aktif" size="small" color="success" /> :
                            <Chip label="Nonaktif" size="small" color="default" />
                          }
                        </Box>
                      }
                      secondary={
                        <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }}>
                          Terdaftar sejak: {wifi.created_at ? new Date(wifi.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) : '-'}
                        </Typography>
                      }
                    />
                  </ListItem>
                ))}
              </List>
            )}
          </CardContent>
        </Card>
      </Grid>

      <ConfirmDialog
        open={confirmState.open}
        onClose={() => setConfirmState({ ...confirmState, open: false })}
        onConfirm={confirmState.onConfirm}
        title={confirmState.title}
        message={confirmState.message}
        type={confirmState.type}
      />
    </Grid>
  )
}

export default WifiSettings
