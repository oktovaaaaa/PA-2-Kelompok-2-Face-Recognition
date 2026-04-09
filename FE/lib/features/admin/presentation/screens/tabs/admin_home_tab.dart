// lib/features/admin/presentation/screens/tabs/admin_home_tab.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';
import '../../../../../core/utils/error_mapper.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/providers/notification_provider.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../../../auth/presentation/screens/pending_employees_screen.dart';
import '../attendance_report_screen.dart';
import '../admin_payroll_screen.dart';
import '../admin_adjustment_screen.dart';
import 'admin_position_tab.dart';
import '../../../../common/widgets/app_dialog.dart';
import '../../../../common/presentation/screens/notification_screen.dart';
import 'package:provider/provider.dart';

class AdminHomeTab extends StatefulWidget {
  final Function(int)? onNavigate;
  const AdminHomeTab({super.key, this.onNavigate});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final _repo = AuthRepository();
  bool _loadingInvite = false;
  String _generatedToken = '';
  Timer? _inviteTimer;
  int _countdown = 0;
  final GlobalKey _qrKey = GlobalKey();
  String? _userName;
  final _statusLabels = {'PENDING': 'Menunggu', 'APPROVED': 'Disetujui', 'REJECTED': 'Ditolak'};
  Map<String, dynamic> _summary = {
    'present': 0,
    'absent': 0,
    'late': 0,
    'leave': 0,
    'sick': 0,
    'working': 0,
    'not_yet': 0,
    'early_leave': 0,
    'late_early_leave': 0,
    'total': 0
  };
  bool _loadingSummary = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadSummary();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _inviteTimer?.cancel();
    super.dispose();
  }

  void _startInviteTimer() {
    _inviteTimer?.cancel();
    _countdown = 30;
    _inviteTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown <= 1) {
            _countdown = 0;
            timer.cancel();
          } else {
            _countdown--;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      // Assuming this endpoint exists or we aggregate data
      final res = await ApiClient.get('/api/admin/dashboard/summary');
      if (res.success && mounted) {
        setState(() => _summary = res.data ?? _summary);
      }
    } catch (_) {
      // Fallback or silence
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _loadUserName() async {
    try {
      final resProf = await ApiClient.get('/api/profile');
      final name = await SessionStorage.getUserName();
      if (mounted) {
        setState(() {
          if (resProf.success) {
            final profile = resProf.data as Map<String, dynamic>?;
            _userName = profile?['name'] ?? name;
            _photoUrl = profile?['photo_url'];
          } else {
            _userName = name;
          }
        });
      }
    } catch (_) {
      final name = await SessionStorage.getUserName();
      if (mounted) setState(() => _userName = name);
    }
  }

  Future<void> _generateInvite() async {
    if (_countdown > 0) return;
    setState(() => _loadingInvite = true);
    try {
      final companyId = await SessionStorage.getCompanyId() ?? '';
      final data = await _repo.generateInvite(companyId);
      _generatedToken = (data['token'] ?? '').toString();
      _startInviteTimer();
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      AppDialog.showError(context, msg);
    } finally {
      if (mounted) setState(() => _loadingInvite = false);
    }
  }

  Future<void> _copyToken() async {
    await Clipboard.setData(ClipboardData(text: _generatedToken));
    if (!mounted) return;
    AppDialog.showSuccess(context, 'Token disalin ke clipboard!');
  }

  Future<void> _saveQrCode() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final result = await ImageGallerySaverPlus.saveImage(
        byteData.buffer.asUint8List(),
        quality: 100,
        name: "invite_qr_${DateTime.now().millisecondsSinceEpoch}",
      );
      if (!mounted) return;
      if (result['isSuccess'] == true) {
        AppDialog.showSuccess(context, 'QR disimpan ke galeri!');
      } else {
        AppDialog.showError(context, 'Gagal menyimpan QR.');
      }
    } catch (_) {
      if (!mounted) return;
      AppDialog.showError(context, 'Terjadi kesalahan saat menyimpan gambar.');
    }
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${_getShortName(_userName ?? 'Admin')} 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola perusahaan dengan mudah',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Consumer<NotificationProvider>(
                  builder: (context, notifProvider, child) {
                    final count = notifProvider.unreadCount;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationScreen()),
                            );
                          },
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                        ),
                        if (count > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                count > 9 ? '9+' : count.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                        ? NetworkImage('${AppConstants.baseUrl}$_photoUrl')
                        : null,
                    child: (_photoUrl == null || _photoUrl!.isEmpty)
                        ? Text(
                            _getInitials(_userName ?? 'Admin'),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_graph_rounded, color: Color(0xFF2563EB), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Statistik Langsung',
                                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateTime.now().toString().substring(0, 10),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ringkasan Kehadiran',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status kehadiran karyawan hari ini',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      if ((_summary['total'] ?? 0) == 0 && !_loadingSummary)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text('Belum ada data kehadiran hari ini', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontStyle: FontStyle.italic)),
                          ),
                        )
                      else if (_loadingSummary)
                        const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(color: Color(0xFF2563EB))))
                      else
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 25,
                                  sections: (_summary['total'] ?? 0) == 0 || (_summary['present'] == 0 && _summary['late'] == 0 && _summary['absent'] == 0 && (_summary['leave'] + _summary['sick']) == 0 && _summary['working'] == 0 && _summary['not_yet'] == 0)
                                    ? [
                                        PieChartSectionData(
                                          value: 1,
                                          color: Colors.grey.shade200,
                                          radius: 20,
                                          showTitle: true,
                                          title: 'LIBUR',
                                          titleStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                                        ),
                                      ]
                                    : [
                                      if ((_summary['present'] ?? 0) > 0) PieChartSectionData(value: (_summary['present'] as num).toDouble(), color: const Color(0xFF22C55E), radius: 20, showTitle: false),
                                      if ((_summary['late'] ?? 0) > 0) PieChartSectionData(value: (_summary['late'] as num).toDouble(), color: const Color(0xFFFBBF24), radius: 20, showTitle: false),
                                      if ((_summary['absent'] ?? 0) > 0) PieChartSectionData(value: (_summary['absent'] as num).toDouble(), color: const Color(0xFFEF4444), radius: 20, showTitle: false),
                                      if (((_summary['leave'] ?? 0) + (_summary['sick'] ?? 0)) > 0) PieChartSectionData(value: ((_summary['leave'] ?? 0) + (_summary['sick'] ?? 0) as num).toDouble(), color: const Color(0xFF3B82F6), radius: 20, showTitle: false),
                                      if ((_summary['not_yet'] ?? 0) > 0) PieChartSectionData(value: (_summary['not_yet'] as num).toDouble(), color: const Color(0xFF94A3B8), radius: 20, showTitle: false),
                                      if ((_summary['working'] ?? 0) > 0) PieChartSectionData(value: (_summary['working'] as num).toDouble(), color: const Color(0xFF818CF8), radius: 20, showTitle: false),
                                      if ((_summary['early_leave'] ?? 0) > 0) PieChartSectionData(value: (_summary['early_leave'] as num).toDouble(), color: const Color(0xFFF97316), radius: 20, showTitle: false),
                                      if ((_summary['late_early_leave'] ?? 0) > 0) PieChartSectionData(value: (_summary['late_early_leave'] as num).toDouble(), color: const Color(0xFFD946EF), radius: 20, showTitle: false),
                                    ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _summaryItem(const Color(0xFF22C55E), 'Hadir', _summary['present'] ?? 0),
                                  const SizedBox(height: 8),
                                  _summaryItem(const Color(0xFFFBBF24), 'Terlambat', _summary['late'] ?? 0),
                                  const SizedBox(height: 8),
                                  _summaryItem(const Color(0xFF818CF8), 'Sedang Bekerja', _summary['working'] ?? 0),
                                  const SizedBox(height: 8),
                                  _summaryItem(const Color(0xFF3B82F6), 'Izin/Sakit', (_summary['leave'] ?? 0) + (_summary['sick'] ?? 0)),
                                  const SizedBox(height: 8),
                                  _summaryItem(const Color(0xFF94A3B8), 'Belum Hadir', _summary['not_yet'] ?? 0),
                                  const SizedBox(height: 8),
                                  _summaryItem(const Color(0xFFEF4444), 'Alpha', _summary['absent'] ?? 0),
                                  const SizedBox(height: 8),
                                  _summaryItem(const Color(0xFFF97316), 'Pulang di jam kerja', _summary['early_leave'] ?? 0),
                                  const SizedBox(height: 8),
                                  _summaryItem(const Color(0xFFD946EF), 'Terlambat & Pulang di jam kerja', _summary['late_early_leave'] ?? 0),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Quick Actions (Memberikan kemudahan navigasi tab)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(
                      icon: Icons.assignment_turned_in_rounded,
                      label: 'Perizinan',
                      color: const Color(0xFFD97706),
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                    _buildQuickAction(
                      icon: Icons.people_rounded,
                      label: 'Karyawan',
                      color: const Color(0xFF2563EB),
                      onTap: () => widget.onNavigate?.call(3),
                    ),
                    _buildQuickAction(
                      icon: Icons.stars_rounded,
                      label: 'Bonus',
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminAdjustmentScreen()),
                      ),
                    ),
                    _buildQuickAction(
                      icon: Icons.work_rounded,
                      label: 'Jabatan',
                      color: const Color(0xFF0F172A),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminPositionTab()),
                      ),
                    ),
                    _buildQuickAction(
                      icon: Icons.settings_rounded,
                      label: 'Pengaturan',
                      color: const Color(0xFF64748B),
                      onTap: () => widget.onNavigate?.call(4),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                const Text(
                  'Manajemen & Laporan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Laporan Kehadiran',
                  subtitle: 'Lihat seluruh riwayat & ekspor Excel',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Manajemen Gaji',
                  subtitle: 'Proses gaji & denda bulanan',
                  onTap: () => widget.onNavigate?.call(2),
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.person_add_rounded,
                  color: const Color(0xFF2563EB),
                  title: 'Karyawan Pending',
                  subtitle: 'Approve atau reject pendaftaran baru',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PendingEmployeesScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.military_tech_rounded,
                  color: Colors.orange.shade700,
                  title: 'Bonus & Sanksi',
                  subtitle: 'Input bonus atau denda manual',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAdjustmentScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.qr_code_2_rounded,
                  color: const Color(0xFF0F172A),
                  title: 'Generate Undangan',
                  subtitle: _countdown > 0 ? 'Tersedia dalam ${_countdown}s' : 'Buat Token & QR Code rekrutmen',
                  onTap: (_loadingInvite || _countdown > 0) ? null : _generateInvite,
                  trailing: _loadingInvite
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                      : (_countdown > 0 ? Text('${_countdown}s', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)) : null),
                ),
                
                if (_generatedToken.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('QR Undangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          RepaintBoundary(
                            key: _qrKey,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100, width: 2),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Stack(
                                children: [
                                  QrImageView(data: _generatedToken, version: QrVersions.auto, size: 200.0),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.vpn_key_rounded, color: Color(0xFF64748B), size: 18),
                                const SizedBox(width: 12),
                                Expanded(child: Text(_generatedToken, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)))),
                                GestureDetector(
                                   onTap: _copyToken,
                                   child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.copy_rounded, color: Color(0xFF2563EB), size: 16),
                                   ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: (_loadingInvite || _countdown > 0) ? null : _generateInvite,
                                  icon: _loadingInvite 
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.refresh_rounded),
                                  label: Text(
                                    _countdown > 0 ? 'Tunggu (${_countdown}s)' : 'Segarkan Barcode',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey.shade100,
                                    disabledForegroundColor: Colors.grey.shade400,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    minimumSize: const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _saveQrCode,
                                  icon: const Icon(Icons.file_download_rounded),
                                  label: const Text('Simpan Ke Galeri', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    minimumSize: const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  String _getShortName(String name) {
    if (name.trim().isEmpty) return '';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length <= 2) return name;
    return '${words[0]} ${words[1]}';
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final pts = name.trim().split(RegExp(r'\s+'));
    if (pts.length >= 2) {
      return (pts[0][0] + pts[1][0]).toUpperCase();
    }
    return pts[0][0].toUpperCase();
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.lerp(color, Colors.white, 0.82),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(Color color, String label, dynamic count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(margin: const EdgeInsets.only(top: 4), width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), softWrap: true)),
        const SizedBox(width: 4),
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Color.lerp(color, Colors.white, 0.82),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
