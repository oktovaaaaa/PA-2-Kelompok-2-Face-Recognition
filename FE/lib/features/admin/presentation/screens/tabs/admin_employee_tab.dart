// lib/features/admin/presentation/screens/tabs/admin_employee_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../employee_stats_screen.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../common/widgets/app_dialog.dart';
import '../../../../../core/utils/error_mapper.dart';
import '../../../../../core/constants/app_constants.dart';

class AdminEmployeeTab extends StatefulWidget {
  const AdminEmployeeTab({super.key});

  @override
  State<AdminEmployeeTab> createState() => _AdminEmployeeTabState();
}

class _AdminEmployeeTabState extends State<AdminEmployeeTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _employees = [];
  List<dynamic> _positions = [];
  bool _loading = false;
  String _statusFilter = 'ACTIVE';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      _statusFilter = _tabController.index == 0 ? 'ACTIVE' : 'RESIGNED';
      _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final empRes = await ApiClient.get('/api/admin/employees?status=$_statusFilter');
      final posRes = await ApiClient.get('/api/admin/positions');
      if (mounted) {
        setState(() {
          _employees = empRes.data ?? [];
          _positions = posRes.data ?? [];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fireEmployee(Map<String, dynamic> emp) async {
    // STEP 1: Konfirmasi awal
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Pecat Karyawan',
      message: 'Apakah Anda yakin ingin memecat ${emp['name']}? Status karyawan akan menjadi RESIGNED dan tidak bisa login lagi.',
      confirmText: 'Ya, Lanjutkan',
      confirmColor: Colors.orange,
    );
    if (confirmed != true) return;

    // STEP 2: Ketik "SAYA YAKIN"
    final phraseCtrl = TextEditingController();
    bool loading = false;
    bool success = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                    SizedBox(width: 12),
                    Text('Konfirmasi Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.red)),
                  ]),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text('Tindakan ini tidak dapat diurungkan.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  children: [
                    const TextSpan(text: 'Ketik frasa formal di bawah ini untuk mengonfirmasi:\n\n'),
                    TextSpan(
                      text: 'SAYA YAKIN UNTUK MEMBERHENTIKAN KARYAWAN YANG BERNAMA ${emp['name'].toString().toUpperCase()}',
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red.shade900, fontSize: 14, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phraseCtrl,
                decoration: InputDecoration(
                  labelText: 'Ketik Frasa Konfirmasi',
                  prefixIcon: const Icon(Icons.text_fields_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: phraseCtrl.text.isNotEmpty && 
                            phraseCtrl.text.trim().toUpperCase() != 'SAYA YAKIN UNTUK MEMBERHENTIKAN KARYAWAN YANG BERNAMA ${emp['name'].toString().toUpperCase()}' 
                            ? 'Frasa tidak sesuai' : null,
                ),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: loading || phraseCtrl.text.trim().toUpperCase() != 'SAYA YAKIN UNTUK MEMBERHENTIKAN KARYAWAN YANG BERNAMA ${emp['name'].toString().toUpperCase()}' ? null : () async {
                    setModalState(() => loading = true);
                    try {
                      final res = await ApiClient.post('/api/admin/employees/fire', {
                        'user_id': emp['id'],
                        'reason': 'Pecat Karyawan dengan konfirmasi 2 lapis'
                      });
                      if (res.success) {
                        success = true;
                        if (mounted) {
                          Navigator.pop(context);
                          AppDialog.showSuccess(context, '${emp['name']} berhasil diberhentikan');
                          _loadData();
                        }
                      } else {
                        if (mounted) AppDialog.showError(context, res.message ?? 'Gagal memecat karyawan');
                      }
                    } catch (e) {
                      if (mounted) AppDialog.showError(context, 'Terjadi kesalahan: $e');
                    } finally {
                      if (mounted) setModalState(() => loading = false);
                    }
                  },
                  child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_remove_rounded),
                          SizedBox(width: 8),
                          Text('Konfirmasi Pecat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reactivateEmployee(Map<String, dynamic> emp) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Aktifkan Kembali',
      message: 'Aktifkan kembali ${emp['name']}? Karyawan akan bisa login kembali.',
      confirmText: 'Ya, Aktifkan',
      confirmColor: Colors.green,
    );
    if (confirmed != true) return;

    try {
      final res = await ApiClient.post('/api/admin/employees/reactivate', {'user_id': emp['id']});
      if (!mounted) return;
      if (res.success) {
        AppDialog.showSuccess(context, 'Karyawan berhasil diaktifkan');
        _loadData();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal mengaktifkan karyawan');
      }
    } catch (_) {}
  }

  Future<void> _resetDevice(Map<String, dynamic> emp) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Hapus Perangkat',
      message: 'Hapus perangkat pada akun ini? Karyawan bisa login di HP baru setelah ini.',
      confirmText: 'Ya, Hapus',
      confirmColor: Colors.orange,
    );
    if (confirmed != true) return;

    try {
      final res = await ApiClient.post('/api/admin/reset-device', {'user_id': emp['id']});
      if (!mounted) return;
      if (res.success) {
        AppDialog.showSuccess(context, 'Perangkat berhasil dihapus dari akun');
        _loadData();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal menghapus perangkat');
      }
    } catch (_) {}
  }

  void _showAssignPosition(Map<String, dynamic> emp) {
    String? selectedPositionId = emp['position_id'] ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.badge_rounded, color: Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Set Jabatan Karyawan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(emp['name'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Pilih salah satu jabatan di bawah ini:', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Opsi Kosongkan Jabatan
                    _buildPositionOption(
                      id: '',
                      name: 'Tidak ada jabatan',
                      salary: 0,
                      selectedId: selectedPositionId ?? '',
                      onTap: (id) => setModalState(() => selectedPositionId = id),
                    ),
                    const SizedBox(height: 8),
                    // Daftar Jabatan dari Data
                    ..._positions.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildPositionOption(
                        id: p['id'] as String,
                        name: p['name'] as String,
                        salary: p['salary'],
                        selectedId: selectedPositionId ?? '',
                        onTap: (id) => setModalState(() => selectedPositionId = id),
                      ),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final res = await ApiClient.post('/api/admin/positions/assign',
                          {'user_id': emp['id'], 'position_id': selectedPositionId ?? ''});
                      if (!mounted) return;
                      if (res.success) {
                        AppDialog.showSuccess(context, 'Jabatan berhasil diset untuk ${emp['name']}');
                        _loadData();
                      } else {
                        AppDialog.showError(context, res.message ?? 'Gagal menetapkan jabatan');
                      }
                    } catch (_) {}
                  },
                  child: const Text('Simpan Perubahan Jabatan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionOption({
    required String id,
    required String name,
    required dynamic salary,
    required String selectedId,
    required Function(String) onTap,
  }) {
    final isSelected = id == selectedId;
    return InkWell(
      onTap: () => onTap(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB).withOpacity(0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                id.isEmpty ? Icons.block_rounded : Icons.work_outline_rounded,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A))),
                  if (salary > 0)
                    Text(_formatSalary(salary), style: TextStyle(color: isSelected ? const Color(0xFF2563EB).withOpacity(0.7) : Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 24),
          ],
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> emp) {
    final isActive = emp['status'] == 'ACTIVE';
    final hasDevice = (emp['device_id'] ?? '').toString().isNotEmpty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.1), width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                backgroundImage: (emp['photo_url'] != null && emp['photo_url'].toString().isNotEmpty)
                    ? NetworkImage('${AppConstants.baseUrl}${emp['photo_url']}')
                    : null,
                child: (emp['photo_url'] == null || emp['photo_url'].toString().isEmpty)
                    ? Text(
                        _getInitials(emp['name'] ?? 'Karyawan'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(emp['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            Center(child: Text(emp['email'] ?? '', style: TextStyle(color: Colors.grey.shade600))),
            const SizedBox(height: 4),
            Center(
              child: Chip(
                label: Text((emp['status'] ?? '') == 'ACTIVE' ? 'Aktif' : 'Diberhentikan', style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: isActive ? Colors.green : Colors.red,
              ),
            ),
            const Divider(height: 24),
            _detailRow('Jabatan', emp['position_name'] ?? '-'),
            _detailRow('Gaji Pokok', _formatSalary(emp['salary'])),
            _detailRow('Telepon', emp['phone'] ?? '-'),
            _detailRow('Alamat', emp['address'] ?? '-'),
            _detailRow('Tgl Lahir', emp['birth_date'] ?? '-'),
            const Divider(height: 24),
            _actionButton(Icons.analytics_rounded, 'Lihat Statistik Kehadiran', Colors.deepPurple, () { 
              Navigator.pop(ctx); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeStatsScreen(userId: emp['id'], userName: emp['name'], photoUrl: emp['photo_url'])));
            }),
            const SizedBox(height: 12),
            if (isActive) ...[
              _actionButton(Icons.work_rounded, 'Set Jabatan', Colors.blue, () { Navigator.pop(ctx); _showAssignPosition(emp); }),
              const SizedBox(height: 8),
              _actionButton(Icons.phone_android_rounded, 'Hapus perangkat pada akun ini', Colors.orange, () { Navigator.pop(ctx); _resetDevice(emp); }),
              const SizedBox(height: 8),
              _actionButton(Icons.person_remove_rounded, 'Pecat Karyawan', Colors.red, () { Navigator.pop(ctx); _fireEmployee(emp); }),
            ] else ...[
              _actionButton(Icons.person_add_rounded, 'Aktifkan Kembali', Colors.green, () { Navigator.pop(ctx); _reactivateEmployee(emp); }),
            ],
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final pts = name.trim().split(RegExp(r'\s+'));
    if (pts.length >= 2) {
      return (pts[0][0] + pts[1][0]).toUpperCase();
    }
    return pts[0][0].toUpperCase();
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  String _formatSalary(dynamic salary) {
    if (salary == null) return '-';
    final val = (salary as num).toDouble();
    if (val == 0) return '-';
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Manajemen Karyawan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('${_employees.length} orang', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Kelola data dan status semua karyawan', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
              const SizedBox(height: 20),
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.white70, size: 20),
                    hintText: 'Cari nama karyawan...',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [Tab(text: 'Aktif'), Tab(text: 'Diberhentikan')],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : _employees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.08), shape: BoxShape.circle),
                            child: const Icon(Icons.people_outline_rounded, size: 56, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(height: 16),
                          const Text('Tidak ada karyawan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 8),
                          Text('Undang karyawan melalui QR Code', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF2563EB),
                      onRefresh: _loadData,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        itemCount: _employees.where((e) {
                          final name = (e['name'] ?? '').toString().toLowerCase();
                          final email = (e['email'] ?? '').toString().toLowerCase();
                          final q = _searchQuery.toLowerCase();
                          return name.contains(q) || email.contains(q);
                        }).length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final filteredList = _employees.where((e) {
                            final name = (e['name'] ?? '').toString().toLowerCase();
                            final email = (e['email'] ?? '').toString().toLowerCase();
                            final q = _searchQuery.toLowerCase();
                            return name.contains(q) || email.contains(q);
                          }).toList();
                          final e = filteredList[i] as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () => _showDetail(e),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      image: (e['photo_url'] != null && e['photo_url'].toString().isNotEmpty)
                                          ? DecorationImage(
                                              image: NetworkImage('${AppConstants.baseUrl}${e['photo_url']}'),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: (e['photo_url'] == null || e['photo_url'].toString().isEmpty)
                                        ? Center(
                                            child: Text(
                                              _getInitials(e['name'] ?? 'Karyawan'),
                                              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                        const SizedBox(height: 4),
                                        Text(e['email'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                        if (e['position_name'] != null && (e['position_name'] as String).isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                            child: Text(e['position_name'], style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB)),
                                ],
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
}
