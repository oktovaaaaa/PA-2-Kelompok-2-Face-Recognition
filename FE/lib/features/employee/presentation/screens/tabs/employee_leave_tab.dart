// lib/features/employee/presentation/screens/tabs/employee_leave_tab.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:intl/intl.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/constants/app_constants.dart';
import 'package:flutter/services.dart';
import '../../../../common/widgets/app_dialog.dart';

class EmployeeLeaveTab extends StatefulWidget {
  const EmployeeLeaveTab({super.key});

  @override
  State<EmployeeLeaveTab> createState() => _EmployeeLeaveTabState();
}

class _EmployeeLeaveTabState extends State<EmployeeLeaveTab> {
  List<dynamic> _leaves = [];
  bool _loading = false;
  
  // Filtering states
  int _selectedMonth = 0; // Default: Semua Bulan
  int _selectedYear = DateTime.now().year;
  
  // Selection states
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  final _statusColors = {
    'PENDING': const Color(0xFFF59E0B),
    'APPROVED': const Color(0xFF10B981),
    'REJECTED': const Color(0xFFEF4444),
  };
  final _statusLabels = {
    'PENDING': 'Menunggu',
    'APPROVED': 'Disetujui',
    'REJECTED': 'Ditolak',
  };

  final List<String> _months = [
    'Semua Bulan', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final query = 'month=${_selectedMonth == 0 ? "" : _selectedMonth}&year=$_selectedYear';
      final res = await ApiClient.get('/api/employee/leaves?$query');
      if (res.success && mounted) setState(() => _leaves = res.data ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    String selectedType = existing?['type'] ?? 'IZIN';
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    bool confirmed = false;
    File? pickedPhoto;
    String? uploadedPhotoUrl = existing?['photo_url'];

    // Multi-date selection state
    List<DateTime?> selectedDates = [];
    if (existing?['dates'] != null && (existing!['dates'] as String).isNotEmpty) {
      try {
        final List<dynamic> datesStr = jsonDecode(existing['dates']);
        selectedDates = datesStr.map((d) => DateTime.parse(d as String)).toList();
      } catch (_) {}
    } else if (existing?['created_at'] != null) {
      selectedDates = [DateTime.parse(existing!['created_at'])];
    }
    
    // Calendar mode: single/multi (Beberapa Hari) or range (Rentang)
    CalendarDatePicker2Type calendarType = CalendarDatePicker2Type.multi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEdit ? 'Edit Izin' : 'Ajukan Izin/Sakit',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tipe
                Row(
                  children: [
                    for (final t in ['IZIN', 'SAKIT'])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: t == 'IZIN' ? 8.0 : 0),
                          child: ChoiceChip(
                            label: Text(t == 'IZIN' ? 'Izin' : 'Sakit'),
                            selected: selectedType == t,
                            onSelected: (_) => setModal(() => selectedType = t),
                            selectedColor: const Color(0xFF2563EB),
                            labelStyle: TextStyle(color: selectedType == t ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Mode Tanggal Toggle
                const Text('Mode Pemilihan Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _buildModeButton(
                        label: 'Beberapa Hari',
                        icon: Icons.calendar_month_rounded,
                        active: calendarType == CalendarDatePicker2Type.multi,
                        onTap: () => setModal(() {
                          calendarType = CalendarDatePicker2Type.multi;
                          selectedDates = [];
                        }),
                      ),
                      const SizedBox(width: 4),
                      _buildModeButton(
                        label: 'Rentang Waktu',
                        icon: Icons.date_range_rounded,
                        active: calendarType == CalendarDatePicker2Type.range,
                        onTap: () => setModal(() {
                          calendarType = CalendarDatePicker2Type.range;
                          selectedDates = [];
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Kalender
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: CalendarDatePicker2(
                    config: CalendarDatePicker2Config(
                      calendarType: calendarType,
                      selectedDayHighlightColor: const Color(0xFF2563EB),
                      weekdayLabelTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      controlsTextStyle: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    value: selectedDates,
                    onValueChanged: (dates) => setModal(() => selectedDates = dates),
                  ),
                ),
                if (selectedDates.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    calendarType == CalendarDatePicker2Type.range && selectedDates.length >= 2 && selectedDates[1] != null
                        ? 'Terpilih: ${DateFormat('dd MMM').format(selectedDates[0]!)} - ${DateFormat('dd MMM yyyy').format(selectedDates[1]!)}'
                        : 'Terpilih: ${selectedDates.length} Hari',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Judul Izin',
                    hintText: 'contoh: Izin Pernikahan Saudara',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Keterangan',
                    hintText: 'Jelaskan alasan izin...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Upload foto bukti
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (picked != null) setModal(() => pickedPhoto = File(picked.path));
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: pickedPhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(pickedPhoto!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : uploadedPhotoUrl != null && uploadedPhotoUrl!.isNotEmpty
                            ? Center(child: Text('📷 Foto sudah ada', style: TextStyle(color: Colors.grey.shade600)))
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_rounded, color: Colors.grey.shade400, size: 32),
                                    Text('Tambah Foto Bukti (opsional)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 12),
                // Checkbox konfirmasi
                CheckboxListTile(
                  value: confirmed,
                  onChanged: (v) => setModal(() => confirmed = v ?? false),
                  title: const Text('Saya menyatakan bahwa data izin ini adalah benar dan tidak dipalsu.',
                      style: TextStyle(fontSize: 13)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Upload foto jika ada
                      if (pickedPhoto != null) {
                        final uploadRes = await ApiClient.uploadFile(pickedPhoto!);
                        if (uploadRes.success) {
                          uploadedPhotoUrl = uploadRes.data?['url'] as String?;
                        }
                      }
                      // Prepare dates for backend (YYYY-MM-DD)
                      List<String> datesToSend = [];
                      if (calendarType == CalendarDatePicker2Type.multi) {
                        datesToSend = selectedDates
                            .where((d) => d != null)
                            .map((d) => DateFormat('yyyy-MM-dd').format(d!))
                            .toList();
                      } else if (calendarType == CalendarDatePicker2Type.range && selectedDates.length >= 2 && selectedDates[0] != null && selectedDates[1] != null) {
                        // Generate all dates in range
                        DateTime start = selectedDates[0]!;
                        DateTime end = selectedDates[1]!;
                        for (int i = 0; i <= end.difference(start).inDays; i++) {
                          datesToSend.add(DateFormat('yyyy-MM-dd').format(start.add(Duration(days: i))));
                        }
                      } else if (selectedDates.isNotEmpty && selectedDates[0] != null) {
                        datesToSend = [DateFormat('yyyy-MM-dd').format(selectedDates[0]!)];
                      }

                      if (datesToSend.isEmpty) {
                        AppDialog.showError(context, 'Pilih minimal satu tanggal');
                        return;
                      }

                      final body = {
                        'type': selectedType,
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'photo_url': uploadedPhotoUrl ?? '',
                        'confirmed_honest': confirmed,
                        'dates': datesToSend,
                      };
                      try {
                        final res = isEdit
                            ? await ApiClient.put('/api/employee/leaves/${existing!['id']}', body)
                            : await ApiClient.post('/api/employee/leaves', body);
                        if (!mounted) return;
                        if (!mounted) return;
                        if (res.success) {
                          AppDialog.showSuccess(context, isEdit ? 'Izin diperbarui' : 'Izin berhasil diajukan!');
                          _load();
                        } else {
                          AppDialog.showError(context, res.message ?? 'Gagal memproses izin');
                        }
                      } catch (_) {}
                    },
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Ajukan Izin'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLeave(String id, {bool isPending = false}) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: isPending ? 'Batalkan Pengajuan' : 'Hapus Riwayat Izin',
      message: isPending 
        ? 'Apakah Anda yakin ingin membatalkan pengajuan izin ini?' 
        : 'Apakah Anda yakin ingin menghapus izin ini dari riwayat?',
      confirmText: isPending ? 'Ya, Batalkan' : 'Ya, Hapus',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;
    try {
      final res = await ApiClient.delete('/api/employee/leaves/$id');
      if (!mounted) return;
      if (res.success) {
        AppDialog.showSuccess(context, isPending ? 'Pengajuan berhasil dibatalkan' : 'Dihapus dari riwayat kamu');
        _load();
      } else {
        AppDialog.showError(context, res.message ?? (isPending ? 'Gagal membatalkan' : 'Gagal menghapus riwayat'));
      }
    } catch (_) {}
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Hapus Terpilih',
      message: 'Hapus ${_selectedIds.length} izin terpilih dari riwayat?',
      confirmText: 'Hapus',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final res = await ApiClient.post('/api/employee/leaves/bulk-delete', {'ids': _selectedIds.toList()});
      if (res.success) {
        AppDialog.showSuccess(context, 'Berhasil menghapus ${_selectedIds.length} izin');
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
        _load();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal menghapus');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showDetailView(Map<String, dynamic> l) {
    final status = l['status'] ?? 'PENDING';
    final color = _statusColors[status] ?? Colors.grey;
    final createdAt = l['created_at'] != null ? DateTime.parse(l['created_at']) : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(l['type'] == 'SAKIT' ? Icons.sick_rounded : Icons.description_rounded, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                      Text(l['type'] ?? '-', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusLabels[status] ?? status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Informasi Tanggal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tanggal Diajukan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          _formatDates(l['dates'] ?? ''),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            const Text('Keterangan / Alasan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 8),
            Text(l['description'] ?? 'Tidak ada keterangan', style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF1E293B))),
            if (l['photo_url'] != null && (l['photo_url'] as String).isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Foto Bukti', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  AppConstants.baseUrl + l['photo_url'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ],
            if (l['admin_note'] != null && (l['admin_note'] as String).isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.rate_review_rounded, size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 8),
                        Text('Catatan Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(l['admin_note'], style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                if (status == 'PENDING')
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showForm(existing: l);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF2563EB)),
                      label: const Text('Edit Pengajuan', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (status == 'PENDING') const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteLeave(l['id'], isPending: status == 'PENDING');
                    },
                    icon: Icon(status == 'PENDING' ? Icons.cancel_outlined : Icons.delete_outline_rounded, size: 20),
                    label: Text(status == 'PENDING' ? 'Batalkan Pengajuan' : 'Hapus Riwayat', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton.extended(
                onPressed: _bulkDelete,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Hapus Terpilih', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            : FloatingActionButton.extended(
                onPressed: () => _showForm(),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 4,
                highlightElevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajukan Izin', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
        body: Column(
          children: [
            // Premium Header
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pengajuan Izin',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (_isSelectionMode)
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          }),
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          label: const Text('Batal', style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isSelectionMode ? '${_selectedIds.length} dipilih' : 'Kelola ketidakhadiran Anda di sini',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75)),
                  ),
                  if (!_isSelectionMode) ...[
                    const SizedBox(height: 16),
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
                                  for (int i = 0; i < _months.length; i++)
                                    DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        _months[i],
                                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedMonth = v);
                                  _load();
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
                                  for (int y = DateTime.now().year - 2; y <= DateTime.now().year; y++)
                                    DropdownMenuItem(
                                      value: y,
                                      child: Text(
                                        y.toString(),
                                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedYear = v);
                                  _load();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
  
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _leaves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                child: Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey.shade300),
                              ),
                              const SizedBox(height: 16),
                              Text('Belum ada pengajuan izin', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                            itemCount: _leaves.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final l = _leaves[i] as Map<String, dynamic>;
                              final id = l['id'].toString();
                              final status = l['status'] ?? '';
                              final color = _statusColors[status] ?? Colors.grey;
                              final isPending = status == 'PENDING';
                              final isSelected = _selectedIds.contains(id);

                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _isSelectionMode && !isSelected ? 0.6 : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelected ? Border.all(color: const Color(0xFF2563EB), width: 2) : null,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onLongPress: () {
                                        setState(() {
                                          _isSelectionMode = true;
                                          _selectedIds.add(id);
                                        });
                                      },
                                      onTap: () {
                                        if (_isSelectionMode) {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedIds.remove(id);
                                              if (_selectedIds.isEmpty) _isSelectionMode = false;
                                            } else {
                                              _selectedIds.add(id);
                                            }
                                          });
                                        } else {
                                          _showDetailView(l);
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            if (_isSelectionMode) ...[
                                              Icon(
                                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                                color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
                                              ),
                                              const SizedBox(width: 12),
                                            ],
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                l['type'] == 'SAKIT' ? Icons.sick_rounded : Icons.event_note_rounded,
                                                color: color,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(l['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    l['type'] ?? '',
                                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    _statusLabels[status] ?? status,
                                                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                                                  ),
                                                ),
                                                if (!_isSelectionMode) ...[
                                                  const SizedBox(height: 8),
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey, size: 20),
                                                    onSelected: (v) {
                                                      if (v == 'edit') _showForm(existing: l);
                                                      if (v == 'delete') _deleteLeave(id);
                                                      if (v == 'detail') _showDetailView(l);
                                                    },
                                                    itemBuilder: (_) => [
                                                      const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.visibility_rounded, size: 16), SizedBox(width: 8), Text('Detail')])),
                                                      if (isPending)
                                                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit')])),
                                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({required String label, required IconData icon, required bool active, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? const Color(0xFF2563EB) : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? const Color(0xFF2563EB) : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDates(String datesJson) {
    if (datesJson.isEmpty) return '-';
    try {
      final List<dynamic> dates = jsonDecode(datesJson);
      if (dates.isEmpty) return '-';
      if (dates.length == 1) return DateFormat('dd MMMM yyyy').format(DateTime.parse(dates[0]));
      
      // Sort dates
      final sorted = dates.map((d) => DateTime.parse(d)).toList()..sort();
      final first = sorted.first;
      final last = sorted.last;
      
      // Jika berurutan semua (rentang)
      bool isContiguous = true;
      for (int i = 0; i < sorted.length - 1; i++) {
        if (sorted[i+1].difference(sorted[i]).inDays != 1) {
          isContiguous = false;
          break;
        }
      }
      
        return isContiguous
            ? '${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(first)} - \n${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(last)}\n(${dates.length} Hari)'
            : sorted.map((d) => DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(d)).join('\n');
    } catch (_) {
      return '-';
    }
  }
}
