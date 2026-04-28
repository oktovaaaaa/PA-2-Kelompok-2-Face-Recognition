import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/models/app_user.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
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
      _users = await _repo.getCompanyEmployees();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.map(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetDevice(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Perangkat'),
        content: Text(
          'Akun "${user.name.isEmpty ? user.email : user.name}" akan direset perangkatnya.\n\n'
          'Gunakan ini jika pengguna telah menginstal ulang aplikasi dan tidak bisa masuk karena perangkat berbeda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repo.resetDeviceBinding(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Perangkat "${user.name.isEmpty ? user.email : user.name}" berhasil direset. Pengguna dapat login kembali.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.map(e))),
      );
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
                      'Daftar Karyawan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_off_rounded, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Tidak ada karyawan aktif.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _users.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _users[index];
                              final name = item.name.isEmpty ? item.email : item.name;
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                                    child: Text(
                                      item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(item.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      if (item.phone.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(item.phone, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                      ],
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.smartphone_rounded, color: Colors.orange, size: 20),
                                    ),
                                    onPressed: () => _resetDevice(item),
                                    tooltip: 'Reset Perangkat',
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
