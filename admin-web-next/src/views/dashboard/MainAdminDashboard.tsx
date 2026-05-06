// src/views/dashboard/MainAdminDashboard.tsx
'use client'

import { useState, useEffect } from 'react'

import { useRouter } from 'next/navigation'

import Link from 'next/link'

import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import Button from '@mui/material/Button'
import Box from '@mui/material/Box'
import CircularProgress from '@mui/material/CircularProgress'

import type { DashboardSummary, AttendanceTrend } from '@/libs/dashboardService';
import { dashboardService } from '@/libs/dashboardService'
import InviteQRModal from './InviteQRModal'
import type { Profile } from '@/libs/settingService';
import { formatImageUrl, settingService } from '@/libs/settingService'
import { formatFullDate } from '@/utils/dateFormatter'

// Component Imports
import AttendanceSummaryPie from './AttendanceSummaryPie'
import AttendanceTrendLine from './AttendanceTrendLine'
import RecentAttendanceTable from './RecentAttendanceTable'

const MainAdminDashboard = () => {
    const [summary, setSummary] = useState<DashboardSummary | null>(null)
    const [trend, setTrend] = useState<AttendanceTrend | null>(null)
    const [profile, setProfile] = useState<Profile | null>(null)
    const [loading, setLoading] = useState(true)
    const [qrModalOpen, setQrModalOpen] = useState(false)
    const router = useRouter()

    const fetchData = async () => {
        setLoading(true)

        try {
            const [sumData, trendData, profData] = await Promise.all([
                dashboardService.getSummary(),
                dashboardService.getTrend('7days'),
                settingService.getProfile()
            ])

            setSummary(sumData)
            setTrend(trendData)
            setProfile(profData)
        } catch (error) {
            console.error('Error fetching dashboard data:', error)
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => {
        fetchData()
    }, [])

    const quickActions = [
        { icon: 'ri-calendar-check-line', label: 'Perizinan', color: 'bg-[#FEF3C7] text-[#D97706]', url: '/cuti' },
        { icon: 'ri-team-line', label: 'Karyawan', color: 'bg-[#DBEAFE] text-[#2563EB]', url: '/karyawan' },
        { icon: 'ri-briefcase-line', label: 'Jabatan', color: 'bg-[#E0E7FF] text-[#4F46E5]', url: '/jabatan' },
        { icon: 'ri-settings-4-line', label: 'Pengaturan', color: 'bg-[#F1F5F9] text-[#475569]', url: '/operasional' }
    ]

    if (loading) return (
        <Box className='flex flex-col items-center justify-center p-14 gap-6 bg-white rounded-3xl shadow-sm'>
            <CircularProgress color='primary' size={40} />
            <Typography variant='caption' className='font-bold uppercase tracking-widest text-slate-400'>
                Sinkronisasi Data Dashboard...
            </Typography>
        </Box>
    )

    return (
        <Grid container spacing={6}>
            {/* Header Sapaan */}
            <Grid item xs={12}>
                <Card className='bg-gradient-to-r from-slate-900 to-blue-900 text-white shadow-xl rounded-3xl overflow-hidden border-none'>
                    <CardContent className='p-8 flex flex-col sm:flex-row justify-between items-center gap-6'>
                        <Box className='flex items-center gap-6'>
                            <Box className='flex-shrink-0 w-[72px] h-[72px] p-1 border-2 border-white/20 rounded-full flex items-center justify-center overflow-hidden shadow-2xl'>
                                <img 
                                    src={formatImageUrl(profile?.photo_url) || '/images/avatars/1.png'} 
                                    alt='Avatar' 
                                    className='w-full h-full rounded-full object-cover'
                                />
                            </Box>
                            <Box>
                                <Typography variant='h5' className='font-bold text-white'>
                                    Halo, {profile?.name?.split(' ')[0] || 'Admin'} 👋
                                </Typography>
                                <Typography className='text-white/60 text-sm'>
                                    Semua data operasional terintegrasi dalam kendali Anda.
                                </Typography>
                            </Box>
                        </Box>
                        <Box className='flex items-center gap-2 bg-white/10 backdrop-blur-md px-4 py-2 rounded-full border border-white/10'>
                            <i className='ri-time-line text-blue-300' />
                            <Typography className='text-sm font-medium uppercase'>
                                {formatFullDate(new Date())}
                            </Typography>
                        </Box>
                    </CardContent>
                </Card>
            </Grid>

            {/* Charts Row */}
            <Grid item xs={12} lg={8}>
                <AttendanceTrendLine trend={trend} />
            </Grid>
            <Grid item xs={12} lg={4}>
                <AttendanceSummaryPie summary={summary} onRefresh={fetchData} />
            </Grid>

            {/* Main Content & Sidebar Row */}
            <Grid item xs={12} lg={8}>
                <Grid container spacing={4}>
                    {/* Quick Actions */}
                    <Grid item xs={12}>
                        <Box className='grid grid-cols-2 sm:grid-cols-4 gap-3'>
                            {quickActions.map((action, idx) => (
                                <Link key={idx} href={action.url} className='block no-underline'>
                                    <Card className='shadow-sm rounded-xl border-none hover:translate-y-[-2px] transition-all cursor-pointer bg-card'>
                                        <CardContent className='p-3 flex flex-col items-center gap-2'>
                                            <Box className={`p-3 rounded-lg ${action.color}`}>
                                                <i className={`${action.icon} text-xl`} />
                                            </Box>
                                            <Typography variant='caption' className='font-bold uppercase tracking-wider text-[10px]' color='text.secondary'>{action.label}</Typography>
                                        </CardContent>
                                    </Card>
                                </Link>
                            ))}
                        </Box>
                    </Grid>

                    {/* Management & Invites */}
                    <Grid item xs={12} sm={6}>
                         <Link href='/absensi' className='block no-underline h-full'>
                            <Card className='shadow-sm rounded-xl border-none bg-card h-full hover:shadow-md transition-all cursor-pointer'>
                                <CardContent className='flex items-center gap-4 p-4'>
                                    <Box className='bg-[#F5F3FF] border border-[#DDD6FE] p-3 rounded-xl text-[#7C3AED]'>
                                        <i className='ri-file-list-3-line text-xl' />
                                    </Box>
                                    <Box>
                                        <Typography variant='subtitle2' className='font-bold' color='text.primary'>Laporan Kehadiran</Typography>
                                        <Typography variant='caption' className='text-[10px] font-medium' color='text.secondary'>Ekspor Excel & Riwayat</Typography>
                                    </Box>
                                </CardContent>
                            </Card>
                         </Link>
                    </Grid>
                    <Grid item xs={12} sm={6}>
                         <Link href='/payroll' className='block no-underline h-full'>
                            <Card className='shadow-sm rounded-xl border-none bg-card h-full hover:shadow-md transition-all cursor-pointer'>
                                <CardContent className='flex items-center gap-4 p-4'>
                                    <Box className='bg-[#ECFDF5] border border-[#A7F3D0] p-3 rounded-xl text-[#059669]'>
                                        <i className='ri-money-dollar-box-line text-xl' />
                                    </Box>
                                    <Box>
                                        <Typography variant='subtitle2' className='font-bold' color='text.primary'>Manajemen Gaji</Typography>
                                        <Typography variant='caption' className='text-[10px] font-medium' color='text.secondary'>Proses & Potongan</Typography>
                                    </Box>
                                </CardContent>
                            </Card>
                         </Link>
                    </Grid>
                    <Grid item xs={12}>
                        <Card className='shadow-lg rounded-2xl border-none bg-slate-900 p-1'>
                            <CardContent className='flex flex-col sm:flex-row items-center justify-between gap-4 p-4'>
                                <Box className='flex items-center gap-4'>
                                    <Box className='bg-white/10 p-3 rounded-xl text-white'>
                                        <i className='ri-qr-code-line text-2xl' />
                                    </Box>
                                    <Box>
                                        <Typography className='font-bold text-white text-sm'>Undangan Rekrutmen</Typography>
                                        <Typography variant='caption' className='text-white/50 text-[10px]'>Barcode diperbarui berkala</Typography>
                                    </Box>
                                </Box>
                                <Button 
                                    variant='contained' 
                                    size='small'
                                    className='rounded-lg shadow-none bg-blue-600 hover:bg-blue-700 h-[40px] px-6 text-white text-xs'
                                    startIcon={<i className='ri-qr-scan-2-line' />}
                                    onClick={() => setQrModalOpen(true)}
                                >
                                    Lihat Barcode
                                </Button>
                            </CardContent>
                        </Card>
                    </Grid>
                </Grid>
            </Grid>

            {/* Sidebar Stats & Percentage */}
            <Grid item xs={12} lg={4}>
                <Card className='shadow-md rounded-2xl border-none h-full bg-primaryLight'>
                    <CardContent className='p-5'>
                        <Typography variant='subtitle2' className='font-bold mbe-4 flex items-center gap-2'>
                            <i className='ri-notification-badge-line text-primary' />
                            Statistik 7 Hari Terakhir
                        </Typography>
                        <Box className='grid grid-cols-2 gap-3'>
                            {( [
                                { 
                                    label: 'Hadir Tepat Waktu', 
                                    value: trend?.present.reduce((a, b) => a + b, 0) || 0, 
                                    color: 'text-green-600', 
                                    rgb: '76, 175, 80', 
                                    badge: 'Positif', 
                                    badgeColorHex: '#2e7d32' 
                                },
                                { 
                                    label: 'Terlambat', 
                                    value: trend?.late.reduce((a, b) => a + b, 0) || 0, 
                                    color: 'text-amber-600', 
                                    rgb: '255, 160, 0', 
                                    badge: 'Waspada', 
                                    badgeColorHex: '#f57c00' 
                                },
                                { 
                                    label: 'Alpha', 
                                    value: trend?.absent.reduce((a, b) => a + b, 0) || 0, 
                                    color: 'text-red-600', 
                                    rgb: '244, 67, 54', 
                                    badge: 'Kritis', 
                                    badgeColorHex: '#d32f2f' 
                                },
                                { 
                                    label: 'Izin/Sakit', 
                                    value: trend?.leave_sick.reduce((a, b) => a + b, 0) || 0, 
                                    color: 'text-blue-600', 
                                    rgb: '33, 150, 243', 
                                    badge: 'Info', 
                                    badgeColorHex: '#1976d2' 
                                },
                                { 
                                    label: 'Pulang di Jam Kerja', 
                                    value: trend?.early_leave.reduce((a, b) => a + b, 0) || 0, 
                                    color: 'text-orange-600', 
                                    rgb: '255, 152, 0', 
                                    badge: 'PJK', 
                                    badgeColorHex: '#e65100' 
                                },
                                { 
                                    label: 'Terlambat & Pulang di Jam Kerja', 
                                    value: trend?.late_early_leave.reduce((a, b) => a + b, 0) || 0, 
                                    color: 'text-purple-600', 
                                    rgb: '156, 39, 176', 
                                    badge: 'Perhatian', 
                                    badgeColorHex: '#7b1fa2' 
                                },
                            ] as { label: string; value: number; color: string; rgb: string; badge: string; badgeColorHex: string }[]).map((item, index) => {
                                const totalTrend = (trend?.present.reduce((a, b) => a + b, 0) || 0) +
                                                 (trend?.late.reduce((a, b) => a + b, 0) || 0) +
                                                 (trend?.absent.reduce((a, b) => a + b, 0) || 0) +
                                                 (trend?.leave_sick.reduce((a, b) => a + b, 0) || 0) +
                                                 (trend?.early_leave.reduce((a, b) => a + b, 0) || 0) +
                                                 (trend?.late_early_leave.reduce((a, b) => a + b, 0) || 0);
                                
                                const percentage = totalTrend > 0 ? ((item.value / totalTrend) * 100).toFixed(1) : '0.0';
                                
                                return (
                                    <Box key={index} className='p-3 bg-card border border-divider rounded-xl shadow-sm'>
                                        <Typography variant='caption' color='text.secondary' className='block truncate'>{item.label}</Typography>
                                        <Box className='flex items-center justify-between mbs-1'>
                                            <Typography className={`font-bold ${item.color}`}>
                                                {percentage}%
                                            </Typography>
                                            <Typography 
                                                variant='caption' 
                                                className='px-2 py-0.5 rounded uppercase font-bold text-[10px]'
                                                sx={{ 
                                                    backgroundColor: theme => theme.palette.mode === 'light' ? `rgba(${item.rgb}, 0.12)` : `rgba(${item.rgb}, 0.25)`,
                                                    color: item.badgeColorHex,
                                                    border: theme => theme.palette.mode === 'light' ? `1px solid rgba(${item.rgb}, 0.2)` : 'none'
                                                }}
                                            >
                                                {item.badge}
                                            </Typography>
                                        </Box>
                                    </Box>
                                );
                            })}
                        </Box>
                    </CardContent>
                </Card>
            </Grid>

            {/* Recent Attendance Table */}
            <Grid item xs={12}>
                <RecentAttendanceTable />
            </Grid>

            {/* QR Modal */}
            <InviteQRModal open={qrModalOpen} onClose={() => setQrModalOpen(false)} />
        </Grid>
    )
}

export default MainAdminDashboard
