'use client'

import { useState, useEffect } from 'react'

import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Button from '@mui/material/Button'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import Avatar from '@mui/material/Avatar'
import IconButton from '@mui/material/IconButton'
import Tooltip from '@mui/material/Tooltip'
import CircularProgress from '@mui/material/CircularProgress'
import Dialog from '@mui/material/Dialog'
import DialogTitle from '@mui/material/DialogTitle'
import DialogContent from '@mui/material/DialogContent'
import DialogActions from '@mui/material/DialogActions'
import DialogContentText from '@mui/material/DialogContentText'

import { settingService } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'

const DevicesTab = () => {
  const { showNotification } = useNotification()

  // States
  const [sessions, setSessions] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [selectedSession, setSelectedSession] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)

  const fetchSessions = async () => {
    setLoading(true)
    try {
      const data = await settingService.getSessions()
      setSessions(data)
    } catch (error: any) {
      showNotification(error.message || 'Gagal memuat daftar perangkat.', 'error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchSessions()
  }, [])

  const handleDeleteClick = (id: string) => {
    setSelectedSession(id)
    setDeleteDialogOpen(true)
  }

  const handleDeleteConfirm = async () => {
    if (!selectedSession) return

    setDeleting(true)
    try {
      await settingService.deleteSession(selectedSession)
      showNotification('Perangkat berhasil dikeluarkan.', 'success')
      setDeleteDialogOpen(false)
      setSelectedSession(null)
      fetchSessions()
    } catch (error: any) {
      showNotification(error.message || 'Gagal mengeluarkan perangkat.', 'error')
    } finally {
      setDeleting(false)
    }
  }

  if (loading) {
    return (
      <Box className='flex justify-center items-center p-12'>
        <CircularProgress />
      </Box>
    )
  }

  const getDeviceIcon = (session: any) => {
    const text = (session.DeviceName || session.DeviceID || '').toLowerCase()
    if (text.includes('iphone') || text.includes('android') || text.includes('smartphone')) {
      return 'ri-smartphone-line'
    }
    if (text.includes('ipad') || text.includes('tablet')) {
      return 'ri-tablet-line'
    }
    
return 'ri-computer-line'
  }

  return (
    <>
      <Grid container spacing={6}>
        <Grid item xs={12}>
          <Card className='shadow-sm border-none'>
            <CardHeader
              title='Manajemen Perangkat'
              subheader='Daftar perangkat yang saat ini memiliki akses aktif ke akun Anda.'
              titleTypographyProps={{ variant: 'h6', fontWeight: 'bold' }}
              action={
                <Button variant='outlined' size='small' onClick={fetchSessions} startIcon={<i className='ri-refresh-line' />}>
                  Refresh
                </Button>
              }
            />
            <CardContent>
              {sessions.length === 0 ? (
                <Box className='flex flex-col items-center justify-center p-12 bg-slate-50 rounded-xl border border-dashed border-slate-200'>
                  <i className='ri-device-line text-4xl text-slate-300 mb-2' />
                  <Typography variant='body2' className='text-slate-400'>Tidak ada sesi aktif ditemukan.</Typography>
                </Box>
              ) : (
                <Box className='flex flex-col gap-4'>
                  {sessions.map((session, index) => (
                    <Box
                      key={session.ID}
                      className='flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-slate-100 hover:border-blue-200 transition-all'
                    >
                      <Box className='flex items-center gap-4'>
                        <Avatar className='bg-blue-100 text-blue-600'>
                          <i className={getDeviceIcon(session)} />
                        </Avatar>
                        <Box>
                          <Typography className='font-bold text-slate-700'>
                            {session.DeviceName || session.DeviceID || 'Perangkat Tidak Dikenal'}
                          </Typography>
                          <Typography variant='caption' className='text-slate-400 block'>
                            Terakhir aktif: {new Date(session.LastActiveAt).toLocaleString('id-ID')}
                          </Typography>
                        </Box>
                      </Box>
                      <Tooltip title='Keluarkan Perangkat'>
                        <IconButton color='error' onClick={() => handleDeleteClick(session.ID)}>
                          <i className='ri-logout-box-r-line' />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  ))}
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Confirmation Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => !deleting && setDeleteDialogOpen(false)}
        aria-labelledby="alert-dialog-title"
        aria-describedby="alert-dialog-description"
        PaperProps={{
          style: {
            borderRadius: '20px',
            padding: '8px'
          }
        }}
      >
        <DialogTitle id="alert-dialog-title" className='font-bold text-xl'>
          {"Konfirmasi Keluarkan Perangkat"}
        </DialogTitle>
        <DialogContent>
          <DialogContentText id="alert-dialog-description">
            Apakah Anda yakin ingin mengeluarkan perangkat ini? Pengguna pada perangkat tersebut harus melakukan login ulang untuk mengakses kembali akun ini.
          </DialogContentText>
        </DialogContent>
        <DialogActions className='p-4'>
          <Button 
            onClick={() => setDeleteDialogOpen(false)} 
            disabled={deleting}
            variant='outlined'
            className='rounded-xl'
          >
            Batal
          </Button>
          <Button 
            onClick={handleDeleteConfirm} 
            color="error" 
            variant='contained'
            autoFocus
            disabled={deleting}
            className='rounded-xl bg-red-600 hover:bg-red-700'
            startIcon={deleting ? <CircularProgress size={20} color="inherit" /> : null}
          >
            Ya, Keluarkan
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

export default DevicesTab
