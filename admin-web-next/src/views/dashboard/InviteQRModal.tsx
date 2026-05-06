// src/views/dashboard/InviteQRModal.tsx
'use client'

import { useState, useEffect, useRef } from 'react'

import Dialog from '@mui/material/Dialog'
import DialogTitle from '@mui/material/DialogTitle'
import DialogContent from '@mui/material/DialogContent'
import IconButton from '@mui/material/IconButton'
import Typography from '@mui/material/Typography'
import Button from '@mui/material/Button'
import Box from '@mui/material/Box'
import CircularProgress from '@mui/material/CircularProgress'
import { QRCodeSVG } from 'qrcode.react'

import { dashboardService } from '@/libs/dashboardService'
import { useNotification } from '@/contexts/NotificationContext'

interface InviteQRModalProps {
  open: boolean
  onClose: () => void
}

const InviteQRModal = ({ open, onClose }: InviteQRModalProps) => {
  const [token, setToken] = useState<string>('')
  const [countdown, setCountdown] = useState<number>(0)
  const [loading, setLoading] = useState<boolean>(false)
  const { showNotification } = useNotification()
  const timerRef = useRef<NodeJS.Timeout | null>(null)

  const fetchToken = async () => {
    if (countdown > 0) return
    setLoading(true)

    try {
      const data = await dashboardService.generateInviteToken()

      setToken(data.token)
      setCountdown(30)
    } catch (error) {
      showNotification('Gagal membuat token baru', 'error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (open) {
      fetchToken()
    } else {
      setToken('')
      setCountdown(0)
      if (timerRef.current) clearInterval(timerRef.current)
    }

    
return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [open])

  useEffect(() => {
    if (open && countdown > 0) {
      timerRef.current = setInterval(() => {
        setCountdown(prev => {
          if (prev <= 1) {
            if (timerRef.current) clearInterval(timerRef.current)
            
return 0
          }

          
return prev - 1
        })
      }, 1000)
    }

    
return () => {
        if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [open, countdown])

  const handleCopy = () => {
    navigator.clipboard.writeText(token)
    showNotification('Token berhasil disalin!', 'success')
  }

  const handleDownload = () => {
    const svg = document.getElementById('invite-qr-svg')

    if (!svg) return

    const svgData = new XMLSerializer().serializeToString(svg)
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    const img = new Image()

    img.onload = () => {
      canvas.width = img.width + 40
      canvas.height = img.height + 40

      if (ctx) {
          ctx.fillStyle = 'white'
          ctx.fillRect(0, 0, canvas.width, canvas.height)
          ctx.drawImage(img, 20, 20)
          const pngFile = canvas.toDataURL('image/png')
          const downloadLink = document.createElement('a')

          downloadLink.download = `invite_qr_${Date.now()}.png`
          downloadLink.href = pngFile
          downloadLink.click()
      }
    }

    img.src = 'data:image/svg+xml;base64,' + btoa(svgData)
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth='xs' fullWidth>
      <DialogTitle className='flex justify-between items-center bg-slate-50 p-4 border-b'>
        <Typography variant='h6' className='font-bold text-slate-800'>Undangan Rekrutmen</Typography>
        <IconButton onClick={onClose} size='small'>
          <i className='ri-close-line' />
        </IconButton>
      </DialogTitle>
      <DialogContent className='p-6'>
        <Box className='flex flex-col items-center gap-6'>
          <Box className='relative p-4 bg-white border-2 border-slate-100 rounded-2xl shadow-sm'>
            {loading ? (
                <Box className='w-[200px] h-[200px] flex items-center justify-center'>
                    <CircularProgress size={40} />
                </Box>
            ) : (
                <QRCodeSVG id='invite-qr-svg' value={token} size={200} />
            )}
          </Box>

          <Box className='w-full flex flex-col gap-2'>
            <Typography variant='caption' color='text.secondary' className='text-center'>
                Gunakan token ini untuk pendaftaran karyawan baru di aplikasi mobile.
            </Typography>
            <Box className='flex items-center gap-2 p-3 bg-slate-50 border border-dashed border-slate-200 rounded-lg'>
                <i className='ri-key-2-line text-slate-400' />
                <Typography className='flex-1 font-mono text-center font-bold tracking-widest text-slate-700'>
                    {token || '-------'}
                </Typography>
                <IconButton size='small' onClick={handleCopy}>
                    <i className='ri-file-copy-line text-slate-400' />
                </IconButton>
            </Box>
          </Box>

          <Box className='grid grid-cols-1 gap-4 w-full'>
            <Button 
                variant='contained' 
                disabled={loading || countdown > 0}
                onClick={fetchToken}
                startIcon={loading ? <CircularProgress size={20} color='inherit' /> : <i className='ri-refresh-line text-white' />}
                className='rounded-xl shadow-none py-3 bg-slate-900 hover:bg-slate-800 disabled:opacity-50'
                sx={{ 
                    color: 'white !important', // Paksa warna teks menjadi putih
                    '&.Mui-disabled': { color: 'rgba(255, 255, 255, 0.5) !important' }
                }}
            >
                {countdown > 0 ? `Tunggu (${countdown}s)` : 'Segarkan Barcode'}
            </Button>
            <Box className='grid grid-cols-2 gap-4'>
                <Button 
                    variant='outlined' 
                    onClick={handleCopy} 
                    startIcon={<i className='ri-file-copy-line' />}
                    className='rounded-xl'
                >
                    Salin Token
                </Button>
                <Button 
                    variant='outlined' 
                    onClick={handleDownload} 
                    startIcon={<i className='ri-download-cloud-2-line' />}
                    className='rounded-xl shadow-none'
                >
                    Download
                </Button>
            </Box>
          </Box>
          
          <Typography variant='caption' className='text-slate-400 italic text-center'>
            Barcode hanya dapat diperbarui secara manual setiap 30 detik untuk keamanan sistem.
          </Typography>
        </Box>
      </DialogContent>
    </Dialog>
  )
}

export default InviteQRModal
