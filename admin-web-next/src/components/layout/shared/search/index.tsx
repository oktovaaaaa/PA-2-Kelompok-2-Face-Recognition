'use client'

import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'

// MUI Imports
import IconButton from '@mui/material/IconButton'
import Dialog from '@mui/material/Dialog'
import DialogContent from '@mui/material/DialogContent'
import TextField from '@mui/material/TextField'
import InputAdornment from '@mui/material/InputAdornment'
import List from '@mui/material/List'
import ListItem from '@mui/material/ListItem'
import ListItemButton from '@mui/material/ListItemButton'
import ListItemIcon from '@mui/material/ListItemIcon'
import ListItemText from '@mui/material/ListItemText'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import Avatar from '@mui/material/Avatar'
import Chip from '@mui/material/Chip'

// Hook Imports
import useVerticalNav from '@menu/hooks/useVerticalNav'

// Service Imports
import { employeeService, type Employee } from '@/libs/employeeService'

interface SearchItem {
  id: string
  name: string
  url?: string
  icon?: string
  type: 'MENU' | 'EMPLOYEE'
  data?: Employee
}

const MENU_ITEMS: SearchItem[] = [
  { id: 'beranda', name: 'Beranda / Dashboard', url: '/dashboard', icon: 'ri-home-7-line', type: 'MENU' },
  { id: 'persetujuan', name: 'Persetujuan Karyawan', url: '/persetujuan', icon: 'ri-user-follow-line', type: 'MENU' },
  { id: 'karyawan', name: 'Data Karyawan', url: '/karyawan', icon: 'ri-team-line', type: 'MENU' },
  { id: 'jabatan', name: 'Manajemen Jabatan', url: '/jabatan', icon: 'ri-briefcase-line', type: 'MENU' },
  { id: 'cuti', name: 'Cuti & Izin', url: '/cuti', icon: 'ri-calendar-event-line', type: 'MENU' },
  { id: 'libur', name: 'Hari Libur', url: '/libur', icon: 'ri-calendar-2-line', type: 'MENU' },
  { id: 'absensi', name: 'Laporan Absensi', url: '/absensi', icon: 'ri-file-list-3-line', type: 'MENU' },
  { id: 'payroll', name: 'Laporan Payroll', url: '/payroll', icon: 'ri-money-dollar-box-line', type: 'MENU' },
  { id: 'bonus', name: 'Bonus & Sanksi', url: '/pelanggaran-bonus', icon: 'ri-medal-line', type: 'MENU' },
  { id: 'profile', name: 'Informasi Profil / Akun', url: '/account-settings?tab=account', icon: 'ri-user-settings-line', type: 'MENU' },
  { id: 'security', name: 'Keamanan Akun (Ganti Password)', url: '/account-settings?tab=security', icon: 'ri-shield-keyhole-line', type: 'MENU' },
  { id: 'devices', name: 'Daftar Perangkat Aktif', url: '/account-settings?tab=devices', icon: 'ri-device-line', type: 'MENU' },
  { id: 'instansi', name: 'Detail Instansi / Perusahaan', url: '/account-settings?tab=company', icon: 'ri-building-line', type: 'MENU' },
  { id: 'operasional', name: 'Pengaturan Operasional', url: '/operasional', icon: 'ri-settings-4-line', type: 'MENU' },
]

const NavSearch = () => {
  // States
  const [open, setOpen] = useState(false)
  const [searchValue, setSearchValue] = useState('')
  const [employees, setEmployees] = useState<Employee[]>([])
  const [filteredResults, setFilteredResults] = useState<SearchItem[]>([])

  // Hooks
  const { isBreakpointReached } = useVerticalNav()
  const router = useRouter()

  // Load employees for search
  useEffect(() => {
    if (open) {
      employeeService.getEmployees('ACTIVE').then(setEmployees).catch(console.error)
    }
  }, [open])

  // Filter logic
  useEffect(() => {
    if (!searchValue.trim()) {
      setFilteredResults([])
      return
    }

    const query = searchValue.toLowerCase()
    
    const menuMatches = MENU_ITEMS.filter(item => 
      item.name.toLowerCase().includes(query)
    )

    const employeeMatches = employees
      .filter(emp => emp.name.toLowerCase().includes(query) || emp.email.toLowerCase().includes(query))
      .map(emp => ({
        id: emp.id,
        name: emp.name,
        type: 'EMPLOYEE' as const,
        data: emp
      }))

    setFilteredResults([...menuMatches, ...employeeMatches].slice(0, 8))
  }, [searchValue, employees])

  // Keyboard shortcut
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
        event.preventDefault()
        setOpen(true)
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  const handleClose = () => {
    setOpen(false)
    setSearchValue('')
  }

  const handleSelect = (item: SearchItem) => {
    handleClose()
    if (item.type === 'MENU' && item.url) {
      router.push(item.url)
    } else if (item.type === 'EMPLOYEE') {
      router.push(`/dashboard?employee_id=${item.id}`)
    }
  }

  return (
    <>
      {isBreakpointReached ? (
        <IconButton className='text-textPrimary' onClick={() => setOpen(true)}>
          <i className='ri-search-line' />
        </IconButton>
      ) : (
        <div 
          className='flex items-center cursor-pointer gap-2 bg-actionHover px-4 py-1.5 rounded-full border border-divider hover:border-primary transition-colors'
          onClick={() => setOpen(true)}
        >
          <i className='ri-search-line text-textSecondary' />
          <div className='whitespace-nowrap select-none text-textDisabled text-sm'>Cari data / menu...</div>
          <div className='bg-background px-1.5 py-0.5 rounded border border-divider text-[10px] font-bold text-textSecondary ml-2'>⌘K</div>
        </div>
      )}

      <Dialog 
        open={open} 
        onClose={handleClose} 
        fullWidth 
        maxWidth="sm"
        PaperProps={{
          sx: { borderRadius: '12px', mt: '10vh' }
        }}
        scroll="paper"
      >
        <DialogContent sx={{ p: 0 }}>
          <Box sx={{ p: 4, borderBottom: '1px solid', borderColor: 'divider' }}>
            <TextField
              fullWidth
              autoFocus
              placeholder="Ketik nama karyawan atau menu (misal: Payroll)..."
              variant="standard"
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
              InputProps={{
                disableUnderline: true,
                startAdornment: (
                  <InputAdornment position="start">
                    <i className="ri-search-line text-xl text-primary" />
                  </InputAdornment>
                ),
                endAdornment: searchValue && (
                  <IconButton size="small" onClick={() => setSearchValue('')}>
                    <i className="ri-close-line" />
                  </IconButton>
                ),
                style: { fontSize: '1.1rem' }
              }}
            />
          </Box>

          <Box sx={{ maxHeight: '400px', overflow: 'auto' }}>
            {searchValue && filteredResults.length === 0 ? (
              <Box sx={{ p: 10, textAlign: 'center' }}>
                <i className="ri-search-eye-line text-4xl text-textDisabled mb-2 block" />
                <Typography color="textDisabled">Tidak ditemukan hasil untuk "{searchValue}"</Typography>
              </Box>
            ) : !searchValue ? (
              <Box sx={{ p: 4 }}>
                <Typography variant="caption" sx={{ fontWeight: 'bold', textTransform: 'uppercase', color: 'text.disabled', ml: 2, mb: 1, display: 'block' }}>
                  Menu Populer
                </Typography>
                <List>
                  {MENU_ITEMS.slice(0, 4).map((item) => (
                    <ListItem key={item.id} disablePadding>
                      <ListItemButton onClick={() => handleSelect(item)} sx={{ borderRadius: '8px' }}>
                        <ListItemIcon sx={{ minWidth: 40 }}>
                          <i className={`${item.icon} text-xl`} />
                        </ListItemIcon>
                        <ListItemText primary={item.name} />
                        <i className="ri-arrow-right-s-line text-textDisabled" />
                      </ListItemButton>
                    </ListItem>
                  ))}
                </List>
              </Box>
            ) : (
              <List sx={{ p: 2 }}>
                {filteredResults.map((item) => (
                  <ListItem key={item.id} disablePadding>
                    <ListItemButton 
                      onClick={() => handleSelect(item)} 
                      sx={{ borderRadius: '8px', mb: 0.5 }}
                    >
                      <ListItemIcon sx={{ minWidth: 48 }}>
                        {item.type === 'EMPLOYEE' ? (
                          <Avatar 
                            src={item.data?.photo_url ? `http://localhost:8080${item.data.photo_url}` : undefined}
                            sx={{ width: 32, height: 32 }}
                          >
                            {item.name.charAt(0)}
                          </Avatar>
                        ) : (
                          <Box sx={{ width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: 'primary.lighter', borderRadius: '8px', color: 'primary.main' }}>
                            <i className={`${item.icon} text-lg`} />
                          </Box>
                        )}
                      </ListItemIcon>
                      <ListItemText 
                        primary={item.name} 
                        secondary={item.type === 'EMPLOYEE' ? item.data?.position_name || 'Karyawan' : 'Menu Navigasi'}
                        primaryTypographyProps={{ fontWeight: '500' }}
                      />
                      {item.type === 'EMPLOYEE' && (
                        <Chip label="Filter Dashboard" size="small" variant="outlined" color="primary" sx={{ fontSize: '10px' }} />
                      )}
                    </ListItemButton>
                  </ListItem>
                ))}
              </List>
            )}
          </Box>
          
          <Box sx={{ p: 2, bgcolor: 'action.hover', display: 'flex', gap: 4, justifyContent: 'center' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Chip label="ENTER" size="small" sx={{ height: 20, fontSize: '9px', fontWeight: 'bold' }} />
              <Typography variant="caption">Pilih</Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Chip label="ESC" size="small" sx={{ height: 20, fontSize: '9px', fontWeight: 'bold' }} />
              <Typography variant="caption">Tutup</Typography>
            </Box>
          </Box>
        </DialogContent>
      </Dialog>
    </>
  )
}

export default NavSearch
