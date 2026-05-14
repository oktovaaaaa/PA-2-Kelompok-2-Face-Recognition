// lib/features/employee/presentation/screens/tabs/employee_history_tab.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/services/pdf_export_service.dart';
import '../../../../common/widgets/app_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';
import '../../../../../core/utils/date_formatter.dart';
import 'package:intl/intl.dart';

class EmployeeHistoryTab extends StatefulWidget {
  const EmployeeHistoryTab({super.key});

  @override
  State<EmployeeHistoryTab> createState() => _EmployeeHistoryTabState();
}

class _EmployeeHistoryTabState extends State<EmployeeHistoryTab> {
  String _filter = ''; // Prioritaskan selectedMonth/Year
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [DateTime.now().year];
  List<dynamic> _records = [];
  Map<String, dynamic>? _stats;
  bool _loading = false;

  final List<String> _months = [
    'Semua Bulan', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _loading = true);
    try {
      // Ambil data profil untuk tahu tahun pendaftaran (Created At)
      final res = await ApiClient.get('/api/auth/me');
      if (res.success && res.data != null) {
        final userData = res.data!;
        if (userData['created_at'] != null) {
          final createdAt = DateTime.parse(userData['created_at']);
          final startYear = createdAt.year;
          final currentYear = DateTime.now().year;
          
          setState(() {
            _availableYears = [];
            for (int y = currentYear; y >= startYear; y--) {
              _availableYears.add(y);
            }
            // Jika tahun saat ini tidak ada di daftar (mungkin jam lokal salah), paksa ada
            if (!_availableYears.contains(currentYear)) _availableYears.insert(0, currentYear);
          });
        }
      }
    } catch (_) {
      // Fallback jika gagal
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      String url = '/api/employee/attendance/history?';
      if (_filter != '') {
        url += 'filter=$_filter';
      } else {
        url += 'year=$_selectedYear';
        if (_selectedMonth != 0) {
          url += '&month=$_selectedMonth';
        }
      }

      final res = await ApiClient.get(url);
      if (res.success && mounted) {
        setState(() {
          _records = res.data?['records'] ?? [];
          _stats = res.data?['stats'] as Map<String, dynamic>?;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PRESENT': return const Color(0xFF22C55E); // Green
      case 'LATE': return const Color(0xFFFBBF24); // Yellow
      case 'ABSENT': return const Color(0xFFEF4444); // Red
      case 'LEAVE': return const Color(0xFF3B82F6); // Blue
      case 'SICK': return const Color(0xFF3B82F6); // Blue
      case 'EARLY_LEAVE': return const Color(0xFFF97316); // Orange
      case 'LATE_EARLY_LEAVE': return const Color(0xFFD946EF); // Magenta
      case 'WORKING': return const Color(0xFF818CF8); // Indigo
      case 'NOT_YET': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PRESENT': return 'Hadir';
      case 'LATE': return 'Terlambat';
      case 'ABSENT': return 'Alpha';
      case 'LEAVE': return 'Izin';
      case 'SICK': return 'Sakit';
      case 'EARLY_LEAVE': return 'Pulang di jam kerja';
      case 'LATE_EARLY_LEAVE': return 'Terlambat & Pulang di jam kerja';
      case 'WORKING': return 'Sedang Bekerja';
      case 'NOT_YET': return 'Belum Hadir';
      default: return status;
    }
  }

  void _showFilterPicker() async {
    int? tempMonth = _selectedMonth ?? DateTime.now().month;
    int? tempYear = _selectedYear ?? DateTime.now().year;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pilih Periode', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: tempMonth,
                decoration: const InputDecoration(labelText: 'Bulan'),
                items: List.generate(12, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text([
                    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
                  ][i]),
                )),
                onChanged: (v) => setDialogState(() => tempMonth = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: tempYear,
                decoration: const InputDecoration(labelText: 'Tahun'),
                items: List.generate(5, (i) => DropdownMenuItem(
                  value: DateTime.now().year - i,
                  child: Text('${DateTime.now().year - i}'),
                )),
                onChanged: (v) => setDialogState(() => tempYear = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = tempMonth ?? DateTime.now().month;
                  _selectedYear = tempYear ?? DateTime.now().year;
                  _filter = '';
                });
                Navigator.pop(context);
                _load();
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_records.isEmpty) {
      AppDialog.showInfo(context, 'Tidak ada data untuk diekspor');
      return;
    }

    AppDialog.showLoading(context, message: 'Menyiapkan PDF...');
    
    try {
      String periodLabel = '';
      if (_filter == 'week') {
        periodLabel = 'Minggu Ini';
      } else if (_filter == 'month') {
        periodLabel = 'Bulan Ini';
      } else if (_filter == 'year') {
        periodLabel = 'Tahun Ini';
      } else {
        periodLabel = '${_months[_selectedMonth]} $_selectedYear';
      }

      final fileName = 'Riwayat_Presensi_${periodLabel.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Prepare stats for PDF
      Map<String, int> pdfStats = {
        'PRESENT': _stats?['present'] ?? 0,
        'LATE': _stats?['late'] ?? 0,
        'ABSENT': _stats?['absent'] ?? 0,
        'LEAVE': _stats?['leave'] ?? 0,
        'SICK': _stats?['sick'] ?? 0,
        'IZIN': _stats?['leave'] ?? 0,
        'SAKIT': _stats?['sick'] ?? 0,
      };

      final path = await PdfExportService.exportAttendance(
        _records, 
        fileName, 
        stats: pdfStats, 
        periodLabel: periodLabel
      );

      if (mounted) Navigator.pop(context); // Hide loading

      if (mounted) {
        AppDialog.showSuccess(
          context, 
          'PDF berhasil dibuat',
          confirmText: 'Buka File',
        ).then((confirmed) {
          if (confirmed == true) OpenFilex.open(path);
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Hide loading
      if (mounted) AppDialog.showError(context, 'Gagal membuat PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = _stats?['present'] ?? 0;
    final lateCount = _stats?['late'] ?? 0;
    final absent = _stats?['absent'] ?? 0;
    final leave = _stats?['leave'] ?? 0;
    final sick = _stats?['sick'] ?? 0;
    final earlyLeave = _stats?['early_leave'] ?? 0;
    final working = _stats?['working'] ?? 0;
    final notYet = _stats?['not_yet'] ?? 0;
    final total = _stats?['total'] ?? 0;
    final lateEarlyLeave = _stats?['late_early_leave'] ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Presensi',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lacak performa kehadiran Anda',
                            style: TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                        tooltip: 'Unduh PDF',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Month & Year Pickers (Premium White)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedMonth,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
                              items: [
                                for (int i = 0; i <= 12; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text(
                                      _months[i],
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedMonth = v;
                                    _filter = '';
                                  });
                                  _load();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
                              items: [
                                for (int y in _availableYears)
                                  DropdownMenuItem(
                                    value: y,
                                    child: Text(
                                      y.toString(),
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedYear = v;
                                    _filter = '';
                                  });
                                  _load();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Premium Filter Pills inside header
                  Row(
                    children: [
                      for (final f in [('week', 'Minggu'), ('month', 'Bulan'), ('year', 'Tahun')])
                        Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 20),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _filter = f.$1;
                                // Sinkronkan bulan/tahun jika memilih filter "Bulan" atau "Tahun"
                                if (f.$1 == 'month') {
                                  _selectedMonth = DateTime.now().month;
                                  _selectedYear = DateTime.now().year;
                                } else if (f.$1 == 'year') {
                                  _selectedYear = DateTime.now().year;
                                }
                              });
                              _load();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _filter == f.$1 ? Colors.white : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                f.$2,
                                style: TextStyle(
                                  color: _filter == f.$1 ? const Color(0xFF1E3A8A) : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: const Color(0xFF2563EB),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      children: [
                        // Pie Chart Card Premium
                        if (total > 0)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.pie_chart_rounded, color: Color(0xFF2563EB), size: 20),
                                    SizedBox(width: 8),
                                    Text('Statistik Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  height: 160,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 40,
                                      sections: [
                                        if (present > 0) PieChartSectionData(value: present.toDouble(), color: const Color(0xFF22C55E), title: '$present', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        if (lateCount > 0) PieChartSectionData(value: lateCount.toDouble(), color: const Color(0xFFFBBF24), title: '$lateCount', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        if (absent > 0) PieChartSectionData(value: absent.toDouble(), color: const Color(0xFFEF4444), title: '$absent', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        if ((leave + sick) > 0) PieChartSectionData(value: (leave + sick).toDouble(), color: const Color(0xFF3B82F6), title: '${leave + sick}', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        if (earlyLeave > 0) PieChartSectionData(value: earlyLeave.toDouble(), color: const Color(0xFFF97316), title: '$earlyLeave', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        if (lateEarlyLeave > 0) PieChartSectionData(value: lateEarlyLeave.toDouble(), color: const Color(0xFFD946EF), title: '$lateEarlyLeave', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _legendItem(const Color(0xFF22C55E), 'Hadir', present),
                                    _legendItem(const Color(0xFFFBBF24), 'Terlambat', lateCount),
                                    _legendItem(const Color(0xFFEF4444), 'Alpha', absent),
                                    _legendItem(const Color(0xFF3B82F6), 'Izin/Sakit', leave + sick),
                                    _legendItem(const Color(0xFFF97316), 'Pulang di jam kerja', earlyLeave),
                                    _legendItem(const Color(0xFFD946EF), 'Terlambat & Pulang di jam kerja', lateEarlyLeave),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                        const Text('Detail Riwayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                        const SizedBox(height: 16),
                        if (_records.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 32),
                                Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('Belum ada riwayat', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        else
                          ...(_records.map((r) {
                            final rec = r as Map<String, dynamic>;
                            final status = rec['status'] ?? '';
                            final color = _statusColor(status);
                            final checkIn = rec['check_in_time']?.toString().isNotEmpty == true
                                ? rec['check_in_time'].toString().substring(11, 16) : '--:--';
                            final checkOut = rec['check_out_time']?.toString().isNotEmpty == true
                                ? rec['check_out_time'].toString().substring(11, 16) : '--:--';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.event_available_rounded, color: color, size: 22),
                                ),
                                title: Text(AppDateFormatter.formatFullDate(rec['date'] ?? ''), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$checkIn - $checkOut', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    if ((rec['salary_deduction'] ?? 0) > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '- Rp ${(rec['salary_deduction'] as num).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                    child: Text(
                                      _statusLabel(status), 
                                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })),
                      ],
                    ),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label ($count)', 
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
