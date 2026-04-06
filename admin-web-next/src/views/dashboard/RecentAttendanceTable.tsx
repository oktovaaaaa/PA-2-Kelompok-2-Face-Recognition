// src/views/dashboard/RecentAttendanceTable.tsx
'use client'

import { useState, useEffect } from 'react'
import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import Table from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableContainer from '@mui/material/TableContainer'
import TableHead from '@mui/material/TableHead'
import TableRow from '@mui/material/TableRow'
import TablePagination from '@mui/material/TablePagination'
import Typography from '@mui/material/Typography'
import Avatar from '@mui/material/Avatar'
import Chip from '@mui/material/Chip'
import Box from '@mui/material/Box'
import IconButton from '@mui/material/IconButton'
import { dashboardService, AttendanceLog } from '@/libs/dashboardService'
import { formatImageUrl } from '@/libs/settingService'

const RecentAttendanceTable = () => {
    const [logs, setLogs] = useState<AttendanceLog[]>([])
    const [loading, setLoading] = useState(true)
    const [page, setPage] = useState(0)
    const [rowsPerPage, setRowsPerPage] = useState(10)

    const fetchLogs = async () => {
        try {
            const today = new Date().toLocaleDateString('en-CA')
            const data = await dashboardService.getAttendanceLogs(today)
            
            // Filter hanya yang sudah absen dan urutkan Ascending (Paling awal di atas)
            const filteredAndSorted = data
                .filter(log => log.check_in_time !== null)
                .sort((a, b) => {
                    if (a.check_in_time! < b.check_in_time!) return -1
                    if (a.check_in_time! > b.check_in_time!) return 1
                    return 0
                })

            setLogs(filteredAndSorted)
        } catch (error) {
            console.error('Error fetching attendance logs:', error)
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => {
        fetchLogs()
        // Auto refresh setiap 1 menit (sesuai permintaan user)
        const interval = setInterval(fetchLogs, 60000)
        return () => clearInterval(interval)
    }, [])

    const handleChangePage = (event: unknown, newPage: number) => {
        setPage(newPage)
    }

    const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
        setRowsPerPage(parseInt(event.target.value, 10))
        setPage(0)
    }

    const formatTime = (timeStr: string | null) => {
        if (!timeStr) return '--:--'
        try {
            const date = new Date(timeStr)
            return date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
        } catch (e) {
            // Fallback for simple HH:mm strings
            return timeStr.substring(0, 5)
        }
    }

    const getStatusChip = (status: string) => {
        switch (status) {
            case 'PRESENT':
                return <Chip label='Datang Tepat Waktu' size='small' color='success' variant='tonal' className='font-bold uppercase text-[10px]' />
            case 'LATE':
                return <Chip label='Terlambat' size='small' color='warning' variant='tonal' className='font-bold uppercase text-[10px]' />
            case 'WORKING':
                return <Chip label='Sedang Bekerja' size='small' color='info' variant='tonal' className='font-bold uppercase text-[10px]' />
            case 'ABSENT':
                return <Chip label='Alpa' size='small' color='error' variant='tonal' className='font-bold uppercase text-[10px]' />
            case 'LEAVE':
            case 'SICK':
            case 'LEAVE_SICK':
                return <Chip label='Izin/Sakit' size='small' color='primary' variant='tonal' className='font-bold uppercase text-[10px]' />
            case 'EARLY_LEAVE':
                return <Chip label='Pulang di jam kerja' size='small' color='warning' variant='tonal' className='font-bold uppercase text-[10px]' />
            case 'LATE_EARLY_LEAVE':
                return <Chip 
                    label='Terlambat & Pulang di jam kerja' 
                    size='small' 
                    variant='tonal' 
                    className='font-bold uppercase text-[10px]' 
                    sx={{
                        backgroundColor: 'rgba(217, 70, 239, 0.16) !important', 
                        color: '#D946EF !important',
                        border: '1px solid rgba(217, 70, 239, 0.5)'
                    }}
                />
            case 'NOT_YET':
                return <Chip label='Belum Hadir' size='small' variant='tonal' className='font-bold uppercase text-[10px] bg-slate-100 text-slate-500' />
            default:
                return <Chip label={status} size='small' variant='tonal' className='font-bold uppercase text-[10px]' />
        }
    }

    return (
        <Card className='shadow-lg rounded-3xl border-none overflow-hidden'>
            <CardHeader
                title={<Typography variant='subtitle2' className='font-bold uppercase tracking-widest'>Log Absensi Hari Ini</Typography>}
                subheader={<Typography variant='caption' color='text.secondary'>Urutan kedatangan karyawan hari ini (Paling awal teratas)</Typography>}
                action={
                    <IconButton size='small' onClick={fetchLogs}>
                        <i className='ri-refresh-line text-slate-400' />
                    </IconButton>
                }
                className='p-6'
            />
            <TableContainer>
                <Table sx={{ minWidth: 600 }}>
                    <TableHead className='bg-actionHover transition-colors'>
                        <TableRow>
                            <TableCell className='font-bold uppercase text-[11px] py-4' color='text.secondary'>Karyawan</TableCell>
                            <TableCell className='font-bold uppercase text-[11px] py-4' color='text.secondary'>Email</TableCell>
                            <TableCell className='font-bold uppercase text-[11px] py-4' color='text.secondary'>Waktu Check-In</TableCell>
                            <TableCell className='font-bold uppercase text-[11px] py-4' color='text.secondary'>Waktu Check-Out</TableCell>
                            <TableCell className='font-bold uppercase text-[11px] py-4' align='center' color='text.secondary'>Status</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {logs.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage).map((log) => (
                            <TableRow key={log.id} hover className='transition-all cursor-default'>
                                <TableCell className='py-4'>
                                    <Box className='flex items-center gap-3'>
                                        <Avatar 
                                            src={formatImageUrl(log.photo_url)} 
                                            alt={log.user_name}
                                            className='shadow-sm border border-divider'
                                        />
                                        <Typography variant='subtitle2' className='font-bold'>{log.user_name}</Typography>
                                    </Box>
                                </TableCell>
                                <TableCell>
                                    <Typography variant='caption' color='text.secondary'>{log.user_email}</Typography>
                                </TableCell>
                                <TableCell>
                                    <Box className='flex items-center gap-2'>
                                        <i className='ri-time-line text-blue-500 text-lg' />
                                        <Typography className='font-bold' color='text.primary'>{formatTime(log.check_in_time)}</Typography>
                                    </Box>
                                </TableCell>
                                <TableCell>
                                    <Box className='flex items-center gap-2'>
                                        <i className='ri-time-line text-orange-500 text-lg' />
                                        <Typography className='font-bold' color='text.primary'>{formatTime(log.check_out_time)}</Typography>
                                    </Box>
                                </TableCell>
                                <TableCell align='center'>
                                    {getStatusChip(log.status)}
                                </TableCell>
                            </TableRow>
                        ))}
                        {logs.length === 0 && !loading && (
                            <TableRow>
                                <TableCell colSpan={5} align='center' className='py-12'>
                                    <Box className='flex flex-col items-center gap-2 opacity-30'>
                                        <i className='ri-inbox-line text-5xl' />
                                        <Typography>Belum ada data absen hari ini</Typography>
                                    </Box>
                                </TableCell>
                            </TableRow>
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
            <TablePagination
                rowsPerPageOptions={[10, 25, 50]}
                component='div'
                count={logs.length}
                rowsPerPage={rowsPerPage}
                page={page}
                onPageChange={handleChangePage}
                onRowsPerPageChange={handleChangeRowsPerPage}
                labelRowsPerPage='Tampilkan:'
                labelDisplayedRows={({ from, to, count }) => `${from}-${to} dari ${count}`}
            />
        </Card>
    )
}

export default RecentAttendanceTable
