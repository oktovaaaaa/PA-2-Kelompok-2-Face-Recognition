// lib/features/admin/presentation/screens/holiday_management_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../common/widgets/app_dialog.dart';
import '../../../../core/utils/date_formatter.dart';

class HolidayManagementScreen extends StatefulWidget {
  const HolidayManagementScreen({super.key});

  @override
  State<HolidayManagementScreen> createState() => _HolidayManagementScreenState();
}

class _HolidayManagementScreenState extends State<HolidayManagementScreen> {
  List<dynamic> _holidays = [];
  Map<String, dynamic>? _settings;
  List<String> _workDays = [];
  bool _isLoading = true;
  bool _isSettingsLoading = true;

  final List<String> ALL_DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final Map<String, String> DAY_LABELS = {
    'Monday': 'Sen', 'Tuesday': 'Sel', 'Wednesday': 'Rab', 'Thursday': 'Kam', 'Friday': 'Jum', 'Saturday': 'Sab', 'Sunday': 'Min'
  };

  @override
  void initState() {
    super.initState();
    _loadHolidays();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isSettingsLoading = true);
    final res = await ApiClient.get('/api/admin/attendance-settings');
    if (res.success) {
      setState(() {
        _settings = res.data;
        _workDays = (_settings?['work_days'] as String? ?? 'Monday,Tuesday,Wednesday,Thursday,Friday').split(',');
        if (_workDays.length == 1 && _workDays[0] == "") _workDays = [];
      });
    }
    setState(() => _isSettingsLoading = false);
  }

  Future<void> _saveWorkDays() async {
    if (_settings == null) {
      AppDialog.showError(context, 'Data pengaturan belum dimuat sempurna');
      return;
    }

    AppDialog.showLoading(context, message: 'Menyimpan jadwal...');

    try {
      final res = await ApiClient.put('/api/admin/attendance-settings', {
        ..._settings!,
        'work_days': _workDays.join(','),
        // Kirim late_penalty_tiers apa adanya, backend sudah bisa menangani string JSON
        'late_penalty_tiers': _settings!['late_penalty_tiers'],
      });
      
      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog loading

      if (res.success) {
        AppDialog.showSuccess(context, 'Jadwal kerja rutin diperbarui');
        _loadSettings();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal menyimpan jadwal');
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        Navigator.pop(context); 
        AppDialog.showError(context, 'Terjadi kesalahan sistem: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteAllPast() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text('Tindakan ini akan menghapus semua data libur yang sudah lewat secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus Semua', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await ApiClient.delete('/api/admin/holidays/past');
      if (res.success) {
        AppDialog.showSuccess(context, 'Pembersihan riwayat berhasil');
        _loadHolidays();
      }
    }
  }

  Future<void> _loadHolidays() async {
    setState(() => _isLoading = true);
    final res = await ApiClient.get('/api/admin/holidays');
    if (res.success) {
      setState(() => _holidays = res.data ?? []);
    }
    setState(() => _isLoading = false);
  }

  void _showAddEditDialog([dynamic holiday]) {
    final isEdit = holiday != null;
    final nameCtrl = TextEditingController(text: holiday?['name'] ?? '');
    final descCtrl = TextEditingController(text: holiday?['description'] ?? '');
    DateTime startDate = isEdit ? DateTime.parse(holiday['start_date']) : DateTime.now();
    DateTime endDate = isEdit ? DateTime.parse(holiday['end_date']) : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Hari Libur' : 'Tambah Hari Libur',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 24),
                _buildLabel('Nama Libur'),
                TextField(
                  controller: nameCtrl,
                  decoration: _inputDec('Contoh: Libur Lebaran', Icons.beach_access_rounded),
                ),
                const SizedBox(height: 16),
                _buildLabel('Deskripsi'),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: _inputDec('Keterangan libur...', Icons.description_outlined),
                ),
                const SizedBox(height: 16),
                _buildLabel('Rentang Tanggal'),
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: DateTimeRange(start: startDate, end: endDate),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setModalState(() {
                        startDate = picked.start;
                        endDate = picked.end;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Text(
                          '${AppDateFormatter.formatFullDate(startDate.toString())} - ${AppDateFormatter.formatFullDate(endDate.toString())}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) {
                        AppDialog.showError(ctx, 'Nama libur tidak boleh kosong');
                        return;
                      }
                      Navigator.pop(ctx);
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'start_date': DateFormat('yyyy-MM-dd').format(startDate),
                        'end_date': DateFormat('yyyy-MM-dd').format(endDate),
                      };

                      final res = isEdit 
                        ? await ApiClient.put('/api/admin/holidays/${holiday['id']}', data)
                        : await ApiClient.post('/api/admin/holidays', data);

                      if (res.success) {
                        _loadHolidays();
                        AppDialog.showSuccess(context, isEdit ? 'Libur diperbarui' : 'Libur ditambahkan');
                      } else {
                        AppDialog.showError(context, res.message ?? 'Gagal menyimpan');
                      }
                    },
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan Libur'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Split holidays
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    final activeHolidays = _holidays.where((h) => (h['end_date'] as String).compareTo(todayStr) >= 0).toList();
    final pastHolidays = _holidays.where((h) => (h['end_date'] as String).compareTo(todayStr) < 0).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _isLoading || _isSettingsLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- Blue Gradient Header with Tabs ---
                Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            ),
                            const Expanded(
                              child: Text(
                                'Kelola Hari Libur', 
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48), // Spacer for balance
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const TabBar(
                        dividerColor: Colors.transparent,
                        indicatorColor: Colors.white,
                        indicatorWeight: 4,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        tabs: [
                          Tab(text: 'Akan Datang'),
                          Tab(text: 'Riwayat'),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // --- Tab Content ---
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Akan Datang
                      RefreshIndicator(
                        onRefresh: () async {
                          await _loadHolidays();
                          await _loadSettings();
                        },
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            // --- Jadwal Rutin Card ---
                            _buildSectionHeader('Jadwal Kerja Rutin', Icons.event_repeat_rounded),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                children: [
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: ALL_DAYS.map((day) {
                                      final isSelected = _workDays.contains(day);
                                      final isWeekend = day == 'Saturday' || day == 'Sunday';
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _workDays.remove(day);
                                            } else {
                                              _workDays.add(day);
                                            }
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            DAY_LABELS[day]!,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : (isWeekend ? Colors.red.shade300 : Colors.grey.shade600),
                                              fontWeight: FontWeight.bold, fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _saveWorkDays,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      child: const Text('Simpan Jadwal Rutin', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // --- Active Manual Holiday List ---
                            _buildSectionHeader('Daftar Libur Khusus', Icons.upcoming_rounded),
                            const SizedBox(height: 12),
                            if (activeHolidays.isEmpty)
                              _buildEmptyState('Tidak ada libur terdekat'),
                            ...activeHolidays.map((h) => _buildHolidayCard(h)).toList(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),

                      // Tab 2: Riwayat
                      RefreshIndicator(
                        onRefresh: _loadHolidays,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (pastHolidays.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Data Libur Sebelumnya', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                    TextButton.icon(
                                      onPressed: _deleteAllPast,
                                      icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.red),
                                      label: const Text('Hapus Semua', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            if (pastHolidays.isEmpty)
                              _buildEmptyState('Riwayat libur masih kosong'),
                            ...pastHolidays.map((h) => _buildHolidayCard(h, isPast: true)).toList(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditDialog(),
          backgroundColor: const Color(0xFF2563EB),
          child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Daftar akan muncul di sini jika sudah ditambahkan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayCard(dynamic h, {bool isPast = false}) {
    final start = DateTime.parse(h['start_date']);
    final end = DateTime.parse(h['end_date']);
    final isRange = start.day != end.day || start.month != end.month || start.year != end.year;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPast ? Colors.grey.shade100 : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPast ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(
              Icons.beach_access_rounded, 
              color: isPast ? Colors.grey.shade400 : const Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h['name'], 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: isPast ? Colors.grey.shade400 : const Color(0xFF1E293B)
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  isRange 
                    ? '${AppDateFormatter.formatFullDate(h['start_date'])} - ${AppDateFormatter.formatFullDate(h['end_date'])}'
                    : AppDateFormatter.formatFullDate(h['start_date']),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert_rounded, color: isPast ? Colors.grey.shade300 : Colors.grey.shade500),
            itemBuilder: (ctx) => [
              if (!isPast) const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (val) async {
              if (val == 'edit') {
                _showAddEditDialog(h);
              } else {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Libur?'),
                    content: const Text('Apakah Anda yakin ingin menghapus data libur ini?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  final res = await ApiClient.delete('/api/admin/holidays/${h['id']}');
                  if (res.success) {
                    _loadHolidays();
                    AppDialog.showSuccess(context, 'Data libur dihapus');
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
