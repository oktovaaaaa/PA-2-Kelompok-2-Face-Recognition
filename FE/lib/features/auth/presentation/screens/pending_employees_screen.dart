// lib/features/admin/presentation/screens/pending_employees_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/models/app_user.dart';
import '../../../common/widgets/app_dialog.dart';

class PendingEmployeesScreen extends StatefulWidget {
  const PendingEmployeesScreen({super.key});

  @override
  State<PendingEmployeesScreen> createState() => _PendingEmployeesScreenState();
}

class _PendingEmployeesScreenState extends State<PendingEmployeesScreen> {
  final _repo = AuthRepository();
  bool _loading = true;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _users = await _repo.getPendingEmployees();
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      AppDialog.showError(context, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(String userId) async {
    try {
      await _repo.approveEmployee(userId);
      if (!mounted) return;
      AppDialog.showSuccess(context, 'Karyawan berhasil disetujui');
      await _load();
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      AppDialog.showError(context, msg);
    }
  }

  Future<void> _reject(String userId) async {
    try {
      await _repo.rejectEmployee(userId);
      if (!mounted) return;
      AppDialog.showSuccess(context, 'Karyawan telah ditolak');
      await _load();
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      AppDialog.showError(context, msg);
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
              padding: const EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 20),
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
                  const Expanded(
                    child: Text(
                      'Persetujuan Karyawan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                  : _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_alt_rounded, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada antrian persetujuan',
                                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Semua pengajuan sudah diproses',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                    final item = _users[index];
                    final name = item.name.isEmpty ? item.email : item.name;
                    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.email,
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _reject(item.id),
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    label: const Text('Tolak'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFEF4444),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approve(item.id),
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: const Text('Setujui'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
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
          ],
        ),
      ),
    );
  }
}