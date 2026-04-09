// lib/features/admin/presentation/screens/employee_stats_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:front_end/core/network/api_client.dart';
import 'package:front_end/core/utils/date_formatter.dart';
import 'package:front_end/core/utils/error_mapper.dart';
import '../../../common/widgets/app_dialog.dart';

class EmployeeStatsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? photoUrl;

  const EmployeeStatsScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.photoUrl,
  });

  @override
  State<EmployeeStatsScreen> createState() => _EmployeeStatsScreenState();
}

class _EmployeeStatsScreenState extends State<EmployeeStatsScreen> {
  bool _loading = false;
  List<dynamic> _records = [];
  Map<String, int> _stats = {
    'PRESENT': 0, 
    'LATE': 0, 
    'ABSENT': 0, 
    'LEAVE': 0, 
    'SICK': 0, 
    'EARLY_LEAVE': 0, 
    'LATE_EARLY_LEAVE': 0,
  };
  String _filter = 'month';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [DateTime.now().year];
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _months = [
    'Semua Bulan', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAvailableYears();
    _loadStats();
  }

  Future<void> _fetchAvailableYears() async {
    try {
      final res = await ApiClient.get('/api/admin/attendance/years?user_id=${widget.userId}');
      if (res.success && res.data != null) {
        final List<dynamic> years = res.data;
        setState(() {
          _availableYears = years.map((e) => int.parse(e.toString())).toList();
          // Pastikan tahun ini ada di daftar meskipun belum ada data
          if (!_availableYears.contains(DateTime.now().year)) {
            _availableYears.insert(0, DateTime.now().year);
            _availableYears.sort((a, b) => b.compareTo(a));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      String url = '/api/admin/attendance?filter=$_filter&user_id=${widget.userId}';
      
      if (_filter == 'month' || _filter == 'year') {
        url += '&year=$_selectedYear';
        if (_filter == 'month' && _selectedMonth != 0) {
          url += '&month=$_selectedMonth';
        }
      } else if (_filter == 'custom' && _startDate != null && _endDate != null) {
        final s = _startDate!.toString().substring(0, 10);
        final e = _endDate!.toString().substring(0, 10);
        url = '/api/admin/attendance?start_date=$s&end_date=$e&user_id=${widget.userId}';
      }
      
      final res = await ApiClient.get(url);
      if (res.success && mounted) {
        final List<dynamic> data = res.data ?? [];
        _records = data;
        
        // Reset stats
        _stats = {
          'PRESENT': 0, 
          'LATE': 0, 
          'ABSENT': 0, 
          'LEAVE': 0, 
          'SICK': 0,
          'EARLY_LEAVE': 0,
          'LATE_EARLY_LEAVE': 0,
        };
        
        for (var r in data) {
          final status = (r['status'] ?? '').toString().toUpperCase();
          if (_stats.containsKey(status)) {
            _stats[status] = (_stats[status] ?? 0) + 1;
          }
        }
        setState(() {});
      }
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (mounted) AppDialog.showError(context, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final pts = name.trim().split(RegExp(r'\s+'));
    if (pts.length >= 2) {
      return (pts[0][0] + pts[1][0]).toUpperCase();
    }
    return pts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 28),
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
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Statistik Karyawan',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          backgroundImage: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                              ? NetworkImage('http://10.0.2.2:8080${widget.photoUrl}')
                              : null,
                          child: (widget.photoUrl == null || widget.photoUrl!.isEmpty)
                              ? Text(
                                  _getInitials(widget.userName),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('ID: ${widget.userId.substring(0, 8)}...', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Filter
                        _buildFilterRow(),
                        const SizedBox(height: 24),

                        // Stats Summary
                        _buildStatsSummary(),
                        const SizedBox(height: 24),

                        // History Header
                        const Text('Riwayat Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        const SizedBox(height: 12),
                        
                        if (_records.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(40),
                            child: Center(child: Text('Tidak ada data untuk periode ini.', style: TextStyle(color: Colors.grey.shade500))),
                          )
                        else
                          ..._records.map((r) => _buildRecordItem(r)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _filterBtn('week', 'Minggu'),
            const SizedBox(width: 8),
            _filterBtn('month', 'Bulan'),
            const SizedBox(width: 8),
            _filterBtn('year', 'Tahun'),
            const SizedBox(width: 8),
            _filterBtn('custom', 'Kustom'),
          ],
        ),
        if (_filter == 'custom') ...[
          const SizedBox(height: 16),
          _buildDateRangePicker(),
        ] else if (_filter == 'month' || _filter == 'year') ...[
          const SizedBox(height: 16),
          _buildPeriodPicker(),
        ],
      ],
    );
  }

  Widget _buildPeriodPicker() {
    return Row(
      children: [
        if (_filter == 'month')
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMonth,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: List.generate(13, (i) => DropdownMenuItem(
                    value: i,
                    child: Text(_months[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  )),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedMonth = v);
                      _loadStats();
                    }
                  },
                ),
              ),
            ),
          ),
        if (_filter == 'month') const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _availableYears.map((y) => DropdownMenuItem(
                  value: y,
                  child: Text(y.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                )).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedYear = v);
                    _loadStats();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(child: _buildDateInput('Mulai', true)),
        const SizedBox(width: 12),
        Expanded(child: _buildDateInput('Selesai', false)),
      ],
    );
  }

  Widget _buildDateInput(String label, bool isStart) {
    final date = isStart ? _startDate : _endDate;
    final dateStr = date != null ? date.toString().substring(0, 10) : 'Pilih';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickSingleDate(isStart),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(child: Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickSingleDate(bool isStart) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB), onPrimary: Colors.white, onSurface: Color(0xFF0F172A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
      if (_startDate != null && _endDate != null) _loadStats();
    }
  }

  Widget _filterBtn(String f, String label) {
    final active = _filter == f;
    return InkWell(
      onTap: () {
        setState(() => _filter = f);
        _loadStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF2563EB) : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey.shade600, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final total = _stats.values.reduce((a, b) => a + b);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140, // Mengecilkan sedikit tinggi chart
            child: total == 0 
              ? const Center(child: Text('N/A'))
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: [
                      if (_stats['PRESENT']! > 0) PieChartSectionData(value: _stats['PRESENT']!.toDouble(), color: Colors.green, radius: 20, showTitle: false),
                      if (_stats['LATE']! > 0) PieChartSectionData(value: _stats['LATE']!.toDouble(), color: Colors.orange, radius: 20, showTitle: false),
                      if (_stats['ABSENT']! > 0) PieChartSectionData(value: _stats['ABSENT']!.toDouble(), color: Colors.red, radius: 20, showTitle: false),
                      if (_stats['LEAVE']! > 0) PieChartSectionData(value: _stats['LEAVE']!.toDouble(), color: Colors.blue, radius: 20, showTitle: false),
                      if (_stats['SICK']! > 0) PieChartSectionData(value: _stats['SICK']!.toDouble(), color: Colors.purple, radius: 20, showTitle: false),
                      if (_stats['EARLY_LEAVE']! > 0) PieChartSectionData(value: _stats['EARLY_LEAVE']!.toDouble(), color: const Color(0xFFF97316), radius: 20, showTitle: false),
                      if (_stats['LATE_EARLY_LEAVE']! > 0) PieChartSectionData(value: _stats['LATE_EARLY_LEAVE']!.toDouble(), color: const Color(0xFFD946EF), radius: 20, showTitle: false),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _statItem(Colors.green, 'Hadir', _stats['PRESENT']!),
              _statItem(Colors.orange, 'Telat', _stats['LATE']!),
              _statItem(Colors.red, 'Alpha', _stats['ABSENT']!),
              _statItem(Colors.blue, 'Izin', _stats['LEAVE']!),
              _statItem(Colors.purple, 'Sakit', _stats['SICK']!),
              _statItem(const Color(0xFFF97316), 'Plg Awal', _stats['EARLY_LEAVE']!),
              _statItem(const Color(0xFFD946EF), 'Kombinasi', _stats['LATE_EARLY_LEAVE']!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ($count)', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> r) {
    final status = (r['status'] ?? '').toString().toUpperCase();
    Color statusColor;
    String statusLabel;
    
    switch (status) {
      case 'PRESENT': statusColor = Colors.green; statusLabel = 'Hadir'; break;
      case 'LATE': statusColor = Colors.orange; statusLabel = 'Terlambat'; break;
      case 'ABSENT': statusColor = Colors.red; statusLabel = 'Alpha'; break;
      case 'LEAVE': statusColor = Colors.blue; statusLabel = 'Izin'; break;
      case 'SICK': statusColor = Colors.purple; statusLabel = 'Sakit'; break;
      case 'WORKING': statusColor = const Color(0xFF818CF8); statusLabel = 'Sedang Bekerja'; break;
      case 'NOT_YET': statusColor = Colors.grey; statusLabel = 'Belum Hadir'; break;
      case 'EARLY_LEAVE': statusColor = const Color(0xFFF97316); statusLabel = 'Pulang di jam kerja'; break;
      case 'LATE_EARLY_LEAVE': statusColor = const Color(0xFFD946EF); statusLabel = 'Terlambat & Pulang di jam kerja'; break;
      default: statusColor = Colors.grey; statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppDateFormatter.formatFullDate(r['date'] ?? '-'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                '${r['check_in_time']?.toString().substring(11, 16) ?? '--:--'} - ${r['check_out_time']?.toString().substring(11, 16) ?? '--:--'}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
