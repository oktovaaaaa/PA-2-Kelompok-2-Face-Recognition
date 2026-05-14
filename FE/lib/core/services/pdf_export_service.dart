import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PdfExportService {
  static Future<String> exportAttendance(
    List<dynamic> records,
    String fileName, {
    required Map<String, int> stats,
    required String periodLabel,
  }) async {
    final pdf = pw.Document();
    
    // Load logo
    ByteData? logoData;
    try {
      logoData = await rootBundle.load('assets/images/videnti.png');
    } catch (_) {
      // Fallback
    }

    final primaryColor = PdfColor.fromHex('#2563EB');
    final secondaryColor = PdfColor.fromHex('#64748B');
    final successColor = PdfColor.fromHex('#22C55E');
    final warningColor = PdfColor.fromHex('#F59E0B');
    final errorColor = PdfColor.fromHex('#EF4444');
    final infoColor = PdfColor.fromHex('#3B82F6');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0), // Set to 0 to allow header to span full width
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return pw.SizedBox(height: 40); // Top margin for page 2+
          }
          return pw.SizedBox();
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // 1. Professional Header Background (Full Width)
            pw.Container(
              width: double.infinity,
              height: 120,
              decoration: pw.BoxDecoration(
                color: primaryColor,
              ),
              child: pw.Stack(
                children: [
                  // Title & Subtitle (Centered)
                  pw.Center(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'VIDENTI',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Laporan Kehadiran Karyawan & Detail Absensi',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Periode: $periodLabel',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Logo (Right Side)
                  if (logoData != null)
                    pw.Positioned(
                      top: 30,
                      right: 30,
                      child: pw.Container(
                        width: 60,
                        height: 60,
                        child: pw.Image(pw.MemoryImage(logoData.buffer.asUint8List())),
                      ),
                    ),
                  // Dicetak Pada (Right Bottom of Header)
                  pw.Positioned(
                    bottom: 15,
                    right: 30,
                    child: pw.Text(
                      'Dicetak pada: ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 2. Summary Stats Cards (With Margin)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(40, 25, 40, 0),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard('HADIR', stats['PRESENT'] ?? 0, successColor),
                  _buildStatCard('TERLAMBAT', stats['LATE'] ?? 0, warningColor),
                  _buildStatCard('ALPHA', stats['ABSENT'] ?? 0, errorColor),
                  _buildStatCard('IZIN/SAKIT', (stats['LEAVE'] ?? 0) + (stats['SICK'] ?? 0) + (stats['IZIN'] ?? 0) + (stats['SAKIT'] ?? 0), infoColor),
                ],
              ),
            ),
            
            pw.SizedBox(height: 35),
            
            // 3. Table (With Margin)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: primaryColor,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF333333)),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8FAFC),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40), // Increased to fit 3 digits
                  1: const pw.FlexColumnWidth(3),   // Karyawan
                  2: const pw.FlexColumnWidth(4),   // Tanggal
                  3: const pw.FlexColumnWidth(1.5), // Masuk
                  4: const pw.FlexColumnWidth(1.5), // Keluar
                  5: const pw.FlexColumnWidth(2),   // Status
                },
                headers: ['No', 'Karyawan', 'Tanggal', 'Masuk', 'Keluar', 'Status'],
                headerAlignment: pw.Alignment.center,
                cellAlignments: {
                  0: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                },
                data: List<List<dynamic>>.generate(
                  records.length,
                  (index) {
                    final r = records[index];
                    return [
                      index + 1,
                      r['user_name'] ?? '-',
                      _formatDate(r['date']),
                      _formatTime(r['check_in_time']),
                      _formatTime(r['check_out_time']),
                      _translateStatus(r['status'] ?? r['type']),
                    ];
                  },
                ),
              ),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$fileName.pdf");
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildStatCard(String label, int value, PdfColor color) {
    return pw.Container(
      width: 120,
      height: 60,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColor.fromInt(0xFFF1F5F9), width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '$value',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      // format 'EEEE, d MMMM yyyy' -> Kamis, 1 Juni 2026
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  static String _formatTime(dynamic time) {
    if (time == null) return '-';
    try {
      final dt = DateTime.parse(time.toString());
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '-';
    }
  }

  static String _translateStatus(dynamic status) {
    final s = status.toString().toUpperCase();
    switch (s) {
      case 'PRESENT': return 'Hadir';
      case 'LATE': return 'Terlambat';
      case 'ABSENT': return 'Alpha';
      case 'WORKING': return 'Sedang Bekerja';
      case 'NOT_YET': return 'Belum Hadir';
      case 'EARLY_LEAVE': return 'Pulang di jam kerja';
      case 'LATE_EARLY_LEAVE': return 'Terlambat & Pulang di jam kerja';
      case 'LEAVE': return 'Izin';
      case 'SICK': return 'Sakit';
      case 'IZIN': return 'Izin';
      case 'SAKIT': return 'Sakit';
      default: return s;
    }
  }
}


