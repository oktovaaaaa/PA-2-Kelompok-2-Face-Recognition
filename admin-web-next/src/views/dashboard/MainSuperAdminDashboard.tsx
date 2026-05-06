// src/views/dashboard/MainSuperAdminDashboard.tsx
'use client'

import { useState, useEffect } from 'react'

import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import Avatar from '@mui/material/Avatar'
import CircularProgress from '@mui/material/CircularProgress'

import Chip from '@mui/material/Chip'

import { dashboardService } from '@/libs/dashboardService'
import type { Profile} from '@/libs/settingService';
import { settingService, formatImageUrl } from '@/libs/settingService'
import { formatFullDate } from '@/utils/dateFormatter'
import RegistrationTrendChart from './RegistrationTrendChart'
import RoleDistributionChart from './RoleDistributionChart'
import GlobalOfficeMap from './GlobalOfficeMap'

const MainSuperAdminDashboard = () => {
    const [stats, setStats] = useState<any>(null)
    const [recentCompanies, setRecentCompanies] = useState<any[]>([])
    const [recentUsers, setRecentUsers] = useState<any[]>([])
    const [trend, setTrend] = useState<number[]>([])
    const [years, setYears] = useState<number[]>([])
    const [profile, setProfile] = useState<Profile | null>(null)
    const [loading, setLoading] = useState(true)
    const [year, setYear] = useState(new Date().getFullYear())

    const fetchData = async () => {
        setLoading(true)

        try {
            const [statsData, trendData, profData, yearsData] = await Promise.all([
                dashboardService.getSuperAdminStats(),
                dashboardService.getRegistrationTrend(year),
                settingService.getProfile(),
                dashboardService.getRegistrationYears()
            ])

            setStats(statsData.stats)
            setRecentCompanies(statsData.recent_companies || [])
            setRecentUsers(statsData.recent_users || [])
            setTrend(trendData)
            setProfile(profData)
            setYears(yearsData)

            if (yearsData.length > 0 && !yearsData.includes(year)) {
                setYear(yearsData[0])
            }
        } catch (error) {
            console.error('Error fetching Super Admin data:', error)
        } finally {
            setLoading(false)
        }
    }

    const fetchTrend = async (selectedYear: number) => {
        try {
            const trendData = await dashboardService.getRegistrationTrend(selectedYear)

            setTrend(trendData)
            setYear(selectedYear)
        } catch (error) {
            console.error('Error fetching trend data:', error)
        }
    }

    useEffect(() => {
        fetchData()
    }, [])

    if (loading) return (
        <Box className='flex flex-col items-center justify-center min-h-[60vh] gap-6'>
            <CircularProgress color='primary' size={50} thickness={4} />
            <Box className='text-center'>
                <Typography variant='h6' className='font-bold uppercase tracking-[0.2em] text-slate-400'>
                    Mengautentikasi Sistem
                </Typography>
                <Typography variant='caption' className='text-slate-500 animate-pulse'>
                    Mengamankan koneksi terenkripsi ke database pusat...
                </Typography>
            </Box>
        </Box>
    )

    const statCards = [
        { label: 'Total Perusahaan', value: stats?.total_companies || 0, icon: 'ri-building-2-line', color: 'from-blue-600 to-indigo-600', shadow: 'shadow-blue-500/20' },
        { label: 'Total User Aktif', value: stats?.total_active_employees || 0, icon: 'ri-team-line', color: 'from-emerald-500 to-teal-600', shadow: 'shadow-emerald-500/20' },
        { label: 'Tahun Operasional', value: years.length, icon: 'ri-shield-flash-line', color: 'from-purple-600 to-pink-600', shadow: 'shadow-purple-500/20' }
    ]

    return (
        <Grid container spacing={6} className='p-2'>
            {/* Premium Header - Adaptable */}
            <Grid item xs={12}>
                <Card className='relative overflow-hidden border-none rounded-[2.5rem] bg-[var(--mui-palette-primary-dark)] shadow-2xl group'>
                    <Box className='absolute inset-0 bg-gradient-to-r from-indigo-600/20 to-purple-600/20 opacity-50' />
                    <Box className='absolute -top-24 -right-24 w-64 h-64 bg-indigo-500/10 rounded-full blur-3xl group-hover:bg-indigo-500/20 transition-all duration-700' />
                    
                    <CardContent className='relative p-10 flex flex-col md:flex-row justify-between items-center gap-8'>
                        <Box className='flex items-center gap-8'>
                            <Box className='relative'>
                                <Box className='absolute -inset-1 bg-gradient-to-tr from-indigo-500 to-purple-500 rounded-full blur opacity-75 animate-pulse' />
                                <Avatar 
                                    src={formatImageUrl(profile?.photo_url) || '/images/avatars/1.png'} 
                                    sx={{ width: 80, height: 80, border: '4px solid var(--mui-palette-background-paper)', boxShadow: '0 10px 25px -5px rgba(0,0,0,0.3)' }}
                                />
                            </Box>
                            <Box>
                                <Typography variant='h4' className='font-black text-white tracking-tight mbe-1'>
                                    Selamat Datang, <span className='text-amber-300 drop-shadow-sm'>{profile?.name || 'Admin'}</span>!
                                </Typography>
                                <Box className='flex items-center gap-3'>
                                    <Chip 
                                        label="Pengelola Utama" 
                                        size="small" 
                                        className='bg-white/10 text-white font-bold border border-white/20'
                                    />
                                    <Typography className='text-white/60 text-sm font-medium'>
                                        Pusat kendali untuk memantau pertumbuhan pengguna dan aktivitas unit bisnis Anda.
                                    </Typography>
                                </Box>
                            </Box>
                        </Box>
                        
                        <Box className='flex gap-4'>
                            <Box className='px-6 py-3 bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 text-center'>
                                <Typography variant='h5' className='font-black text-white'>{stats?.total_companies || 0}</Typography>
                                <Typography variant='caption' className='text-white/60 uppercase font-bold tracking-widest'>Unit</Typography>
                            </Box>
                            <Box className='px-6 py-3 bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 text-center'>
                                <Typography variant='h5' className='font-black text-white'>{stats?.total_active_employees || 0}</Typography>
                                <Typography variant='caption' className='text-white/60 uppercase font-bold tracking-widest'>Aktif</Typography>
                            </Box>
                        </Box>
                    </CardContent>
                </Card>
            </Grid>

            {/* Glowing Quick Stats - Theme Aware */}
            {statCards.map((card, idx) => (
                <Grid item xs={12} sm={4} key={idx}>
                    <Card className={`relative border-none rounded-[2rem] bg-[var(--mui-palette-background-paper)] overflow-hidden ${card.shadow} hover:-translate-y-2 transition-all duration-300`}>
                        <Box className={`absolute top-0 left-0 w-1 h-full bg-gradient-to-b ${card.color}`} />
                        <CardContent className='p-8'>
                            <Box className='flex justify-between items-center mbe-6'>
                                <Box className={`p-4 bg-gradient-to-br ${card.color} rounded-[1.25rem] shadow-lg flex items-center justify-center`}>
                                    <i className={`${card.icon} text-3xl text-white`} />
                                </Box>
                                <Typography variant='h3' className='font-black text-[var(--mui-palette-text-primary)] tracking-tighter'>
                                    {card.value}
                                </Typography>
                            </Box>
                            <Typography variant='subtitle2' className='font-bold text-[var(--mui-palette-text-secondary)] uppercase tracking-[0.15em]'>
                                {card.label}
                            </Typography>
                        </CardContent>
                    </Card>
                </Grid>
            ))}

            {/* Priority Row: Trend & User Activity - Moved Up */}
            <Grid item xs={12} md={7}>
                <RegistrationTrendChart data={trend} year={year} years={years} onYearChange={fetchTrend} />
            </Grid>

            <Grid item xs={12} md={5}>
                <Card className='border-none rounded-[2.5rem] bg-[var(--mui-palette-background-paper)] text-[var(--mui-palette-text-primary)] shadow-2xl h-full'>
                    <CardContent className='p-8'>
                        <Box className='flex justify-between items-center mbe-8'>
                            <Box>
                                <Typography variant='h6' className='font-black'>Alur Aktivitas Sistem</Typography>
                                <Typography variant='caption' className='text-[var(--mui-palette-text-secondary)]'>Pembaruan langsung antar perusahaan</Typography>
                            </Box>
                            <Box className='p-2 bg-indigo-500/20 rounded-xl'>
                                <i className='ri-pulse-line text-indigo-400' />
                            </Box>
                        </Box>

                        <Box className='flex flex-col gap-8'>
                            {recentUsers.map((user, i) => (
                                <Box key={user.id} className='flex gap-5 relative'>
                                    {i < recentUsers.length - 1 && (
                                        <Box className='absolute left-[19px] top-[40px] bottom-[-32px] w-[2px] bg-gradient-to-b from-indigo-500/50 to-transparent' />
                                    )}
                                    <Box className='relative'>
                                        <Avatar 
                                            src={user.photo_url ? `http://localhost:8080${user.photo_url}` : undefined} 
                                            sx={{ width: 40, height: 40, border: '2px solid var(--mui-palette-divider)', boxShadow: '0 0 15px rgba(99, 102, 241, 0.2)' }}
                                        >
                                            {user.name.charAt(0)}
                                        </Avatar>
                                        <Box className='absolute -bottom-1 -right-1 w-4 h-4 bg-emerald-500 rounded-full border-2 border-[var(--mui-palette-background-paper)]' />
                                    </Box>
                                    <Box>
                                        <Typography variant='body2' className='text-[var(--mui-palette-text-primary)] font-bold'>
                                            {user.name} <span className='text-[var(--mui-palette-text-secondary)] font-normal'>bergabung sebagai</span> {user.role?.replace('ROLE_', '').replace('_', ' ')}
                                        </Typography>
                                        <Typography variant='caption' className='flex items-center gap-2 text-indigo-500 font-medium mt-1'>
                                            <i className='ri-community-line' /> {user.company?.name}
                                        </Typography>
                                        <Typography variant='caption' className='block text-[var(--mui-palette-text-secondary)] mt-0.5'>
                                            {formatFullDate(user.created_at)}
                                        </Typography>
                                    </Box>
                                </Box>
                            ))}
                        </Box>
                    </CardContent>
                </Card>
            </Grid>

            {/* Middle Row: Company Spotlights */}
            <Grid item xs={12}>
                <Box className='flex justify-between items-center mbe-6 px-2'>
                    <Box>
                        <Typography variant='h5' className='font-black text-[var(--mui-palette-text-primary)]'>Sorotan Perusahaan</Typography>
                        <Typography variant='body2' className='text-[var(--mui-palette-text-secondary)]'>Memantau unit bisnis yang baru bergabung</Typography>
                    </Box>
                    <Box className='hidden sm:flex gap-2'>
                        <Chip label="5 Terbaru" variant="outlined" size="small" className='font-bold' />
                        <Chip label="Terverifikasi" className='bg-[var(--mui-palette-success-light)] text-[var(--mui-palette-success-dark)] font-bold border-none' size="small" />
                    </Box>
                </Box>
                
                <Grid container spacing={4}>
                    {recentCompanies.map((company) => (
                        <Grid item xs={12} sm={6} md={4} lg={2.4} key={company.id}>
                            <Card className='group h-full border-none rounded-3xl bg-[var(--mui-palette-background-paper)] shadow-sm hover:shadow-xl hover:bg-[var(--mui-palette-action-hover)] transition-all duration-300 cursor-pointer overflow-hidden'>
                                <Box className='h-2 bg-gradient-to-r from-indigo-500 to-blue-500 opacity-0 group-hover:opacity-100 transition-opacity' />
                                <CardContent className='p-6 flex flex-col items-center text-center'>
                                    <Box className='relative mbe-4'>
                                        <Box className='absolute inset-0 bg-indigo-500 rounded-3xl blur-xl opacity-0 group-hover:opacity-20 transition-opacity' />
                                        <Avatar 
                                            src={company.logo_url ? `http://localhost:8080${company.logo_url}` : undefined}
                                            sx={{ width: 64, height: 64, bgcolor: 'primary.light', color: 'primary.main', fontSize: '1.5rem', fontWeight: 900, borderRadius: '18px', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}
                                        >
                                            {company.name.charAt(0)}
                                        </Avatar>
                                    </Box>
                                    <Typography variant='subtitle1' className='font-black text-[var(--mui-palette-text-primary)] line-clamp-1 mbe-1'>
                                        {company.name}
                                    </Typography>
                                    <Typography variant='caption' className='text-[var(--mui-palette-text-secondary)] font-medium mbe-4 line-clamp-1'>
                                        {company.email}
                                    </Typography>
                                    
                                    <Box className='w-full pt-4 border-t border-[var(--mui-palette-divider)] flex flex-col gap-2'>
                                        <Box className='flex items-center gap-2 text-[var(--mui-palette-text-secondary)]'>
                                            <i className='ri-phone-line text-xs' />
                                            <Typography variant='caption' className='font-bold truncate'>{company.phone || 'N/A'}</Typography>
                                        </Box>
                                        <Box className='flex items-center gap-2 text-[var(--mui-palette-text-secondary)]'>
                                            <i className='ri-map-pin-2-line text-xs' />
                                            <Typography variant='caption' className='font-medium truncate'>{company.address || 'Kantor Global'}</Typography>
                                        </Box>
                                    </Box>
                                </CardContent>
                            </Card>
                        </Grid>
                    ))}
                    {recentCompanies.length === 0 && (
                         <Grid item xs={12}>
                            <Box className='bg-[var(--mui-palette-background-default)] rounded-3xl p-10 text-center border-2 border-dashed border-[var(--mui-palette-divider)]'>
                                <Typography className='text-[var(--mui-palette-text-secondary)]'>Belum ada unit bisnis yang terdeteksi.</Typography>
                            </Box>
                         </Grid>
                    )}
                </Grid>
            </Grid>

            {/* Bottom Row Visualization: Globe & Role Distribution - Moved Down */}
            <Grid item xs={12} md={7}>
                <GlobalOfficeMap companies={recentCompanies} />
            </Grid>

            <Grid item xs={12} md={5}>
                <RoleDistributionChart distribution={stats?.role_distribution || {}} />
            </Grid>
        </Grid>
    )
}

export default MainSuperAdminDashboard
