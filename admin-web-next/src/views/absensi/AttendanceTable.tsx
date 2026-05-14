'use client'

import React, { useState, useEffect } from 'react'

import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Table from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableContainer from '@mui/material/TableContainer'
import TableHead from '@mui/material/TableHead'
import TableRow from '@mui/material/TableRow'
import Paper from '@mui/material/Paper'
import TextField from '@mui/material/TextField'
import Button from '@mui/material/Button'
import Chip from '@mui/material/Chip'
import Avatar from '@mui/material/Avatar'
import Typography from '@mui/material/Typography'
import InputAdornment from '@mui/material/InputAdornment'
import MenuItem from '@mui/material/MenuItem'
import Select from '@mui/material/Select'
import FormControl from '@mui/material/FormControl'
import InputLabel from '@mui/material/InputLabel'
import Stack from '@mui/material/Stack'
import Box from '@mui/material/Box'
import Grid from '@mui/material/Grid'
import * as XLSX from 'xlsx'

import { attendanceService } from '@/libs/attendanceService'
import { formatFullDate } from '@/utils/dateFormatter'
import { useNotification } from '@/contexts/NotificationContext'

interface AttendanceTableProps {
  parentPeriod: string
  parentMonth: number
  parentYear: number
}

const AttendanceTable = ({ parentPeriod, parentMonth, parentYear }: AttendanceTableProps) => {
  const { showNotification } = useNotification()
  const [loading, setLoading] = useState(true)
  const [data, setData] = useState<any[]>([])
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('ALL')

  const months = [
    { value: 1, label: 'Januari' }, { value: 2, label: 'Februari' }, { value: 3, label: 'Maret' },
    { value: 4, label: 'April' }, { value: 5, label: 'Mei' }, { value: 6, label: 'Juni' },
    { value: 7, label: 'Juli' }, { value: 8, label: 'Agustus' }, { value: 9, label: 'September' },
    { value: 10, label: 'Oktober' }, { value: 11, label: 'November' }, { value: 12, label: 'Desember' }
  ]

  const fetchData = async () => {
    setLoading(true)

    try {
      const params: any = { filter: parentPeriod, status: statusFilter !== 'ALL' ? statusFilter : undefined }
      
      if (parentPeriod === 'month') {
        params.month = parentMonth
        params.year = parentYear
      } else if (parentPeriod === 'year') {
        params.year = parentYear
      }
      
      const history = await attendanceService.getAttendanceHistory(params)

      setData(history || [])
    } catch (error) {
      console.error('Error fetching attendance history:', error)
    } finally {
      setLoading(false)
    }
  }

  // Remove internal fetchYears since it's now handled by the global AttendanceFilter
  useEffect(() => {
    fetchData()
  }, [parentPeriod, parentMonth, parentYear, statusFilter])

  const filteredData = data.filter(row => 
    (row.user_name || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
    (row.user_email || '').toLowerCase().includes(searchTerm.toLowerCase())
  )

  const _translateStatus = (status: string) => {
    switch (status) {
      case 'PRESENT': return 'Hadir'
      case 'LATE': return 'Terlambat'
      case 'ABSENT': return 'Alpha'
      case 'WORKING': return 'Sedang Bekerja'
      case 'NOT_YET': return 'Belum Hadir'
      case 'EARLY_LEAVE': return 'Pulang di jam kerja'
      case 'LATE_EARLY_LEAVE': return 'Terlambat & Pulang di jam kerja'
      case 'LEAVE': return 'Izin'
      case 'SICK': return 'Sakit'
      default: return status
    }
  }

  const _getStatusColor = (status: string) => {
    switch (status) {
      case 'PRESENT': return '22C55E'
      case 'LATE': return 'F59E0B'
      case 'ABSENT': return 'EF4444'
      case 'WORKING': return '818CF8'
      case 'NOT_YET': return '94A3B8'
      case 'EARLY_LEAVE': return 'F97316'
      case 'LATE_EARLY_LEAVE': return 'D946EF'
      default: return '64748B'
    }
  }


  const handleExport = async () => {
    const ExcelJS = (await import('exceljs')).default
    const FileSaver = await import('file-saver')
    const saveAs = FileSaver.saveAs || (FileSaver as any).default?.saveAs || (FileSaver as any).default
    
    const workbook = new ExcelJS.Workbook()
    const worksheet = workbook.addWorksheet('Laporan Kehadiran')

    // Set Column Widths
    worksheet.columns = [
        { header: 'No', key: 'no', width: 35 }, // Wide enough for Dashboard Status Labels
        { header: 'Nama Karyawan', key: 'name', width: 30 },
        { header: 'Tanggal', key: 'date', width: 30 },
        { header: 'Masuk', key: 'in', width: 12 },
        { header: 'Keluar', key: 'out', width: 12 },
        { header: 'Status', key: 'status', width: 25 },

        // Extra columns for bar chart (20 columns)
        ...Array(20).fill(0).map((_, i) => ({ header: '', key: `bar_${i}`, width: 3 }))
    ]

    let currentRow = 1

    // 1. Title
    const titleRow = worksheet.getRow(currentRow)

    titleRow.getCell(1).value = 'LAPORAN KEHADIRAN KARYAWAN'
    titleRow.getCell(1).font = { name: 'Arial', size: 16, bold: true, color: { argb: 'FF1E3A8A' } }
    worksheet.mergeCells(`A${currentRow}:F${currentRow}`)
    currentRow++

    // 2. Subtitle (Period)
    const periodLabel = parentPeriod === 'today' ? 'Hari Ini' : parentPeriod === 'week' ? 'Minggu Ini' : parentPeriod === 'month' ? `${months.find(m => m.value === parentMonth)?.label} ${parentYear}` : `Tahun ${parentYear}`
    const subtitleRow = worksheet.getRow(currentRow)

    subtitleRow.getCell(1).value = `Periode: ${periodLabel}`
    subtitleRow.getCell(1).font = { name: 'Arial', size: 11, italic: true, color: { argb: 'FF64748B' } }
    worksheet.mergeCells(`A${currentRow}:F${currentRow}`)
    currentRow += 2

    // 3. Visualization Dashboard
    const dashHeader = worksheet.getRow(currentRow)

    dashHeader.getCell(1).value = 'DASHBOARD VISUALISASI KEHADIRAN (GRAFIK)'
    dashHeader.getCell(1).font = { bold: true, size: 14 }
    dashHeader.getCell(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF1F5F9' } }
    worksheet.mergeCells(`A${currentRow}:Z${currentRow}`)
    currentRow += 2

    const totalForChart = filteredData.length || 1

    const summaryKeys = [
        { key: 'PRESENT', label: 'Hadir' },
        { key: 'LATE', label: 'Terlambat' },
        { key: 'ABSENT', label: 'Alpha' },
        { key: 'WORKING', label: 'Sedang Bekerja' },
        { key: 'NOT_YET', label: 'Belum Hadir' },
        { key: 'EARLY_LEAVE', label: 'Pulang di jam kerja' },
        { key: 'LATE_EARLY_LEAVE', label: 'Terlambat & Pulang di jam kerja' },
    ]

    summaryKeys.forEach(s => {
        const count = filteredData.filter(r => r.status === s.key).length
        const percent = Math.round((count / totalForChart) * 100)
        const row = worksheet.getRow(currentRow)
        
        // Label & Percentage
        row.getCell(1).value = `${s.label} (${count})`
        row.getCell(1).font = { bold: true, color: { argb: `FF${_getStatusColor(s.key)}` } }
        row.getCell(2).value = `${percent}%`
        row.getCell(2).alignment = { horizontal: 'right' }

        // Bar Chart (20 cols)
        const barCols = Math.round((count / totalForChart) * 20)

        for (let b = 0; b < 20; b++) {
            const cell = row.getCell(3 + b)

            if (b < barCols) {
                cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: `FF${_getStatusColor(s.key)}` } }
            } else {
                cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8FAFC' } }
            }
        }

        currentRow++
    })
    currentRow += 3

    // 4. Detail Table
    const headerRow = worksheet.getRow(currentRow)
    const headers = ['No', 'Nama Karyawan', 'Tanggal', 'Masuk', 'Keluar', 'Status']

    headers.forEach((h, i) => {
        const cell = headerRow.getCell(i + 1)

        cell.value = h
        cell.font = { bold: true, color: { argb: 'FFFFFFFF' } }
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF2563EB' } }
        cell.alignment = { horizontal: 'center', vertical: 'middle' }
        cell.border = {
            top: { style: 'thin' },
            left: { style: 'thin' },
            bottom: { style: 'medium' },
            right: { style: 'thin' }
        }
    })
    currentRow++

    // Data Rows
    filteredData.forEach((r, index) => {
        const row = worksheet.getRow(currentRow)
        const checkIn = r.check_in_time ? new Date(r.check_in_time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-'
        const checkOut = r.check_out_time ? new Date(r.check_out_time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-'
        
        const values = [
            index + 1,
            r.user_name,
            formatFullDate(r.date),
            checkIn,
            checkOut,
            _translateStatus(r.status)
        ]

        values.forEach((v, i) => {
            const cell = row.getCell(i + 1)

            cell.value = v
            cell.border = {
                top: { style: 'thin' },
                left: { style: 'thin' },
                bottom: { style: 'thin' },
                right: { style: 'thin' }
            }
        })
        currentRow++
    })

    // Generate Dynamic Filename
    let fileName = 'Laporan_Absensi'

    if (parentPeriod === 'today') fileName += '_Hari_Ini'
    else if (parentPeriod === 'week') fileName += '_Minggu_Ini'
    else if (parentPeriod === 'month') fileName += `_${months.find(m => m.value === parentMonth)?.label}_${parentYear}`
    else if (parentPeriod === 'year') fileName += `_Tahun_${parentYear}`

    // Generate & Save
    try {
        showNotification('Sedang menyiapkan file Excel...', 'info')
        const buffer = await workbook.xlsx.writeBuffer()
        const data = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })

        saveAs(data, `${fileName}.xlsx`)
        showNotification('Laporan berhasil diunduh!', 'success')
    } catch (error) {
        showNotification('Gagal mengunduh laporan.', 'error')
    }
  }

  const handleExportPDF = async () => {
    const { default: jsPDF } = await import('jspdf')
    const { default: autoTable } = await import('jspdf-autotable')
    
    const doc = new jsPDF()
    const primaryColor = [37, 99, 235] // #2563EB
    const periodLabel = parentPeriod === 'today' ? 'Hari Ini' : parentPeriod === 'week' ? 'Minggu Ini' : parentPeriod === 'month' ? `${months.find(m => m.value === parentMonth)?.label} ${parentYear}` : `Tahun ${parentYear}`
    
    // 1. Professional Header Background
    doc.setFillColor(primaryColor[0], primaryColor[1], primaryColor[2])
    doc.rect(0, 0, 210, 45, 'F')
    
    // 2. Title & Subtitle (Centered)
    doc.setFont('helvetica', 'bold')
    doc.setFontSize(24)
    doc.setTextColor(255, 255, 255)
    doc.text('VIDENTI', 105, 18, { align: 'center' })
    
    doc.setFont('helvetica', 'normal')
    doc.setFontSize(12)
    doc.text('Laporan Kehadiran Karyawan & Detail Absensi', 105, 26, { align: 'center' })
    
    doc.setFontSize(10)
    doc.text(`Periode: ${periodLabel}`, 105, 33, { align: 'center' })
    
    // 3. Dicetak Pada (Right Bottom of Header)
    doc.setFontSize(8)
    const printDate = `Dicetak pada: ${new Date().toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}`
    doc.text(printDate, 196, 40, { align: 'right' })
    
    // 4. Logo (Right Side)
    try {
      doc.addImage('/images/videnti.png', 'PNG', 172, 10, 22, 22)
    } catch (e) {
      console.error('Failed to add logo:', e)
    }
    
    // 5. Summary Section (Below Header)
    const summaryData = [
      { label: 'Hadir', count: filteredData.filter(r => r.status === 'PRESENT').length, color: [34, 197, 94] },
      { label: 'Terlambat', count: filteredData.filter(r => r.status === 'LATE').length, color: [245, 158, 11] },
      { label: 'Alpha', count: filteredData.filter(r => r.status === 'ABSENT').length, color: [239, 68, 68] },
      { label: 'Izin/Sakit', count: filteredData.filter(r => ['LEAVE', 'SICK'].includes(r.status)).length, color: [59, 130, 246] }
    ]
    
    let startX = 14
    summaryData.forEach(item => {
      doc.setDrawColor(241, 245, 249)
      doc.setFillColor(255, 255, 255)
      doc.roundedRect(startX, 52, 43, 20, 3, 3, 'FD')
      
      doc.setFontSize(8)
      doc.setTextColor(100, 116, 139)
      doc.text(item.label.toUpperCase(), startX + 5, 58)
      
      doc.setFontSize(12)
      doc.setTextColor(item.color[0], item.color[1], item.color[2])
      doc.setFont('helvetica', 'bold')
      doc.text(item.count.toString(), startX + 5, 66)
      doc.setFont('helvetica', 'normal')
      
      startX += 47
    })
    
    // 6. Detailed Table
    const tableHeaders = [['No', 'Karyawan', 'Tanggal', 'Masuk', 'Keluar', 'Status']]
    const tableBody = filteredData.map((r, i) => [
      i + 1,
      r.user_name,
      formatFullDate(r.date),
      r.check_in_time ? new Date(r.check_in_time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-',
      r.check_out_time ? new Date(r.check_out_time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-',
      _translateStatus(r.status)
    ])
    
    autoTable(doc, {
      startY: 85,
      head: tableHeaders,
      body: tableBody,
      theme: 'striped',
      headStyles: {
        fillColor: primaryColor,
        textColor: 255,
        fontSize: 10,
        fontStyle: 'bold',
        halign: 'center'
      },
      bodyStyles: {
        fontSize: 9,
        textColor: 51,
        cellPadding: 4
      },
      alternateRowStyles: {
        fillColor: [248, 250, 252]
      },
      columnStyles: {
        0: { halign: 'center', cellWidth: 15 },
        3: { halign: 'center' },
        4: { halign: 'center' },
        5: { halign: 'center' }
      },
      margin: { top: 25 }, // Normal margin for pages after page 1
      didDrawPage: (data) => {
        // Footer
        doc.setFontSize(8)
        doc.setTextColor(150)
        doc.text(
          `Halaman ${data.pageNumber} dari ${doc.getNumberOfPages()}`,
          doc.internal.pageSize.width / 2,
          doc.internal.pageSize.height - 10,
          { align: 'center' }
        )
      }
    })
    
    let fileName = 'Laporan_Absensi'
    if (parentPeriod === 'today') fileName += '_Hari_Ini'
    else if (parentPeriod === 'month') fileName += `_${months.find(m => m.value === parentMonth)?.label}_${parentYear}`
    else if (parentPeriod === 'year') fileName += `_Tahun_${parentYear}`
    
    showNotification('Sedang menyiapkan file PDF...', 'info')
    doc.save(`${fileName}.pdf`)
    showNotification('Laporan PDF berhasil diunduh!', 'success')
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'PRESENT': return 'success'
      case 'LATE': return 'warning'
      case 'LEAVE': return 'info'
      case 'SICK': return 'info'
      case 'ABSENT': return 'error'
      case 'WORKING': return 'primary'
      case 'LATE_EARLY_LEAVE': return 'secondary'
      case 'EARLY_LEAVE': return 'warning'
      default: return 'secondary'
    }
  }

  const formatTime = (timeStr: string | null) => {
    if (!timeStr) return '-'
    const date = new Date(timeStr)

    
return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }

  return (
    <Card>
      <CardHeader 
        title='Laporan Kehadiran Terperinci' 
        subheader='Filter berdasarkan periode, status, dan cari karyawan'
        action={
          <Stack direction='row' spacing={2}>
            <Button 
              variant='outlined' 
              color='primary'
              onClick={handleExportPDF} 
              startIcon={<i className='ri-file-pdf-line' />}
            >
              Export PDF
            </Button>
            <Button 
              variant='contained' 
              onClick={handleExport} 
              startIcon={<i className='ri-file-excel-line' />}
            >
              Export Excel
            </Button>
          </Stack>
        }
      />
      <CardContent>
        {/* Advanced Filter UI */}
        <Box sx={{ mb: 6, p: 4, bgcolor: 'action.hover', borderRadius: 1 }}>
            <Grid container spacing={4} alignItems="center">
                <Grid item xs={12} lg={8}>
                    {/* Removed Period Toggles from here as they are now global */}
                    <Typography variant="body2" color="text.secondary">
                        Laporan untuk periode: <strong>{
                            parentPeriod === 'today' ? 'Hari Ini' : 
                            parentPeriod === 'week' ? 'Minggu Ini' : 
                            parentPeriod === 'month' ? `${months.find(m => m.value === parentMonth)?.label} ${parentYear}` : 
                            `Tahun ${parentYear}`
                        }</strong>
                    </Typography>
                </Grid>

                {/* Removed Selects from here as they are now global */}

                <Grid item xs={12} sm={6} lg={parentPeriod === 'week' ? 4 : 4}>
                    <TextField
                        fullWidth
                        size='small'
                        placeholder='Cari Nama...'
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        InputProps={{
                            startAdornment: <InputAdornment position='start'><i className='ri-search-line' /></InputAdornment>
                        }}
                    />
                </Grid>
            </Grid>

            {/* Status Filter Row */}
            <Box sx={{ mt: 4 }}>
                <Stack direction="row" spacing={2} sx={{ overflowX: 'auto', pb: 2 }}>
                    {[
                        { val: 'ALL', label: 'Semua Status' },
                        { val: 'PRESENT', label: 'Hadir' },
                        { val: 'LATE', label: 'Terlambat' },
                        { val: 'ABSENT', label: 'Alpha' },
                        { val: 'LEAVE', label: 'Izin' },
                        { val: 'SICK', label: 'Sakit' },
                        { val: 'WORKING', label: 'Sedang Bekerja' },
                        { val: 'EARLY_LEAVE', label: 'Pulang di jam kerja' },
                        { val: 'LATE_EARLY_LEAVE', label: 'Terlambat & Pulang di jam kerja' }
                    ].map((s) => (
                        <Chip 
                            key={s.val}
                            label={s.label}
                            size="small"
                            variant="tonal"
                            color={statusFilter === s.val ? 'primary' : 'default'}
                            onClick={() => setStatusFilter(s.val)}
                            sx={{ cursor: 'pointer' }}
                        />
                    ))}
                </Stack>
            </Box>
        </Box>

        {loading ? (
            <Box sx={{ p: 10, textAlign: 'center' }}>
                <Typography variant="body2" color="text.secondary">Sedang memproses data laporan...</Typography>
            </Box>
        ) : (
          <TableContainer component={Paper} elevation={0}>
            <Table sx={{ minWidth: 900 }}>
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell>Karyawan</TableCell>
                  <TableCell>Tanggal</TableCell>
                  <TableCell>Check-In</TableCell>
                  <TableCell>Check-Out</TableCell>
                  <TableCell>Jarak (Audit)</TableCell>
                  <TableCell>Status</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredData.map((row) => (
                  <TableRow key={row.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                        <Avatar 
                          src={row.user_image ? `http://localhost:8080/uploads/${row.user_image}` : undefined} 
                          sx={{ width: 40, height: 40 }}
                        >
                          {row.user_name?.charAt(0)}
                        </Avatar>
                        <Box>
                          <Typography variant='body2' fontWeight='600'>{row.user_name}</Typography>
                          <Typography variant='caption' color='text.secondary'>{row.user_email}</Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>{formatFullDate(row.date)}</TableCell>
                    <TableCell>{formatTime(row.check_in_time)}</TableCell>
                    <TableCell>{formatTime(row.check_out_time)}</TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                        {row.check_in_time && (
                          <Chip 
                            label={`${row.check_in_distance ? Math.round(row.check_in_distance) : 0}m`} 
                            size="small" variant="outlined" color="primary" sx={{ fontSize: '10px', height: 20 }}
                          />
                        )}
                        {row.check_out_time && (
                          <Chip 
                            label={`${row.check_out_distance ? Math.round(row.check_out_distance) : 0}m`} 
                            size="small" variant="outlined" color="secondary" sx={{ fontSize: '10px', height: 20 }}
                          />
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip 
                        label={
                            row.status === 'PRESENT' ? 'Hadir' : 
                            row.status === 'LATE' ? 'Terlambat' : 
                            row.status === 'ABSENT' ? 'Alpha' : 
                            row.status === 'LEAVE' ? 'Izin' : 
                            row.status === 'SICK' ? 'Sakit' : 
                            row.status === 'WORKING' ? 'Sedang Bekerja' : 
                            row.status === 'EARLY_LEAVE' ? 'Pulang di jam kerja' : 
                            row.status === 'LATE_EARLY_LEAVE' ? 'Terlambat & Pulang di jam kerja' : 
                            row.status === 'NOT_YET' ? 'Belum Hadir' : row.status
                        } 
                        size='small' 
                        color={getStatusColor(row.status) as any} 
                        variant='tonal'
                        sx={{ 
                            minWidth: 90,
                            ...(row.status === 'LATE_EARLY_LEAVE' && { 
                                backgroundColor: 'rgba(217, 70, 239, 0.16) !important', 
                                color: '#D946EF !important',
                                border: '1px solid rgba(217, 70, 239, 0.5)'
                            }) 
                        }} 
                      />
                    </TableCell>
                  </TableRow>
                ))}
                {filteredData.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} align="center" sx={{ py: 10 }}>
                        Tidak ada data ditemukan untuk kriteria ini.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </CardContent>
    </Card>
  )
}

export default AttendanceTable
