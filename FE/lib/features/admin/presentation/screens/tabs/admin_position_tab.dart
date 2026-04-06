// lib/features/admin/presentation/screens/tabs/admin_position_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../common/widgets/app_dialog.dart';

class AdminPositionTab extends StatefulWidget {
  const AdminPositionTab({super.key});

  @override
  State<AdminPositionTab> createState() => _AdminPositionTabState();
}

class _AdminPositionTabState extends State<AdminPositionTab> {
  List<dynamic> _positions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/admin/positions');
      if (res.success && mounted) setState(() => _positions = res.data ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final salaryCtrl = TextEditingController(
        text: existing?['salary'] != null ? CurrencyInputFormatter.formatNumber((existing!['salary'] as num).toInt()) : '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Jabatan' : 'Tambah Jabatan',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Jabatan',
                  hintText: 'contoh: Manager, Staff, Supervisor',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salaryCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Gaji Pokok (Rp)',
                  hintText: 'contoh: 5000000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Jabatan (Opsional)',
                  hintText: 'Tuliskan deskripsi pekerjaan...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D64F5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final body = {
                      'name': nameCtrl.text.trim(),
                      'salary': CurrencyInputFormatter.unformat(salaryCtrl.text.trim()).toDouble(),
                      'description': descCtrl.text.trim(),
                    };
                    try {
                      if (isEdit) {
                        await ApiClient.put('/api/admin/positions/${existing!['id']}', body);
                      } else {
                        await ApiClient.post('/api/admin/positions', body);
                      }
                      _loadPositions();
                      if (mounted) {
                        AppDialog.showSuccess(context, isEdit ? 'Jabatan diperbarui' : 'Jabatan ditambahkan');
                      }
                      } catch (e) {
                      if (mounted) {
                        AppDialog.showError(context, 'Gagal menyimpan perubahan jabatan');
                      }
                    }
                  },
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Jabatan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePosition(String id, String name) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Hapus Jabatan',
      message: 'Hapus jabatan "$name"? Jabatan yang masih digunakan karyawan tidak dapat dihapus.',
      confirmText: 'Ya, Hapus',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;
    try {
      final res = await ApiClient.delete('/api/admin/positions/$id');
      if (!mounted) return;
      if (res.success) {
        AppDialog.showSuccess(context, 'Jabatan dihapus');
        _loadPositions();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal menghapus jabatan');
      }
    } catch (_) {}
  }

  String _formatSalary(dynamic salary) {
    if (salary == null) return 'Rp 0';
    return 'Rp ${CurrencyInputFormatter.formatNumber((salary as num).toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Jabatan', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Manajemen Jabatan',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_positions.length} Jabatan',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Kelola struktur jabatan dan gaji pokok perusahaan',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : _positions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.work_off_rounded, size: 56, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(height: 16),
                            const Text('Belum Ada Jabatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 8),
                            Text('Tap tombol + untuk menambah jabatan baru', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF2563EB),
                        onRefresh: _loadPositions,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                          itemCount: _positions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final p = _positions[i] as Map<String, dynamic>;
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.work_rounded, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                          const SizedBox(height: 4),
                                          if (p['description'] != null && p['description'].toString().isNotEmpty) ...[
                                            Text(
                                              p['description'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _formatSalary(p['salary']),
                                              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 22),
                                          onPressed: () => _showForm(existing: p),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 22),
                                          onPressed: () => _deletePosition(p['id'], p['name']),
                                        ),
                                      ],
                                    ),
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
