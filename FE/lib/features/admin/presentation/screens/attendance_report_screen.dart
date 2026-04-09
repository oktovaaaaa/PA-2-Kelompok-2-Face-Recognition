import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/excel_export_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../common/widgets/app_dialog.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  List<dynamic> _allRecords = [];
  List<dynamic> _filteredRecords = [];
  bool _loading = false;
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  
  // New Analytics State
  DateTimeRange? _selectedDateRange;
  bool _isLineChart = false;
  bool _showStats = true;
  bool _showFilters = true; // State baru untuk buka tutup filter
  String _periodFilter = 'month'; // 'week', 'month', 'year', 'custom'
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      String attendanceUrl = '/api/admin/attendance?filter=$_periodFilter';
      
      if (_periodFilter == 'month') {
        attendanceUrl += '&month=$_selectedMonth&year=$_selectedYear';
      } else if (_periodFilter == 'year') {
        attendanceUrl += '&year=$_selectedYear';
      } else if (_periodFilter == 'custom' && _selectedDateRange != null) {
        final start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        final end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
        attendanceUrl = '/api/admin/attendance?start_date=$start&end_date=$end';
      }

      final res = await ApiClient.get(attendanceUrl);

      if (res.success && mounted) {
        setState(() {
          _allRecords = res.data ?? [];
          _applyFilters();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _allRecords.where((r) {
        final nameMatch = (r['user_name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
        final recordStatus = (r['status'] ?? r['type'] ?? '').toString().toUpperCase();
        
        bool statusMatch = _statusFilter == 'ALL';
        if (!statusMatch) {
          if (_statusFilter == 'IZIN') {
            statusMatch = recordStatus == 'IZIN' || recordStatus == 'LEAVE';
          } else if (_statusFilter == 'SAKIT') {
            statusMatch = recordStatus == 'SAKIT' || recordStatus == 'SICK';
          } else {
            statusMatch = recordStatus == _statusFilter;
          }
        }
        
        return nameMatch && statusMatch;
      }).toList();
    });
  }

  Future<void> _showDownloadDialog() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text('Unduh Laporan Excel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const Text('Pilih periode laporan yang ingin Anda unduh', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 24),
            _buildDownloadOption(
              icon: Icons.calendar_month_rounded,
              title: 'Laporan Bulanan',
              desc: 'Unduh laporan per bulan tertentu',
              onTap: () {
                Navigator.pop(context);
                _showDownloadFilterSelector('month');
              },
            ),
            const SizedBox(height: 12),
            _buildDownloadOption(
              icon: Icons.view_agenda_rounded,
              title: 'Laporan Tahunan',
              desc: 'Unduh laporan satu tahun penuh',
              onTap: () {
                Navigator.pop(context);
                _showDownloadFilterSelector('year');
              },
            ),
            const SizedBox(height: 12),
            _buildDownloadOption(
              icon: Icons.date_range_rounded,
              title: 'Rentang Tanggal',
              desc: 'Unduh laporan berdasarkan rentang dari-sampai',
              onTap: () {
                Navigator.pop(context);
                _showDownloadFilterSelector('custom');
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption({required IconData icon, required String title, required String desc, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _showDownloadFilterSelector(String type) async {
    int dlMonth = _selectedMonth;
    int dlYear = _selectedYear;
    DateTimeRange? dlRange = _selectedDateRange;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          type == 'month' ? 'Pilih Bulan & Tahun' : type == 'year' ? 'Pilih Tahun' : 'Pilih Rentang',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == 'month') ...[
                DropdownButton<int>(
                  value: dlMonth,
                  isExpanded: true,
                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMMM').format(DateTime(2000, i + 1))))),
                  onChanged: (v) => setDialogState(() => dlMonth = v!),
                ),
                const SizedBox(height: 12),
              ],
              if (type == 'month' || type == 'year')
                DropdownButton<int>(
                  value: dlYear,
                  isExpanded: true,
                  items: List.generate(5, (i) => DropdownMenuItem(value: DateTime.now().year - 2 + i, child: Text('${DateTime.now().year - 2 + i}'))),
                  onChanged: (v) => setDialogState(() => dlYear = v!),
                ),
              if (type == 'custom')
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => dlRange = picked);
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(dlRange == null ? 'Pilih Rentang' : '${DateFormat('dd/MM/yyyy').format(dlRange!.start)} - ${DateFormat('dd/MM/yyyy').format(dlRange!.end)}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDownloadProcess(type, month: dlMonth, year: dlYear, range: dlRange);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Unduh Sekarang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownloadProcess(String filterType, {int? month, int? year, DateTimeRange? range}) async {
    // Show Loading
    AppDialog.showLoading(context, message: 'Menyiapkan laporan...');
    
    try {
      String url = '/api/admin/attendance?filter=$filterType';
      String periodLabel = '';

      if (filterType == 'month') {
        url += '&month=$month&year=$year';
        periodLabel = '${DateFormat('MMMM').format(DateTime(2000, month!))} $year';
      } else if (filterType == 'year') {
        url += '&year=$year';
        periodLabel = 'Tahun $year';
      } else if (filterType == 'custom' && range != null) {
        final start = DateFormat('yyyy-MM-dd').format(range.start);
        final end = DateFormat('yyyy-MM-dd').format(range.end);
        url = '/api/admin/attendance?start_date=$start&end_date=$end';
        periodLabel = '${DateFormat('dd/MM/yyyy').format(range.start)} - ${DateFormat('dd/MM/yyyy').format(range.end)}';
      }

      final res = await ApiClient.get(url);
      Navigator.pop(context); // Hide Loading

      if (res.success && res.data != null) {
        final List<dynamic> records = res.data;
        
        // Calculate stats
        Map<String, int> stats = {'PRESENT': 0, 'LATE': 0, 'ABSENT': 0, 'WORKING': 0, 'NOT_YET': 0, 'EARLY_LEAVE': 0};
        for (var r in records) {
          final s = (r['status'] ?? '').toString().toUpperCase();
          if (stats.containsKey(s)) stats[s] = (stats[s] ?? 0) + 1;
        }

        final fileName = 'Laporan_Kehadiran_${periodLabel.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
        final path = await ExcelExportService.exportAttendance(records, fileName, stats: stats, periodLabel: periodLabel);
        
        if (mounted) {
          AppDialog.showSuccess(
            context, 
            'Laporan berhasil dibuat',
            confirmText: 'Buka File',
          ).then((confirmed) {
             if (confirmed == true) OpenFilex.open(path);
          });
        }
      } else {
        AppDialog.showError(context, 'Gagal mengambil data laporan');
      }
    } catch (e) {
      Navigator.pop(context); // Hide Loading
      AppDialog.showError(context, 'Terjadi kesalahan: $e');
    }
  }

  Future<void> _exportExcel() async {
    if (_filteredRecords.isEmpty) {
      AppDialog.showInfo(context, 'Tidak ada data untuk diekspor');
      return;
    }
    
    // Hitung statistik untuk Excel dari _filteredRecords
    Map<String, int> stats = {
      'PRESENT': 0, 'LATE': 0, 'ABSENT': 0, 'WORKING': 0, 'NOT_YET': 0, 'EARLY_LEAVE': 0,
    };
    for (var r in _filteredRecords) {
      final s = (r['status'] ?? '').toString().toUpperCase();
      if (stats.containsKey(s)) {
        stats[s] = (stats[s] ?? 0) + 1;
      }
    }

    String periodLabel = '';
    if (_periodFilter == 'month') {
      periodLabel = '${DateFormat('MMMM').format(DateTime(2000, _selectedMonth))} $_selectedYear';
    } else if (_periodFilter == 'year') {
      periodLabel = 'Tahun $_selectedYear';
    } else if (_periodFilter == 'custom' && _selectedDateRange != null) {
      periodLabel = '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';
    } else {
      periodLabel = _periodFilter;
    }

    try {
      final fileName = 'Laporan_Kehadiran_${periodLabel.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
      final path = await ExcelExportService.exportAttendance(
        _filteredRecords, 
        fileName,
        stats: stats,
        periodLabel: periodLabel,
      );
      
      if (mounted) {
        AppDialog.showSuccess(
          context, 
          'Laporan berhasil dibuat\nLokasi: $path',
          confirmText: 'Buka File',
        ).then((confirmed) {
           if (confirmed == true) OpenFilex.open(path);
        });
      }
    } catch (e) {
      if (mounted) AppDialog.showError(context, 'Gagal ekspor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Premium Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 64, left: 16, right: 8, bottom: 20),
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
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Laporan & Statistik',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _showStats = !_showStats),
                  icon: Icon(
                    _showStats ? Icons.bar_chart_rounded : Icons.visibility_rounded,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  tooltip: _showStats ? 'Sembunyikan Statistik' : 'Tampilkan Statistik',
                ),
                IconButton(
                  onPressed: _showDownloadDialog,
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  tooltip: 'Unduh Excel',
                ),
                if (_allRecords.isNotEmpty)
                  IconButton(
                    onPressed: _handleBulkDelete,
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    tooltip: 'Hapus Riwayat Periode Ini',
                  ),
              ],
            ),
          ),

            // Analytics Section
            if (!_loading && _allRecords.isNotEmpty) _buildAnalyticsSection(),

            // Filters & Date Range Selection
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Text('Filter Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                          ],
                        ),
                        Icon(_showFilters ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                  
                  if (_showFilters) ...[
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) {
                        _searchQuery = v;
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama karyawan...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _periodChip('week', 'Minggu Ini'),
                          _periodChip('month', 'Pilih Bulan'),
                          _periodChip('year', 'Pilih Tahun'),
                          _periodChip('custom', 'Pilih Rentang'),
                        ],
                      ),
                    ),
                    
                    if (_periodFilter == 'month' || _periodFilter == 'year') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (_periodFilter == 'month')
                            Expanded(child: _buildMonthDropdown()),
                          if (_periodFilter == 'month') const SizedBox(width: 12),
                          Expanded(child: _buildYearDropdown()),
                        ],
                      ),
                    ],

                    if (_periodFilter == 'custom') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildDateInput('Mulai', true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDateInput('Selesai', false)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('ALL', 'Semua'),
                          _filterChip('PRESENT', 'Hadir'),
                          _filterChip('LATE', 'Telat'),
                          _filterChip('ABSENT', 'Alpha'),
                          _filterChip('IZIN', 'Izin'),
                          _filterChip('SAKIT', 'Sakit'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _filteredRecords.isEmpty
                      ? Center(child: Text('Data tidak ditemukan', style: TextStyle(color: Colors.grey.shade500)))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                            itemCount: _filteredRecords.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final r = _filteredRecords[i] as Map<String, dynamic>;
                              return _buildAttendanceCard(r);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String status, String label) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF0F172A),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2563EB),
        onSelected: (v) {
          setState(() {
            _statusFilter = status;
            _applyFilters();
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
        showCheckmark: false,
      ),
    );
  }

  Widget _periodChip(String p, String label) {
    final isSelected = _periodFilter == p;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF2563EB),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        backgroundColor: const Color(0xFF2563EB).withOpacity(0.05),
        selectedColor: const Color(0xFF2563EB),
        onSelected: (v) {
          setState(() => _periodFilter = p);
          _loadData();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return _buildPickerTrigger(
      title: DateFormat('MMMM').format(DateTime(2000, _selectedMonth)),
      icon: Icons.calendar_month_rounded,
      onTap: () => _showMonthPickerSheet(
        current: _selectedMonth,
        onChanged: (v) {
          setState(() => _selectedMonth = v);
          _loadData();
        },
      ),
    );
  }

  Widget _buildYearDropdown() {
    return _buildPickerTrigger(
      title: '$_selectedYear',
      icon: Icons.event_available_rounded,
      onTap: () => _showYearPickerSheet(
        current: _selectedYear,
        onChanged: (v) {
          setState(() => _selectedYear = v);
          _loadData();
        },
      ),
    );
  }

  Widget _buildPickerTrigger({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showMonthPickerSheet({required int current, required Function(int) onChanged}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Pilih Bulan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = current == month;
                return InkWell(
                  onTap: () {
                    onChanged(month);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat('MMM').format(DateTime(2000, month)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showYearPickerSheet({required int current, required Function(int) onChanged}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Pilih Tahun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  final year = DateTime.now().year - 2 + index;
                  final isSelected = current == year;
                  return ListTile(
                    onTap: () {
                      onChanged(year);
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected ? const Color(0xFF2563EB).withOpacity(0.1) : null,
                    leading: Icon(Icons.calendar_today_rounded, size: 18, color: isSelected ? const Color(0xFF2563EB) : Colors.grey),
                    title: Text(
                      '$year',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInput(String label, bool isStart) {
    final date = isStart ? _selectedDateRange?.start : _selectedDateRange?.end;
    final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : '-';
    
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
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
    final initial = (isStart ? _selectedDateRange?.start : _selectedDateRange?.end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Membolehkan pemilihan ke depan untuk laporan rencana/target jika diperlukan, atau batasi sesuai kebutuhan
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
        if (isStart) {
          _selectedDateRange = DateTimeRange(start: picked, end: _selectedDateRange?.end ?? picked.add(const Duration(days: 1)));
        } else {
          _selectedDateRange = DateTimeRange(start: _selectedDateRange?.start ?? picked.subtract(const Duration(days: 1)), end: picked);
        }
      });
      _loadData();
    }
  }

  Future<void> _handleBulkDelete() async {
    String periodLabel = '';
    if (_periodFilter == 'month') {
      periodLabel = '${DateFormat('MMMM').format(DateTime(2000, _selectedMonth))} $_selectedYear';
    } else if (_periodFilter == 'year') {
      periodLabel = 'Tahun $_selectedYear';
    } else if (_periodFilter == 'custom' && _selectedDateRange != null) {
      periodLabel = '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';
    } else {
      periodLabel = 'Periode Terpilih';
    }

    // STEP 1: Konfirmasi Awal
    final confirm1 = await AppDialog.showConfirm(
      context,
      title: 'Hapus Riwayat',
      message: 'Apakah Anda yakin ingin menghapus seluruh riwayat kehadiran untuk periode $periodLabel bagi SEMUA karyawan?',
    );
    if (confirm1 != true) return;

    // STEP 2: Peringatan Bahaya
    if (!mounted) return;
    final confirm2 = await AppDialog.showConfirm(
      context,
      title: 'TINDAKAN KRUSIAL',
      message: 'Data ini sangat penting dan tidak dapat dikembalikan setelah dihapus. Hal ini juga akan mempengaruhi perhitungan gaji karyawan. Lanjutkan dengan risiko Anda sendiri?',
      confirmText: 'Sangat Yakin',
      confirmColor: Colors.red.shade700,
    );
    if (confirm2 != true) return;

    // STEP 3: Verifikasi Teks
    if (!mounted) return;
    final expectedPhrase = 'HAPUS ${periodLabel.toUpperCase()}';
    final TextEditingController verifyCtrl = TextEditingController();
    bool canDelete = false;

    final confirm3 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Verifikasi Terakhir', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Untuk mengonfirmasi, ketik kalimat di bawah ini:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: SelectableText(expectedPhrase, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: verifyCtrl,
                onChanged: (v) => setDialogState(() => canDelete = v.trim().toUpperCase() == expectedPhrase),
                decoration: InputDecoration(
                  hintText: 'Ketik di sini...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: canDelete ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Hapus Permanen'),
            ),
          ],
        ),
      ),
    );

    if (confirm3 != true) return;

    // EXECUTION
    AppDialog.showLoading(context, message: 'Menghapus data...');
    try {
      String url = '/api/admin/attendance?filter=$_periodFilter';
      if (_periodFilter == 'month') {
        url += '&month=$_selectedMonth&year=$_selectedYear';
      } else if (_periodFilter == 'year') {
        url += '&year=$_selectedYear';
      } else if (_periodFilter == 'custom' && _selectedDateRange != null) {
        final start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        final end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
        url = '/api/admin/attendance?filter=custom&start_date=$start&end_date=$end';
      }

      final res = await ApiClient.delete(url);
      Navigator.pop(context); // Close loading

      if (res.success) {
        AppDialog.showSuccess(context, 'Data riwayat periode $periodLabel telah dihapus secara permanen.');
        _loadData();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal menghapus data');
      }
    } catch (e) {
      Navigator.pop(context);
      AppDialog.showError(context, 'Terjadi kesalahan sistem: $e');
    }
  }

  Widget _buildAnalyticsSection() {
    if (!_showStats) return const SizedBox.shrink();

    // Agreggate data for charts
    Map<String, Map<String, int>> dailyStats = {};
    int present = 0, late = 0, absent = 0, working = 0, notYet = 0, earlyLeave = 0, other = 0;

    for (var r in _filteredRecords) {
      final date = (r['date'] ?? '').toString();
      final status = (r['status'] ?? '').toString().toUpperCase();
      
      if (!dailyStats.containsKey(date)) {
        dailyStats[date] = {'PRESENT': 0, 'LATE': 0, 'ABSENT': 0, 'WORKING': 0, 'NOT_YET': 0, 'EARLY_LEAVE': 0, 'OTHER': 0};
      }

      if (status == 'PRESENT') { present++; dailyStats[date]!['PRESENT'] = (dailyStats[date]!['PRESENT'] ?? 0) + 1; }
      else if (status == 'LATE') { late++; dailyStats[date]!['LATE'] = (dailyStats[date]!['LATE'] ?? 0) + 1; }
      else if (status == 'ABSENT') { absent++; dailyStats[date]!['ABSENT'] = (dailyStats[date]!['ABSENT'] ?? 0) + 1; }
      else if (status == 'WORKING') { working++; dailyStats[date]!['WORKING'] = (dailyStats[date]!['WORKING'] ?? 0) + 1; }
      else if (status == 'NOT_YET') { notYet++; dailyStats[date]!['NOT_YET'] = (dailyStats[date]!['NOT_YET'] ?? 0) + 1; }
      else if (status == 'EARLY_LEAVE') { earlyLeave++; dailyStats[date]!['EARLY_LEAVE'] = (dailyStats[date]!['EARLY_LEAVE'] ?? 0) + 1; }
      else { other++; dailyStats[date]!['OTHER'] = (dailyStats[date]!['OTHER'] ?? 0) + 1; }
    }

    final sortedDates = dailyStats.keys.toList()..sort();
    // Only show last 7 days in chart if many
    final displayDates = sortedDates.length > 7 ? sortedDates.sublist(sortedDates.length - 7) : sortedDates;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tren Kehadiran (7 Hari)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isLineChart = false),
                    icon: Icon(Icons.bar_chart_rounded, size: 18, color: !_isLineChart ? const Color(0xFF2563EB) : Colors.grey.shade300),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isLineChart = true),
                    icon: Icon(Icons.show_chart_rounded, size: 18, color: _isLineChart ? const Color(0xFF2563EB) : Colors.grey.shade300),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: _isLineChart 
              ? _buildLineChart(displayDates, dailyStats)
              : _buildBarChart(displayDates, dailyStats),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              _legendItem(Colors.green, 'Hadir', size: 10),
              _legendItem(Colors.orange, 'Telat', size: 10),
              _legendItem(const Color(0xFF818CF8), 'Aktif', size: 10),
              _legendItem(Colors.red, 'Alpha', size: 10),
              _legendItem(Colors.grey.shade400, 'Mangkir', size: 10),
              _legendItem(const Color(0xFFD946EF), 'Terlambat & Pulang di jam kerja', size: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<String> dates, Map<String, Map<String, int>> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= dates.length) return const SizedBox();
                final d = dates[val.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(d.substring(8), style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dates.length, (i) {
          final d = dates[i];
          final s = data[d]!;
          
          bool isHoliday = (s['PRESENT'] ?? 0) == 0 && (s['LATE'] ?? 0) == 0 && (s['ABSENT'] ?? 0) == 0 && 
                           (s['WORKING'] ?? 0) == 0 && (s['EARLY_LEAVE'] ?? 0) == 0 && (s['OTHER'] ?? 0) == 0;

          if (isHoliday) {
             return BarChartGroupData(
                x: i,
                barRods: [
                   BarChartRodData(toY: 0.5, color: Colors.grey.withOpacity(0.1), width: 24, borderRadius: BorderRadius.circular(4)),
                ],
             );
          }

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: (s['PRESENT'] ?? 0).toDouble(), color: const Color(0xFF22C55E), width: 6),
              BarChartRodData(toY: (s['LATE'] ?? 0).toDouble(), color: const Color(0xFFFBBF24), width: 6),
              BarChartRodData(toY: (s['ABSENT'] ?? 0).toDouble(), color: const Color(0xFFEF4444), width: 6),
              BarChartRodData(toY: (s['OTHER'] ?? 0).toDouble(), color: const Color(0xFF3B82F6), width: 6),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(List<String> dates, Map<String, Map<String, int>> data) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
            tooltipBorder: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade200, width: 1),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.x.toInt() >= dates.length) return null;
                final date = dates[spot.x.toInt()];
                final s = data[date]!;
                
                // Detection logic matches _lineData
                bool isHoliday = (s['PRESENT'] ?? 0) == 0 && (s['LATE'] ?? 0) == 0 && (s['ABSENT'] ?? 0) == 0 && 
                                 (s['WORKING'] ?? 0) == 0 && (s['EARLY_LEAVE'] ?? 0) == 0 && (s['OTHER'] ?? 0) == 0;
                
                final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
                
                if (isHoliday) {
                  return LineTooltipItem(
                    'HARI LIBUR\n$date',
                    TextStyle(
                      color: isDarkTheme ? const Color(0xFFFDBA74) : const Color(0xFFEA580C), 
                      fontWeight: FontWeight.bold, 
                      fontSize: 11
                    ),
                  );
                }
                
                String label;
                Color textColor;
                
                if (spot.barIndex % 4 == 0) { 
                  label = 'Hadir'; textColor = isDarkTheme ? const Color(0xFF4ADE80) : const Color(0xFF15803D); 
                } else if (spot.barIndex % 4 == 1) { 
                  label = 'Telat'; textColor = isDarkTheme ? const Color(0xFFFBBF24) : const Color(0xFFB45309); 
                } else if (spot.barIndex % 4 == 2) { 
                  label = 'Alpha'; textColor = isDarkTheme ? const Color(0xFFF87171) : const Color(0xFFB91C1C); 
                } else { 
                  label = 'Izin'; textColor = isDarkTheme ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8); 
                }

                return LineTooltipItem(
                  '$label: ${spot.y.toInt()}',
                  TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= dates.length) return const SizedBox();
                final d = dates[val.toInt()];
                return Text(d.substring(8), style: TextStyle(color: Colors.grey.shade500, fontSize: 10));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          ..._lineData(dates, data, 'PRESENT', Colors.green),
          ..._lineData(dates, data, 'LATE', Colors.orange),
          ..._lineData(dates, data, 'ABSENT', Colors.red),
          ..._lineData(dates, data, 'OTHER', Colors.blue),
        ],
      ),
    );
  }

  List<LineChartBarData> _lineData(List<String> dates, Map<String, Map<String, int>> data, String key, Color color) {
    List<LineChartBarData> segments = [];
    List<FlSpot> currentSegment = [];

    for (int i = 0; i < dates.length; i++) {
      final d = dates[i];
      final s = data[d]!;
      // Check if it's a holiday (all major categories are 0 or null)
      bool isHoliday = (s['PRESENT'] ?? 0) == 0 && (s['LATE'] ?? 0) == 0 && (s['ABSENT'] ?? 0) == 0 && 
                       (s['WORKING'] ?? 0) == 0 && (s['EARLY_LEAVE'] ?? 0) == 0 && (s['OTHER'] ?? 0) == 0;

      if (isHoliday) {
        if (currentSegment.isNotEmpty) {
          segments.add(_createLineBarData(currentSegment, color));
          currentSegment = [];
        }
      } else {
        currentSegment.add(FlSpot(i.toDouble(), (s[key] ?? 0).toDouble()));
      }
    }

    if (currentSegment.isNotEmpty) {
      segments.add(_createLineBarData(currentSegment, color));
    }

    return segments;
  }

  LineChartBarData _createLineBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }

  Widget _legendItem(Color color, String label, {double? size}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: size ?? 11), softWrap: true)),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> r) {
    final status = (r['status'] ?? r['type'] ?? '').toString().toUpperCase();
    Color statusColor;
    String statusLabel;
    
    switch (status) {
      case 'PRESENT': statusColor = Colors.green; statusLabel = 'Hadir Tepat Waktu'; break;
      case 'LATE': statusColor = Colors.orange; statusLabel = 'Terlambat'; break;
      case 'ABSENT': statusColor = Colors.red; statusLabel = 'Alpha'; break;
      case 'NOT_YET': statusColor = Colors.grey; statusLabel = 'Belum Hadir'; break;
      case 'WORKING': statusColor = Color(0xFF818CF8); statusLabel = 'Sedang Bekerja'; break; // Indigo shade
      case 'EARLY_LEAVE': statusColor = const Color(0xFFF97316); statusLabel = 'Pulang di jam kerja'; break;
      case 'LATE_EARLY_LEAVE': statusColor = const Color(0xFFD946EF); statusLabel = 'Terlambat & Pulang di jam kerja'; break;
      case 'LEAVE': 
      case 'IZIN': statusColor = Colors.blue; statusLabel = 'Izin'; break;
      case 'SICK': 
      case 'SAKIT': statusColor = Colors.purple; statusLabel = 'Sakit'; break;
      default: statusColor = Colors.grey; statusLabel = status;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
            child: Text((r['user_name'] ?? 'K').substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['user_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                Text(AppDateFormatter.formatFullDate(r['date'] ?? '-'), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    statusLabel, 
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                r['is_leave'] == true
                    ? (r['title']?.toString() ?? 'Cuti/Izin')
                    : '${r['check_in_time']?.toString().substring(11, 16) ?? '--:--'} - ${r['check_out_time']?.toString().substring(11, 16) ?? '--:--'}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
