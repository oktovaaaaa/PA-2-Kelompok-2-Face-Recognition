import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../common/widgets/app_dialog.dart';
import 'package:intl/intl.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/sessions');
      if (res.success) {
        setState(() => _sessions = res.data ?? []);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Keluarkan Perangkat',
      message: 'Apakah Anda yakin ingin mengeluarkan perangkat ini? Pengguna harus login kembali.',
      confirmText: 'Ya, Keluarkan',
      confirmColor: Colors.red,
    );

    if (confirmed != true) return;

    try {
      final res = await ApiClient.delete('/api/sessions/$sessionId');
      if (res.success) {
        if (mounted) AppDialog.showSuccess(context, 'Perangkat berhasil dikeluarkan');
        _loadSessions();
      } else {
        if (mounted) AppDialog.showError(context, res.message ?? 'Gagal mengeluarkan perangkat');
      }
    } catch (e) {
      if (mounted) AppDialog.showError(context, 'Terjadi kesalahan: $e');
    }
  }

  IconData _getDeviceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('windows') || lower.contains('mac') || lower.contains('linux') || 
        lower.contains('chrome') || lower.contains('safari') || lower.contains('firefox')) {
      return Icons.computer_rounded;
    }
    return Icons.smartphone_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manajemen Perangkat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : RefreshIndicator(
              onRefresh: _loadSessions,
              color: const Color(0xFF2563EB),
              child: _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.devices_other_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Tidak ada sesi aktif', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final deviceId = session['DeviceID'] ?? 'Unknown ID';
                        final deviceName = session['DeviceName'] ?? '';
                        final displayName = deviceName.isNotEmpty ? deviceName : deviceId;

                        final lastActive = session['LastActiveAt'] != null 
                            ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(session['LastActiveAt']))
                            : '-';
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_getDeviceIcon(displayName), color: const Color(0xFF2563EB), size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Terakhir aktif: $lastActive',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteSession(session['ID']),
                                icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
                                tooltip: 'Keluarkan',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
