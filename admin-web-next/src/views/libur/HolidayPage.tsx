// src/views/libur/HolidayPage.tsx
'use client'

import React, { useState, useEffect, useCallback } from 'react'

import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'
import Button from '@mui/material/Button'
import Grid from '@mui/material/Grid'

import WorkDaySettings from './WorkDaySettings'
import HolidayList from './HolidayList'
import HolidayModal from './HolidayModal'
import ConfirmDialog from '@/components/ConfirmDialog'
import type { Holiday, AttendanceSettings } from '@/libs/holidayService';
import { holidayService } from '@/libs/holidayService'
import { useNotification } from '@/contexts/NotificationContext'

const HolidayPage = () => {
  const { showNotification } = useNotification()
  const [holidays, setHolidays] = useState<Holiday[]>([])
  const [settings, setSettings] = useState<AttendanceSettings | null>(null)
  const [workDays, setWorkDays] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [saveLoading, setSaveLoading] = useState(false)
  
  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isConfirmOpen, setIsConfirmOpen] = useState(false)
  const [selectedHoliday, setSelectedHoliday] = useState<Holiday | null>(null)
  const [deleteId, setDeleteId] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    setLoading(true)

    try {
      const hData = await holidayService.getHolidays()

      setHolidays(hData)
      
      const sData = await holidayService.getSettings()

      setSettings(sData)
      setWorkDays(sData.work_days.split(',').filter(d => d !== ''))
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData()
  }, [loadData])

  const handleToggleWorkDay = (day: string) => {
    setWorkDays(prev => 
      prev.includes(day) ? prev.filter(d => d !== day) : [...prev, day]
    )
  }

  const handleSaveWorkDays = async () => {
    if (!settings) return
    setSaveLoading(true)

    try {
      // Pastikan late_penalty_tiers dikirim sebagai objek/array, bukan string JSON mentah
      const payload = {
        ...settings,
        work_days: workDays.join(',')
      }
      
      if (typeof payload.late_penalty_tiers === 'string') {
        try {
          payload.late_penalty_tiers = JSON.parse(payload.late_penalty_tiers)
        } catch (e) {
          console.error("Failed to parse tiers", e)
        }
      }

      await holidayService.updateSettings(payload)
      showNotification('Jadwal kerja rutin berhasil diperbarui!', 'success')
    } catch (error) {
      showNotification('Gagal menyimpan jadwal kerja.', 'error')
    } finally {
      setSaveLoading(false)
    }
  }

  const handleCreateOrUpdateHoliday = async (formData: any) => {
    try {
      if (selectedHoliday) {
        await holidayService.updateHoliday(selectedHoliday.id, formData)
        showNotification('Hari libur berhasil diperbarui.', 'success')
      } else {
        await holidayService.createHoliday(formData)
        showNotification('Hari libur baru telah ditambahkan.', 'success')
      }

      setIsModalOpen(false)
      loadData()
    } catch (error) {
      showNotification('Gagal memproses data hari libur.', 'error')
    }
  }

  const handleDeleteHoliday = (id: string) => {
    setDeleteId(id)
    setIsConfirmOpen(true)
  }

  const confirmDelete = async () => {
    if (!deleteId) return

    try {
      await holidayService.deleteHoliday(deleteId)
      showNotification('Hari libur telah dihapus.', 'success')
      loadData()
    } catch (error) {
      showNotification('Gagal menghapus hari libur.', 'error')
    }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 6 }}>
        <Box>
            <Typography variant='h4' fontWeight='800' color='primary' gutterBottom>Manajemen Hari Libur</Typography>
            <Typography variant='body2' color='text.secondary'>Atur jadwal kerja rutin mingguan dan tentukan hari libur khusus perusahaan.</Typography>
        </Box>
        <Button 
            variant='contained' 
            startIcon={<i className='ri-add-line' />}
            onClick={() => { setSelectedHoliday(null); setIsModalOpen(true); }}
        >
            Tambah Libur
        </Button>
      </Box>

      {/* 1. Routine Work Days */}
      <WorkDaySettings 
        workDays={workDays}
        onToggle={handleToggleWorkDay}
        onSave={handleSaveWorkDays}
        loading={saveLoading}
      />

      {/* 2. Special Holidays List */}
      <HolidayList 
        holidays={holidays}
        onEdit={(h) => { setSelectedHoliday(h); setIsModalOpen(true); }}
        onDelete={handleDeleteHoliday}
      />

      {/* Holiday Form Modal */}
      <HolidayModal 
        open={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        holiday={selectedHoliday}
        onSubmit={handleCreateOrUpdateHoliday}
      />

      {/* Delete Confirmation */}
      <ConfirmDialog 
        open={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={confirmDelete}
        title="Hapus Hari Libur"
        message="Daftar hari libur yang dihapus tidak dapat dipulihkan. Lanjutkan?"
        type="error"
      />
    </Box>
  )
}

export default HolidayPage
