// src/views/cuti/LeavePage.tsx
'use client'

import React, { useState, useEffect, useCallback } from 'react'

import Grid from '@mui/material/Grid'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'
import Button from '@mui/material/Button'

import LeaveHeader from './LeaveHeader'
import LeaveCalendar from './LeaveCalendar'
import LeaveTable from './LeaveTable'
import LeaveDetailModal from './LeaveDetailModal'
import LeaveRequestModal from './LeaveRequestModal'
import ConfirmDialog from '@/components/ConfirmDialog'
import type { LeaveRequest } from '@/libs/leaveService';
import { leaveService } from '@/libs/leaveService'
import { useNotification } from '@/contexts/NotificationContext'

const LeavePage = () => {
  const { showNotification } = useNotification()
  const [leaves, setLeaves] = useState<LeaveRequest[]>([])
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState({ total: 0, pending: 0, approved: 0, rejected: 0 })
  
  // Modal states
  const [selectedLeave, setSelectedLeave] = useState<LeaveRequest | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)
  const [isRequestOpen, setIsRequestOpen] = useState(false)
  const [isConfirmOpen, setIsConfirmOpen] = useState(false)
  const [confirmConfig, setConfirmConfig] = useState<{title: string, message: string, type: 'warning' | 'error' | 'info', action: () => void} | null>(null)
  const [selectedDate, setSelectedDate] = useState<Date | null>(null)

  const loadData = useCallback(async () => {
    setLoading(true)

    try {
      const data = await leaveService.getLeaves({ year: new Date().getFullYear() })

      setLeaves(data)
      
      const s = {
        total: data.length,
        pending: data.filter(l => l.status === 'PENDING').length,
        approved: data.filter(l => l.status === 'APPROVED').length,
        rejected: data.filter(l => l.status === 'REJECTED').length
      }

      setStats(s)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData()
  }, [loadData])

  const handleDateClick = (date: Date) => {
    setSelectedDate(date)
    setIsRequestOpen(true)
  }

  const handleProcessLeave = async (id: string, action: 'approve' | 'reject', note: string) => {
    setConfirmConfig({
        title: action === 'approve' ? 'Setujui Pengajuan' : 'Tolak Pengajuan',
        message: `Apakah Anda yakin ingin ${action === 'approve' ? 'menyetujui' : 'menolak'} pengajuan ini?`,
        type: action === 'approve' ? 'info' : 'warning',
        action: async () => {
            try {
                if (action === 'approve') await leaveService.approveLeave(id, note)
                else await leaveService.rejectLeave(id, note)
                showNotification(`Pengajuan berhasil ${action === 'approve' ? 'disetujui' : 'ditolak'}.`, 'success')
                setIsDetailOpen(false)
                loadData()
            } catch (error) {
                showNotification('Gagal memproses pengajuan.', 'error')
            }
        }
    })
    setIsConfirmOpen(true)
  }

  const handleDeleteLeave = async (id: string) => {
    setConfirmConfig({
        title: 'Hapus Pengajuan',
        message: 'Apakah Anda yakin ingin menghapus data pengajuan ini secara permanen?',
        type: 'error',
        action: async () => {
            try {
                await leaveService.deleteLeave(id)
                showNotification('Data pengajuan telah dihapus.', 'success')
                loadData()
            } catch (error) {
                showNotification('Gagal menghapus pengajuan.', 'error')
            }
        }
    })
    setIsConfirmOpen(true)
  }

  const handleCreateLeave = async (formData: any) => {
    try {
      await leaveService.createLeave(formData)
      showNotification('Izin/Cuti berhasil ditambahkan!', 'success')
      setIsRequestOpen(false)
      loadData()
    } catch (error) {
      showNotification('Gagal menambahkan izin/cuti.', 'error')
    }
  }

  return (
    <Box sx={{ p: 0 }}>
      {/* Page Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 6 }}>
        <Box>
            <Typography variant='h4' fontWeight='800' color='primary' gutterBottom>Manajemen Cuti & Izin</Typography>
            <Typography variant='body2' color='text.secondary'>Kelola pengajuan, pantau kehadiran via kalender, dan atur izin karyawan.</Typography>
        </Box>
        <Button 
            variant='contained' 
            startIcon={<i className='ri-add-line' />}
            onClick={() => { setSelectedDate(null); setIsRequestOpen(true); }}
        >
            Tambah Cuti
        </Button>
      </Box>

      {/* 1. Summary Header */}
      <LeaveHeader stats={stats} />

      <Grid container spacing={6} sx={{ mt: 2 }}>
        {/* 2. Interactive Calendar */}
        <Grid item xs={12} lg={5}>
          <LeaveCalendar 
            leaves={leaves} 
            onDateClick={handleDateClick} 
          />
        </Grid>

        {/* 3. Detailed Data Table */}
        <Grid item xs={12} lg={7}>
            <LeaveTable 
                leaves={leaves} 
                onView={(l) => { setSelectedLeave(l); setIsDetailOpen(true); }}
                onDelete={handleDeleteLeave}
            />
        </Grid>
      </Grid>

      {/* Modals & Dialogs */}
      <LeaveDetailModal 
        open={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
        leave={selectedLeave}
        onProcess={handleProcessLeave}
      />

      <LeaveRequestModal 
        open={isRequestOpen}
        onClose={() => setIsRequestOpen(false)}
        selectedDate={selectedDate}
        onSubmit={handleCreateLeave}
      />

      <ConfirmDialog 
        open={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={confirmConfig?.action || (() => {})}
        title={confirmConfig?.title || ''}
        message={confirmConfig?.message || ''}
        type={confirmConfig?.type}
      />
    </Box>
  )
}

export default LeavePage
