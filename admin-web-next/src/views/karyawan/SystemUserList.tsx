'use client'

import React, { useState, useEffect, useCallback } from 'react'

import {
  Card,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Typography,
  TextField,
  InputAdornment,
  Box,
  Avatar,
  Tab,
  Tabs,
  CircularProgress,
  TablePagination,
  IconButton,
  Tooltip,
  Dialog,
  DialogContent,
  DialogTitle,
  Divider,
  Autocomplete,
  Switch,
  FormControlLabel,
  Button,
  Grid
} from '@mui/material'

import { employeeService, Employee } from '../../libs/employeeService'
import { formatFullDate } from '@/utils/dateFormatter'

const SystemUserList = () => {
  // States
  const [users, setUsers] = useState<any[]>([])
  const [companies, setCompanies] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState<string>('ACTIVE')
  const [companyIdFilter, setCompanyIdFilter] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState('')

  // Modal States
  const [selectedUser, setSelectedUser] = useState<any | null>(null)
  const [selectedCompany, setSelectedCompany] = useState<any | null>(null)
  const [isUpdatingStatus, setIsUpdatingStatus] = useState(false)

  // Pagination States
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)

  const loadData = useCallback(async () => {
    setLoading(true)

    try {
      const [userData, companyData] = await Promise.all([
        employeeService.getAllSystemUsers(statusFilter),
        employeeService.getAllCompanies()
      ])

      setUsers(userData || [])
      setCompanies(companyData || [])
      setPage(0)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }, [statusFilter])

  useEffect(() => {
    loadData()
  }, [loadData])

  const handleToggleCompanyStatus = async (id: string, currentStatus: string) => {
    const newStatus = currentStatus === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE'

    setIsUpdatingStatus(true)

    try {
      await employeeService.updateCompanyStatus(id, newStatus)
      await loadData()

      if (selectedCompany && selectedCompany.id === id) {
        setSelectedCompany({ ...selectedCompany, status: newStatus })
      }
    } catch (error) {
      console.error(error)
    } finally {
      setIsUpdatingStatus(false)
    }
  }

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const filteredUsers = users.filter((u: any) => {
    const matchesSearch = u.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      u.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (u.company?.name || '').toLowerCase().includes(searchQuery.toLowerCase())

    const matchesCompany = !companyIdFilter || u.company_id === companyIdFilter

    return matchesSearch && matchesCompany
  })

  const sortedUsers = [...filteredUsers].sort((a, b) => {
    const compA = a.company?.name || 'Sistem'
    const compB = b.company?.name || 'Sistem'

    if (compA !== compB) return compA.localeCompare(compB)

    if (a.role === 'ADMIN' && b.role !== 'ADMIN') return -1
    if (a.role !== 'ADMIN' && b.role === 'ADMIN') return 1

    return a.name.localeCompare(b.name)
  })

  const paginatedUsers = sortedUsers.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)

  let lastCompany = ''

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {/* Page Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', flexWrap: 'wrap', gap: 4 }}>
        <Box>
          <Typography variant='h4' fontWeight='900' color='primary' className='tracking-tight' gutterBottom>
            Daftar Seluruh User Sistem
          </Typography>
          <Typography variant='body2' className='text-[var(--mui-palette-text-secondary)] font-medium'>
            Pusat manajemen lintas organisasi. Kelola akses, pantau biodata, dan kontrol status operasional unit bisnis.
          </Typography>
        </Box>
        <Box className='flex gap-3 bg-[var(--mui-palette-background-paper)] p-2 rounded-2xl border border-[var(--mui-palette-divider)]'>
          <Chip icon={<i className='ri-team-line' />} label={`${users.length} Total User`} variant="outlined" className='font-bold' />
          <Chip icon={<i className='ri-building-line' />} label={`${companies.length} Unit Perusahaan`} className='bg-primary/10 text-primary font-bold border-none' />
        </Box>
      </Box>

      <Card sx={{ border: 'none', borderRadius: '1.5rem', boxShadow: '0 4px 20px rgba(0,0,0,0.05)' }}>
        <Box sx={{ px: 6, py: 5, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 6, flexWrap: 'wrap' }}>
          <Box className='flex items-center gap-4'>
            <Tabs
              value={statusFilter}
              onChange={(_, val) => setStatusFilter(val)}
              sx={{
                '& .MuiTab-root': { fontWeight: 800, fontSize: '0.9rem', minHeight: 48, borderRadius: '12px' },
                '& .Mui-selected': { color: 'primary.main' }
              }}
            >
              <Tab label="Aktif" value="ACTIVE" />
              <Tab label="Diberhentikan" value="RESIGNED" />
            </Tabs>
            <Divider orientation="vertical" flexItem sx={{ mx: 2, height: 30, my: 'auto' }} />
            <Autocomplete
              size="small"
              options={companies}
              getOptionLabel={(option) => option.name}
              sx={{ width: 250 }}
              value={companies.find(c => c.id === companyIdFilter) || null}
              onChange={(_, val) => setCompanyIdFilter(val?.id || null)}
              renderInput={(params) => (
                <TextField
                  {...params}
                  placeholder="Filter Perusahaan..."
                  InputProps={{
                    ...params.InputProps,
                    startAdornment: (
                      <InputAdornment position="start">
                        <i className='ri-filter-3-line text-primary' />
                      </InputAdornment>
                    )
                  }}
                />
              )}
            />
          </Box>

          <TextField
            size='small'
            placeholder='Cari Nama / Email / Perusahaan...'
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            sx={{
              width: { xs: '100%', sm: 350 },
              '& .MuiOutlinedInput-root': { borderRadius: '12px', bgcolor: 'action.hover', border: 'none' },
              '& .MuiOutlinedInput-notchedOutline': { border: 'none' }
            }}
            InputProps={{
              startAdornment: (
                <InputAdornment position='start'>
                  <i className='ri-search-2-line text-primary' />
                </InputAdornment>
              )
            }}
          />
        </Box>
      </Card>

      <Card sx={{ border: 'none', borderRadius: '1.5rem', boxShadow: '0 4px 20px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
        <TableContainer component={Paper} elevation={0}>
          {loading ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', p: 15, gap: 4 }}>
              <CircularProgress size={48} thickness={4} />
              <Typography variant="caption" className='font-bold uppercase tracking-widest text-slate-400'>Menyelaraskan Data Lintas Server...</Typography>
            </Box>
          ) : (
            <Table sx={{ minWidth: 800 }}>
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase', tracking: '0.1em' }}>Data Pengguna</TableCell>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase', tracking: '0.1em' }}>Identitas & Hak Akses</TableCell>
                  <TableCell sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase', tracking: '0.1em' }}>Jabatan</TableCell>
                  <TableCell align="center" sx={{ fontWeight: '800', p: 4, fontSize: '0.75rem', textTransform: 'uppercase', tracking: '0.1em' }}>Status Akun</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginatedUsers.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={4} align='center' sx={{ py: 15 }}>
                      <Box className='flex flex-col items-center gap-2 opacity-30'>
                        <i className='ri-user-search-line text-6xl' />
                        <Typography className='font-bold'>Tidak ada data user yang sesuai dengan kriteria.</Typography>
                      </Box>
                    </TableCell>
                  </TableRow>
                ) : paginatedUsers.map((row: any) => {
                  const currentCompany = row.company?.name || 'Lainnya / Sistem'
                  const showHeader = currentCompany !== lastCompany

                  lastCompany = currentCompany

                  return (
                    <React.Fragment key={row.id}>
                      {showHeader && (
                        <TableRow
                          sx={{ bgcolor: 'var(--mui-palette-primary-lighter)', cursor: 'pointer', '&:hover': { opacity: 0.8 } }}
                          onClick={() => setSelectedCompany(row.company)}
                        >
                          <TableCell colSpan={4} sx={{ py: 3, px: 6 }}>
                            <Box className='flex justify-between items-center'>
                              <Typography variant='subtitle2' color='primary' className='font-black uppercase tracking-[0.15em] flex items-center gap-3'>
                                <i className='ri-community-line text-xl' />
                                Unit Perusahaan: {currentCompany}
                              </Typography>
                              <Box className='flex items-center gap-4'>
                                {row.company?.status === 'INACTIVE' && (
                                  <Chip label="Nonaktif" size="small" className='bg-red-500 text-white font-black' />
                                )}
                                <Typography variant="caption" className='font-bold opacity-60'>Klik untuk Manajemen Unit <i className='ri-arrow-right-up-line' /></Typography>
                              </Box>
                            </Box>
                          </TableCell>
                        </TableRow>
                      )}
                      <TableRow
                        hover
                        onClick={() => setSelectedUser(row)}
                        sx={{ cursor: 'pointer', '&:last-child td, &:last-child th': { border: 0 } }}
                      >
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Avatar
                              src={row.photo_url ? `http://localhost:8080${row.photo_url}` : undefined}
                              sx={{ mr: 4, width: 44, height: 44, border: '2px solid var(--mui-palette-divider)' }}
                            >
                              {row.name.charAt(0)}
                            </Avatar>
                            <Box>
                              <Typography variant='body2' fontWeight="900" color='text.primary'>{row.name}</Typography>
                              <Typography variant='caption' className='text-indigo-500 font-bold uppercase text-[10px] tracking-widest'>ID: {row.id.substring(0, 8)}</Typography>
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant='body2' className='font-medium' sx={{ display: 'block' }}>{row.email}</Typography>
                          <Chip
                            label={row.role === 'ADMIN' ? 'Bos' : (row.role === 'SUPER_ADMIN' ? 'System Root' : 'Karyawan')}
                            size='small'
                            className={`mt-2 font-black tracking-widest text-[9px] uppercase ${row.role === 'SUPER_ADMIN' ? 'bg-indigo-600 text-white' : (row.role === 'ADMIN' ? 'bg-amber-500 text-white' : 'bg-slate-100 text-slate-600')}`}
                            sx={{ height: 18 }}
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant='body2' className='font-bold text-slate-600'>{row.position?.name || '-'}</Typography>
                          <Typography variant='caption' className='text-slate-400'>{row.role === 'ADMIN' ? 'Bos' : (row.role === 'EMPLOYEE' ? 'Karyawan' : row.role)}</Typography>
                        </TableCell>
                        <TableCell align="center">
                          <Chip
                            label={row.status === 'ACTIVE' ? 'Aktif' : (row.status === 'RESIGNED' ? 'Diberhentikan' : (row.status === 'INACTIVE' ? 'Nonaktif' : row.status))}
                            color={row.status === 'ACTIVE' ? 'success' : 'error'}
                            size='small'
                            className='font-black text-[10px] px-2'
                            variant='filled'
                          />
                        </TableCell>
                      </TableRow>
                    </React.Fragment>
                  )
                })}
              </TableBody>
            </Table>
          )}
        </TableContainer>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component='div'
          count={filteredUsers.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Baris per halaman:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} dari ${count !== -1 ? count : `lebih dari ${to}`}`}
        />
      </Card>

      {/* Employee Profile Modal */}
      <Dialog
        open={!!selectedUser}
        onClose={() => setSelectedUser(null)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: '2rem', overflow: 'hidden' } }}
      >
        {selectedUser && (
          <DialogContent className='p-0'>
            <Box className='relative h-32 bg-gradient-to-r from-indigo-600 to-purple-600'>
              <Box className='absolute -bottom-12 left-8'>
                <Avatar
                  src={selectedUser.photo_url ? `http://localhost:8080${selectedUser.photo_url}` : undefined}
                  sx={{ width: 100, height: 100, border: '6px solid var(--mui-palette-background-paper)', boxShadow: '0 10px 20px rgba(0,0,0,0.1)' }}
                >
                  {selectedUser.name.charAt(0)}
                </Avatar>
              </Box>
            </Box>
            <Box className='pt-16 px-10 pb-10'>
              <Box className='flex justify-between items-start mbe-6'>
                <Box>
                  <Typography variant='h5' className='font-black'>{selectedUser.name}</Typography>
                  <Typography color='primary' className='font-bold uppercase tracking-widest text-xs'>
                    <i className='ri-community-line mie-1' /> {selectedUser.company?.name}
                  </Typography>
                </Box>
                <Chip label={selectedUser.status === 'ACTIVE' ? 'Aktif' : (selectedUser.status === 'RESIGNED' ? 'Diberhentikan' : 'Nonaktif')} color={selectedUser.status === 'ACTIVE' ? 'success' : 'error'} className='font-black' />
              </Box>

              <Divider className='mbe-6' />

              <Grid container spacing={6}>
                <Grid item xs={6}>
                  <Typography variant='caption' className='block font-bold uppercase text-slate-400 mbe-1'>Alamat Email</Typography>
                  <Typography variant='body2' className='font-black'>{selectedUser.email}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant='caption' className='block font-bold uppercase text-slate-400 mbe-1'>Nomor Telepon</Typography>
                  <Typography variant='body2' className='font-black'>{selectedUser.phone || '-'}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant='caption' className='block font-bold uppercase text-slate-400 mbe-1'>Jabatan / Peran</Typography>
                  <Typography variant='body2' className='font-black'>{selectedUser.position?.name || selectedUser.role}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant='caption' className='block font-bold uppercase text-slate-400 mbe-1'>Bergabung Pada</Typography>
                  <Typography variant='body2' className='font-black'>{formatFullDate(selectedUser.created_at)}</Typography>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant='caption' className='block font-bold uppercase text-slate-400 mbe-1'>Alamat Lengkap</Typography>
                  <Typography variant='body2' className='font-medium'>{selectedUser.address || 'Alamat belum dilengkapi.'}</Typography>
                </Grid>
              </Grid>

              <Box className='mt-10 flex gap-4'>
                <Button fullWidth variant='contained' onClick={() => setSelectedUser(null)} className='rounded-xl font-bold py-3'>Tutup Profil</Button>
              </Box>
            </Box>
          </DialogContent>
        )}
      </Dialog>

      {/* Company Profile Modal */}
      <Dialog
        open={!!selectedCompany}
        onClose={() => setSelectedCompany(null)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: '2rem', overflow: 'hidden' } }}
      >
        {selectedCompany && (
          <DialogContent className='p-0'>
            <Box className='bg-primary/5 p-10 flex flex-col items-center gap-6'>
              <Avatar
                src={selectedCompany.logo_url ? `http://localhost:8080${selectedCompany.logo_url}` : undefined}
                sx={{ width: 100, height: 100, border: '4px solid white', boxShadow: '0 10px 25px rgba(0,0,0,0.1)', borderRadius: '2rem', bgcolor: 'primary.main' }}
              >
                {selectedCompany.name.charAt(0)}
              </Avatar>
              <Box className='text-center'>
                <Typography variant='h5' className='font-black mbe-1'>{selectedCompany.name}</Typography>
                <Typography variant='caption' className='font-bold uppercase tracking-widest text-slate-400'>Organization Hub ID: {selectedCompany.id.substring(0, 8)}</Typography>
              </Box>
            </Box>

            <Box className='p-10'>
              <Typography variant='subtitle2' className='font-black uppercase tracking-widest text-primary mbe-6'>Informasi Kantor</Typography>

              <Box className='flex flex-col gap-6 mbe-10'>
                <Box className='flex gap-4 items-center'>
                  <Box className='p-3 bg-slate-100 rounded-xl'><i className='ri-mail-line text-xl text-slate-500' /></Box>
                  <Box>
                    <Typography variant='caption' className='block font-bold uppercase text-slate-400'>Email Korporat</Typography>
                    <Typography className='font-black'>{selectedCompany.email}</Typography>
                  </Box>
                </Box>
                <Box className='flex gap-4 items-center'>
                  <Box className='p-3 bg-slate-100 rounded-xl'><i className='ri-phone-line text-xl text-slate-500' /></Box>
                  <Box>
                    <Typography variant='caption' className='block font-bold uppercase text-slate-400'>Kontak Kantor</Typography>
                    <Typography className='font-black'>{selectedCompany.phone || '-'}</Typography>
                  </Box>
                </Box>
                <Box className='flex gap-4 items-center'>
                  <Box className='p-3 bg-slate-100 rounded-xl'><i className='ri-map-pin-2-line text-xl text-slate-500' /></Box>
                  <Box>
                    <Typography variant='caption' className='block font-bold uppercase text-slate-400'>Lokasi Pusat</Typography>
                    <Typography className='font-black text-sm'>{selectedCompany.address}</Typography>
                    <Typography variant='caption' className='text-indigo-500 font-bold'>Coord: {selectedCompany.latitude?.toFixed(4)}, {selectedCompany.longitude?.toFixed(4)}</Typography>
                  </Box>
                </Box>
              </Box>

              <Box className='p-6 bg-[var(--mui-palette-action-hover)] rounded-[1.5rem] border border-[var(--mui-palette-divider)]'>
                <Box className='flex justify-between items-center'>
                  <Box>
                    <Typography variant='subtitle2' className='font-black'>Kontrol Operasional</Typography>
                    <Typography variant='caption' className='text-slate-500'>Aktifkan atau nonaktifkan akses untuk seluruh karyawan unit ini.</Typography>
                  </Box>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={selectedCompany.status === 'ACTIVE'}
                        onChange={() => handleToggleCompanyStatus(selectedCompany.id, selectedCompany.status)}
                        disabled={isUpdatingStatus}
                        color='success'
                      />
                    }
                    label=""
                  />
                </Box>
                {selectedCompany.status !== 'ACTIVE' && (
                  <Box className='mt-4 p-3 bg-red-100 rounded-lg flex items-center gap-3'>
                    <i className='ri-error-warning-fill text-red-600 text-xl' />
                    <Typography variant='caption' className='text-red-700 font-bold'>Akses untuk unit ini sedang dibekukan oleh sistem.</Typography>
                  </Box>
                )}
              </Box>

              <Box className='mt-8 flex gap-4'>
                <Button fullWidth variant='outlined' onClick={() => setSelectedCompany(null)} className='rounded-xl font-bold py-3'>Kembali</Button>
              </Box>
            </Box>
          </DialogContent>
        )}
      </Dialog>
    </Box>
  )
}

export default SystemUserList
