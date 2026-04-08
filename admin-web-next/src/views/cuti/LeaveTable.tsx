// src/views/cuti/LeaveTable.tsx
'use client'

import React, { useState } from 'react'
import Card from '@mui/material/Card'
import Table from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableContainer from '@mui/material/TableContainer'
import TableHead from '@mui/material/TableHead'
import TableRow from '@mui/material/TableRow'
import Paper from '@mui/material/Paper'
import Chip from '@mui/material/Chip'
import Typography from '@mui/material/Typography'
import IconButton from '@mui/material/IconButton'
import Box from '@mui/material/Box'
import Avatar from '@mui/material/Avatar'
import TablePagination from '@mui/material/TablePagination'
import { LeaveRequest } from '@/libs/leaveService'
import { formatFullDate } from '@/utils/dateFormatter'

interface Props {
  leaves: LeaveRequest[]
  onView: (l: LeaveRequest) => void
  onDelete: (id: string) => void
}

const LeaveTable = ({ leaves, onView, onDelete }: Props) => {
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'APPROVED': return 'success'
      case 'REJECTED': return 'error'
      case 'PENDING': return 'warning'
      default: return 'default'
    }
  }

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'APPROVED': return 'Disetujui'
      case 'REJECTED': return 'Ditolak'
      case 'PENDING': return 'Menunggu'
      default: return status
    }
  }

  const paginatedLeaves = leaves.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)

  return (
    <Card sx={{ mt: 6 }}>
      <TableContainer component={Paper} elevation={0}>
        <Table sx={{ minWidth: 800 }}>
          <TableHead sx={{ bgcolor: 'action.hover' }}>
            <TableRow>
              <TableCell sx={{ fontWeight: '600' }}>Karyawan</TableCell>
              <TableCell sx={{ fontWeight: '600' }}>Tipe</TableCell>
              <TableCell sx={{ fontWeight: '600' }}>Judul / Alasan</TableCell>
              <TableCell sx={{ fontWeight: '600' }}>Tanggal</TableCell>
              <TableCell align="center" sx={{ fontWeight: '600' }}>Status</TableCell>
              <TableCell align="right" sx={{ fontWeight: '600' }}>Aksi</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {paginatedLeaves.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align='center' sx={{ py: 10 }}>
                  <Typography color='textSecondary'>Tidak ada data pengajuan izin.</Typography>
                </TableCell>
              </TableRow>
            ) : (
              paginatedLeaves.map((row) => (
                <TableRow key={row.id} hover onClick={() => onView(row)} sx={{ cursor: 'pointer' }}>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                      <Avatar 
                        src={row.user_photo ? `http://localhost:8080${row.user_photo}` : undefined}
                        sx={{ width: 34, height: 34 }}
                      >
                        {row.user_name?.charAt(0)}
                      </Avatar>
                      <Box>
                        <Typography variant='body2' fontWeight="600">{row.user_name}</Typography>
                        <Typography variant='caption' color='text.secondary'>{row.user_email}</Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Chip 
                      label={row.type} 
                      size='small' 
                      color={row.type === 'SAKIT' ? 'error' : 'info'} 
                      variant='tonal' 
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant='body2' noWrap sx={{ maxWidth: 200 }}>{row.title}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant='body2'>{formatFullDate(row.created_at)}</Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Chip 
                      label={getStatusLabel(row.status)} 
                      color={getStatusColor(row.status) as any} 
                      size='small' 
                      variant='outlined'
                    />
                  </TableCell>
                  <TableCell align="right">
                    <IconButton size='small' color='primary' onClick={(e) => { e.stopPropagation(); onView(row); }}>
                      <i className='ri-eye-line' />
                    </IconButton>
                    <IconButton size='small' color='error' onClick={(e) => { e.stopPropagation(); onDelete(row.id); }}>
                      <i className='ri-delete-bin-line' />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
      <TablePagination
        rowsPerPageOptions={[5, 10, 25]}
        component='div'
        count={leaves.length}
        rowsPerPage={rowsPerPage}
        page={page}
        onPageChange={handleChangePage}
        onRowsPerPageChange={handleChangeRowsPerPage}
        labelRowsPerPage="Baris per halaman:"
      />
    </Card>
  )
}

export default LeaveTable
