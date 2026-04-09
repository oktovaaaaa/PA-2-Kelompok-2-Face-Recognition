// lib/features/admin/presentation/screens/admin_adjustment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../common/widgets/app_dialog.dart';

class AdminAdjustmentScreen extends StatefulWidget {
  const AdminAdjustmentScreen({super.key});

  @override
  State<AdminAdjustmentScreen> createState() => _AdminAdjustmentScreenState();
}

class _AdminAdjustmentScreenState extends State<AdminAdjustmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data State
  List<dynamic> _employees = [];
  List<dynamic> _history = [];
  List<String> _years = [];
  bool _loading = false;
  bool _loadingEmployees = false;

  // Filters
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadHistory();
      }
    });
    _loadEmployees();
    _loadYears();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _loadingEmployees = true);
    try {
      final res = await ApiClient.get('/api/admin/employees?status=ACTIVE');
      if (res.success && mounted) {
        setState(() => _employees = res.data ?? []);
      }
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _loadYears() async {
    try {
      final type = _tabController.index == 0 ? 'bonuses' : 'penalties';
      final res = await ApiClient.get('/api/admin/$type/years');
      if (res.success && mounted) {
        setState(() => _years = List<String>.from(res.data ?? []));
        if (!_years.contains(_selectedYear.toString()) && _years.isNotEmpty) {
           // Don't override current year if possible, but stay safe
        }
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final type = _tabController.index == 0 ? 'bonuses' : 'penalties';
      // Adjusting endpoint: penalties uses 'filter=month' logic based on penalty_handler.go
      String url = '/api/admin/$type?month=$_selectedMonth&year=$_selectedYear&page=1&limit=50';
      if (type == 'penalties') {
        url += '&filter=month';
      }
      if (_searchQuery.isNotEmpty) url += '&search=$_searchQuery';

      final res = await ApiClient.get(url);
      if (res.success && mounted) {
        // Penalty API wraps data in an object {data: [], total: 0}
        if (type == 'penalties') {
          setState(() => _history = res.data['data'] ?? []);
        } else {
          setState(() => _history = res.data ?? []);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddDialog() async {
    if (_employees.isEmpty && !_loadingEmployees) {
      await _loadEmployees();
    }

    final isBonus = _tabController.index == 0;
    Map<String, dynamic>? selectedEmployee;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    // Specific for Penalty
    String penaltyType = 'Lainnya'; 

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
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
              Text(isBonus ? 'Tambah Bonus Baru' : 'Input Sanksi Manual', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              
              // Employee Picker
              const Text('Pilih Karyawan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showEmployeePicker(context, (emp) => setModalState(() => selectedEmployee = emp)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedEmployee?['name'] ?? 'Klik untuk memilih karyawan',
                          style: TextStyle(color: selectedEmployee == null ? Colors.grey : Colors.black, fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title / Reason
              Text(isBonus ? 'Nama Bonus' : 'Alasan Sanksi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: isBonus ? 'Contoh: Bonus Project A' : 'Contoh: Keterlambatan Rapat',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              const Text('Nominal (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
              const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(DateFormat('dd MMMM yyyy', 'id').format(selectedDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBonus ? const Color(0xFF2563EB) : Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _submit(
                    context,
                    isBonus: isBonus,
                    userID: selectedEmployee?['id'],
                    title: titleCtrl.text,
                    amount: CurrencyInputFormatter.unformat(amountCtrl.text).toDouble(),
                    date: DateFormat('yyyy-MM-dd').format(selectedDate),
                    type: penaltyType, // Only for penalties
                  ),
                  child: const Text('Simpan Data', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmployeePicker(BuildContext context, Function(Map<String, dynamic>) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Pilih Karyawan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _employees.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final emp = _employees[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (emp['photo_url'] != null && emp['photo_url'].isNotEmpty)
                        ? NetworkImage('${AppConstants.baseUrl}${emp['photo_url']}')
                        : null,
                    child: (emp['photo_url'] == null || emp['photo_url'].isEmpty) ? Text(emp['name'][0]) : null,
                  ),
                  title: Text(emp['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(emp['position_name'] ?? 'Staf'),
                  onTap: () {
                    onSelected(emp);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, {
    required bool isBonus,
    String? userID,
    required String title,
    required double amount,
    required String date,
    required String type,
  }) async {
    if (userID == null || title.isEmpty || amount <= 0) {
      AppDialog.showError(context, 'Harap lengkapi semua data');
      return;
    }

    AppDialog.showLoading(context);
    try {
      final endpoint = isBonus ? '/api/admin/bonuses' : '/api/admin/penalties';
      final res = await ApiClient.post(endpoint, {
        'user_id': userID,
        'title': title,
        'amount': amount,
        'date': date,
        if (!isBonus) 'type': type,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (res.success) {
        Navigator.pop(context); // Close modal
        AppDialog.showSuccess(context, 'Data berhasil disimpan');
        _loadHistory();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal menyimpan data');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      AppDialog.showError(context, 'Terjadi kesalahan sistem');
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Hapus Data',
      message: 'Apakah Anda yakin ingin menghapus catatan ini?',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;

    AppDialog.showLoading(context);
    try {
      final type = _tabController.index == 0 ? 'bonuses' : 'penalties';
      final res = await ApiClient.delete('/api/admin/$type/$id');
      
      if (!mounted) return;
      Navigator.pop(context);

      if (res.success) {
        AppDialog.showSuccess(context, 'Data berhasil dihapus');
        _loadHistory();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal menghapus data');
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _history.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: _tabController.index == 0 ? const Color(0xFF2563EB) : Colors.red.shade600,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(_tabController.index == 0 ? 'Tambah Bonus' : 'Tambah Sanksi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
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
              const Text('Bonus & Sanksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          // Sub Header Filters
          Row(
            children: [
               _filterChip(
                 label: '${_monthName(_selectedMonth)} $_selectedYear',
                 icon: Icons.calendar_today_rounded,
                 onTap: _showPeriodPicker,
               ),
            ],
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [Tab(text: 'Riwayat Bonus'), Tab(text: 'Riwayat Sanksi')],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) {
          final item = _history[i];
          final user = item['user'] ?? {};
          final isBonus = _tabController.index == 0;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: (isBonus ? Colors.green : Colors.red).withOpacity(0.1),
                      backgroundImage: (user['photo_url'] != null && user['photo_url'].isNotEmpty)
                          ? NetworkImage('${AppConstants.baseUrl}${user['photo_url']}')
                          : null,
                      child: (user['photo_url'] == null || user['photo_url'].isEmpty) ? Text(user['name']?[0] ?? '?', style: TextStyle(color: isBonus ? Colors.green : Colors.red)) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'] ?? 'Karyawan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(item['date'])), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _delete(item['id']),
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 20),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (item['description'] != null && item['description'].isNotEmpty)
                            Text(item['description'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      '${isBonus ? "+" : "-"} ${_formatCurrency(item['amount'])}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isBonus ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada riwayat ${_tabController.index == 0 ? "bonus" : "sanksi"}', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          Text('Klik tombol tambah untuk membuat data baru', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  void _showPeriodPicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: 300,
        child: Column(
          children: [
            const Text('Pilih Periode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedMonth,
                    items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(_monthName(i+1)))),
                    onChanged: (v) { setState(() => _selectedMonth = v!); Navigator.pop(ctx); _loadHistory(); },
                  ),
                ),
                const SizedBox(width: 16),
                 Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedYear,
                    items: List.generate(5, (i) => DropdownMenuItem(value: DateTime.now().year - i, child: Text('${DateTime.now().year - i}'))),
                    onChanged: (v) { setState(() => _selectedYear = v!); Navigator.pop(ctx); _loadHistory(); },
                  ),
                ),
              ],
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'][m-1];

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final val = (amount as num).toDouble();
    return 'Rp ${NumberFormat.decimalPattern('id').format(val)}';
  }
}
