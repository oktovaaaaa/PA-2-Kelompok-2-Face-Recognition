// src/views/operasional/LocationSettings.tsx
'use client'

import { useState, useEffect } from 'react'
import dynamic from 'next/dynamic'
import { 
  Card, CardHeader, CardContent, Grid, TextField, 
  Button, Typography, Box, CircularProgress, IconButton,
  Divider, Tooltip, Switch, FormControlLabel, List, ListItem,
  ListItemText, Chip, Paper, InputBase, ClickAwayListener, MenuList, MenuItem
} from '@mui/material'
import { settingService, CompanyLocation } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'
import ConfirmDialog from '@/components/ConfirmDialog'

// Import Leaflet CSS
import 'leaflet/dist/leaflet.css'

// Dynamic import for the entire map logic component to avoid SSR issues
const MapView = dynamic(() => import('./MapComponent'), { 
  ssr: false,
  loading: () => <Box sx={{ height: 400, display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: 'action.hover' }}><CircularProgress /></Box>
})

const LocationSettings = () => {
  const { showNotification } = useNotification()
  const [locations, setLocations] = useState<CompanyLocation[]>([])
  const [loading, setLoading] = useState(true)
  const [actionLoading, setActionLoading] = useState(false)
  
  // Editor State
  const [isEditing, setIsEditing] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [form, setForm] = useState({
    name: '',
    latitude: -6.2088,
    longitude: 106.8456,
    radius: 100,
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
  });

  // Search State
  const [searchQuery, setSearchQuery] = useState('')
  const [isSearching, setIsSearching] = useState(false)
  const [suggestions, setSuggestions] = useState<any[]>([])
  const [showSuggestions, setShowSuggestions] = useState(false)

  const loadLocations = async () => {
    try {
      const data = await settingService.getLocations()
      setLocations(data)
      
      // Jika form masih kosong (awal load) dan ada data lokasi tersimpan,
      // otomatis gunakan lokasi pertama sebagai default agar tidak lari ke Jakarta
      if (data.length > 0 && !form.name && !isEditing) {
        const first = data[0]
        setForm({
          name: first.name,
          latitude: first.latitude,
          longitude: first.longitude,
          radius: first.radius,
          is_active: first.is_active
        })
      }
    } catch (error) {
      console.error(error)
      showNotification('Gagal memuat daftar lokasi.', 'error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadLocations()
  }, [])

  // Debounced search for suggestions
  useEffect(() => {
    if (searchQuery.length < 3) {
      setSuggestions([]);
      setShowSuggestions(false);
      return;
    }

    const timer = setTimeout(async () => {
      try {
        const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}&limit=5`, {
          headers: {
            'User-Agent': 'Videnti-Attendance-System/1.0'
          }
        });
        const data = await res.json();
        setSuggestions(data || []);
        setShowSuggestions(true);
      } catch (e) {
        console.error('Failed to fetch suggestions', e);
      }
    }, 500); // 500ms debounce

    return () => clearTimeout(timer);
  }, [searchQuery]);

  const handleSelectSuggestion = (s: any) => {
    setForm(f => ({ 
      ...f, 
      latitude: parseFloat(s.lat), 
      longitude: parseFloat(s.lon),
      // Auto fill name if empty
      name: f.name || s.display_name.split(',')[0]
    }));
    setSearchQuery(s.display_name);
    setShowSuggestions(false);
  }

  const handleSearch = async () => {
    if (!searchQuery.trim() && !form.name.trim()) return
    const q = searchQuery.trim() || form.name.trim()
    
    setIsSearching(true)
    setShowSuggestions(false)
    try {
      const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(q)}&limit=1`, {
        headers: {
          'User-Agent': 'Videnti-Attendance-System/1.0'
        }
      })
      const data = await res.json()
      if (data && data.length > 0) {
        const { lat, lon } = data[0]
        setForm(f => ({ 
          ...f, 
          latitude: parseFloat(lat), 
          longitude: parseFloat(lon),
          name: f.name || data[0].display_name.split(',')[0]
        }))
      } else {
        showNotification('Lokasi tidak ditemukan.', 'warning')
      }
    } catch (e) {
      showNotification('Gagal melakukan pencarian.', 'error')
    } finally {
      setIsSearching(false)
    }
  }

  const executeSave = async () => {
    setActionLoading(true)
    try {
      if (isEditing && editingId) {
        await settingService.updateLocation(editingId, form)
        showNotification('Lokasi berhasil diperbarui!', 'success')
      } else {
        await settingService.createLocation(form)
        showNotification('Lokasi baru berhasil ditambahkan!', 'success')
      }
      setIsEditing(false)
      setEditingId(null)
      loadLocations()
      setForm({ name: '', latitude: -6.2088, longitude: 106.8456, radius: 100, is_active: true });
    } catch (error) {
      showNotification('Gagal menyimpan lokasi.', 'error')
    } finally {
      setActionLoading(false)
    }
  }

  const handleSave = async () => {
    if (!form.name) {
      showNotification('Nama lokasi wajib diisi.', 'error')
      return
    }

    setConfirmState({
      open: true,
      title: isEditing ? 'Perbarui Lokasi?' : 'Simpan Lokasi?',
      message: `Apakah Anda yakin ingin ${isEditing ? 'memperbarui' : 'menyimpan'} lokasi "${form.name}"?`,
      onConfirm: executeSave,
      type: 'info'
    });
  }

  const handleEdit = (loc: CompanyLocation) => {
    setForm({
      name: loc.name,
      latitude: loc.latitude,
      longitude: loc.longitude,
      radius: loc.radius,
      is_active: loc.is_active
    })
    setEditingId(loc.id)
    setIsEditing(true)
    // Find the element scroll to it
    const editor = document.getElementById('location-editor')
    if (editor) editor.scrollIntoView({ behavior: 'smooth' })
  }

  const handleDelete = async (id: string, name: string) => {
    setConfirmState({
      open: true,
      title: 'Hapus Lokasi?',
      message: `Tindakan ini akan menghapus "${name}" secara permanen. Karyawan yang terdaftar di area ini tidak akan bisa melakukan absensi.`,
      onConfirm: async () => {
        try {
          await settingService.deleteLocation(id)
          showNotification('Lokasi dihapus.', 'success')
          loadLocations()
        } catch (e) {
          showNotification('Gagal menghapus lokasi.', 'error')
        }
      },
      type: 'error'
    });
  }

  if (loading) return null

  return (
    <Grid container spacing={6}>
      {/* Editor & Map Section */}
      <Grid item xs={12} id="location-editor">
        <Card variant="outlined">
          <CardHeader 
            title={isEditing ? 'Ubah Lokasi Absensi' : 'Tambah Lokasi Baru'} 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-map-pin-2-line' style={{ fontSize: '1.5rem', color: '#2563EB' }} />}
            subheader="Tentukan titik pusat dan jangkauan radius untuk validasi absensi karyawan"
          />
          <Divider />
          <CardContent>
            <Grid container spacing={6}>
              {/* Form Side */}
              <Grid item xs={12} lg={4}>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <TextField 
                    fullWidth label="Nama Lokasi" placeholder="Contoh: Kantor Pusat" size="small"
                    value={form.name} onChange={e => setForm({ ...form, name: e.target.value })}
                  />

                  <Box sx={{ position: 'relative' }}>
                    <ClickAwayListener onClickAway={() => setShowSuggestions(false)}>
                      <Box>
                        <Paper component="form" variant="outlined" sx={{ p: '2px 4px', display: 'flex', alignItems: 'center', zIndex: 1, position: 'relative' }}
                          onSubmit={(e) => { e.preventDefault(); handleSearch(); }}
                        >
                          <InputBase
                            sx={{ ml: 1, flex: 1, fontSize: '0.875rem' }}
                            placeholder="Cari Kota/Kecamatan/Provinsi..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            onFocus={() => { if (suggestions.length > 0) setShowSuggestions(true); }}
                          />
                          <IconButton type="submit" sx={{ p: '10px' }} disabled={isSearching}>
                            {isSearching ? <CircularProgress size={20} /> : <i className="ri-search-line" />}
                          </IconButton>
                        </Paper>

                        {showSuggestions && suggestions.length > 0 && (
                          <Paper 
                            sx={{ 
                              position: 'absolute', top: '100%', left: 0, right: 0, 
                              zIndex: 10, mt: 1, maxHeight: 200, overflow: 'auto',
                              boxShadow: (theme) => theme.shadows[10],
                              border: '1px solid', borderColor: 'divider'
                            }}
                          >
                            <MenuList>
                              {suggestions.map((s, idx) => (
                                <MenuItem key={idx} onClick={() => handleSelectSuggestion(s)}>
                                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                    <i className="ri-map-pin-line" style={{ color: '#2563EB' }} />
                                    <Typography variant="body2" noWrap sx={{ maxWidth: 300 }}>
                                      {s.display_name}
                                    </Typography>
                                  </Box>
                                </MenuItem>
                              ))}
                            </MenuList>
                          </Paper>
                        )}
                      </Box>
                    </ClickAwayListener>
                  </Box>

                  <Box sx={{ display: 'flex', gap: 2 }}>
                    <TextField 
                      fullWidth label="Latitude" size="small" type="number"
                      value={form.latitude} onChange={e => setForm({ ...form, latitude: parseFloat(e.target.value) || 0 })}
                    />
                    <TextField 
                      fullWidth label="Longitude" size="small" type="number"
                      value={form.longitude} onChange={e => setForm({ ...form, longitude: parseFloat(e.target.value) || 0 })}
                    />
                  </Box>

                  <TextField 
                    fullWidth label="Radius Lokasi (meter)" size="small" type="number"
                    value={form.radius} onChange={e => setForm({ ...form, radius: parseFloat(e.target.value) || 0 })}
                    helperText="Karyawan di luar radius ini tidak bisa melakukan absensi"
                  />

                  <FormControlLabel
                    control={<Switch checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} />}
                    label="Status Aktif"
                  />

                  <Box sx={{ mt: 'auto', display: 'flex', gap: 2 }}>
                    {isEditing && (
                      <Button variant="outlined" color="secondary" fullWidth onClick={() => { setIsEditing(false); setEditingId(null); setForm({ name: '', latitude: -6.2088, longitude: 106.8456, radius: 100, is_active: true }); }}>
                        Batal
                      </Button>
                    )}
                    <Button variant="contained" fullWidth onClick={handleSave} disabled={actionLoading}>
                      {actionLoading ? 'Menyimpan...' : (isEditing ? 'Perbarui Lokasi' : 'Simpan Lokasi')}
                    </Button>
                  </Box>
                </Box>
              </Grid>

              {/* Map Side */}
              <Grid item xs={12} lg={8}>
                <Box sx={{ height: 400, width: '100%', borderRadius: 1, overflow: 'hidden', border: '1px solid', borderColor: 'divider' }}>
                   <MapView 
                     latitude={form.latitude} 
                     longitude={form.longitude} 
                     radius={form.radius} 
                     onLocationChange={(lat, lon) => setForm(f => ({ ...f, latitude: lat, longitude: lon }))}
                   />
                </Box>
                <Typography variant="caption" color="textSecondary" sx={{ mt: 2, display: 'block' }}>
                  * Geser marker biru pada peta untuk menentukan titik koordinat yang lebih presisi.
                </Typography>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>

      {/* List Section */}
      <Grid item xs={12}>
        <Card variant="outlined">
          <CardHeader 
            title="Daftar Lokasi Kantor" 
            titleTypographyProps={{ variant: 'h6', fontWeight: '700' }}
            avatar={<i className='ri-list-check' style={{ fontSize: '1.5rem', color: '#10B981' }} />}
            subheader="Daftar area absensi yang saat ini terdaftar di sistem"
          />
          <Divider />
          <CardContent>
            {locations.length === 0 ? (
              <Box sx={{ py: 10, textAlign: 'center' }}>
                <Typography color="textSecondary">Belum ada lokasi yang ditambahkan.</Typography>
              </Box>
            ) : (
              <List sx={{ width: '100%', bgcolor: 'background.paper' }}>
                {locations.map((loc) => (
                  <ListItem 
                    key={loc.id} 
                    sx={{ px: 4, py: 3, borderBottom: '1px solid', borderColor: 'divider' }}
                    secondaryAction={
                      <Box>
                        <Tooltip title="Ubah">
                          <IconButton edge="end" onClick={() => handleEdit(loc)} sx={{ mr: 1 }}>
                            <i className="ri-edit-line" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Hapus">
                          <IconButton edge="end" color="error" onClick={() => handleDelete(loc.id, loc.name)}>
                            <i className="ri-delete-bin-7-line" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    }
                  >
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                          <Typography variant="subtitle1" sx={{ fontWeight: 'bold' }}>{loc.name}</Typography>
                          <Chip label={`${loc.radius}m`} size="small" variant="outlined" color="primary" />
                          {loc.is_active ? 
                            <Chip label="Aktif" size="small" color="success" /> : 
                            <Chip label="Nonaktif" size="small" color="default" />
                          }
                        </Box>
                      }
                      secondary={
                        <Typography variant="body2" color="textSecondary">
                          Lat: {loc.latitude.toFixed(6)}, Lon: {loc.longitude.toFixed(6)}
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

export default LocationSettings
