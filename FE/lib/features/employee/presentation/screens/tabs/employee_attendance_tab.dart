// lib/features/employee/presentation/screens/tabs/employee_attendance_tab.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/providers/notification_provider.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';
import '../../../../common/widgets/app_dialog.dart';
import '../../../../common/presentation/screens/notification_screen.dart';
import '../face_verification_screen.dart';
import 'dart:math' as math;

class EmployeeAttendanceTab extends StatefulWidget {
  final Function(int index) onNavigate;

  const EmployeeAttendanceTab({
    super.key,
    required this.onNavigate,
  });

  @override
  State<EmployeeAttendanceTab> createState() => _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState extends State<EmployeeAttendanceTab> {
  Map<String, dynamic>? _todayData;
  Map<String, dynamic>? _profileData;
  List<dynamic> _locations = [];
  bool _loading = true;
  bool _actionLoading = false;
  String _currentTime = '--:--:--';
  Timer? _timer;
  
  double? _distance;
  bool _isInRadius = false;
  String _locationStatus = 'Mencari...';
  Map<String, dynamic>? _nearestLoc;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _load();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    _initLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationStatus = 'GPS Mati');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationStatus = 'Izin Ditolak');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationStatus = 'Izin Permanen Ditolak');
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen(
      (Position position) => _calculateDistance(position),
      onError: (e) => setState(() => _locationStatus = 'Error Lokasi'),
    );
  }

  void _calculateDistance(Position position) {
    double? minDistance;
    bool foundInside = false;
    Map<String, dynamic>? closest;

    if (_locations.isNotEmpty) {
      for (var loc in _locations) {
        final lat = (loc['latitude'] as num?)?.toDouble();
        final lng = (loc['longitude'] as num?)?.toDouble();
        final rad = (loc['radius'] as num?)?.toDouble() ?? 100.0;

        if (lat != null && lng != null) {
          final d = Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
          if (minDistance == null || d < minDistance) {
            minDistance = d;
            closest = loc;
          }
          if (d <= rad) foundInside = true;
        }
      }
    }

    if (minDistance == null && _todayData?['settings'] != null) {
      final settings = _todayData!['settings'] as Map<String, dynamic>;
      final lat = (settings['latitude'] ?? settings['office_latitude'] ?? 0.0) as num;
      final lng = (settings['longitude'] ?? settings['office_longitude'] ?? 0.0) as num;
      final rad = (settings['radius'] ?? settings['attendance_radius'] ?? 100.0) as num;

      if (lat != 0.0 && lng != 0.0) {
        final d = Geolocator.distanceBetween(position.latitude, position.longitude, lat.toDouble(), lng.toDouble());
        minDistance = d;
        closest = {'name': 'Kantor Pusat', 'latitude': lat, 'longitude': lng, 'radius': rad};
        if (d <= rad.toDouble()) foundInside = true;
      }
    }

    if (mounted) {
      setState(() {
        _distance = minDistance;
        _isInRadius = foundInside;
        _nearestLoc = closest;
        if (minDistance != null) {
          if (minDistance! > 1000000) {
             _locationStatus = 'Koordinat 0,0';
          } else {
             _locationStatus = '${minDistance.toStringAsFixed(1)}m';
          }
        } else {
          _locationStatus = 'Lokasi Belum Diset';
        }
      });
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/api/employee/attendance/today'),
        ApiClient.get('/api/profile'),
        ApiClient.get('/api/employee/locations'),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].success) _todayData = results[0].data as Map<String, dynamic>?;
          if (results[1].success) _profileData = results[1].data as Map<String, dynamic>?;
          if (results[2].success) _locations = results[2].data as List<dynamic>? ?? [];
          _loading = false;
        });
        
        try {
          Position position = await Geolocator.getCurrentPosition();
          _calculateDistance(position);
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleAction(String action) async {
    if (_actionLoading) return;
    
    if (!_isInRadius && action != 'check_out') {
      AppDialog.showError(context, 'Anda berada di luar radius kantor (${_locationStatus})');
      return;
    }

    final faceB64 = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceVerificationScreen()));
    if (faceB64 == null) return;

    setState(() => _actionLoading = true);
    try {
      final endpoint = action == 'check_in' ? 'checkin' : 'checkout';
      final pos = await Geolocator.getCurrentPosition();
      
      final res = await ApiClient.post('/api/employee/attendance/$endpoint', {
        'face_image': faceB64,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });

      if (mounted) {
        if (res.success) {
          AppDialog.showSuccess(context, action == 'check_in' ? 'Check-in Berhasil' : 'Check-out Berhasil');
          _load();
        } else {
          AppDialog.showError(context, res.message ?? 'Gagal melakukan absensi');
        }
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _getShortName(String full) {
    if (full.isEmpty) return 'Karyawan';
    return full.split(' ')[0];
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final pts = name.trim().split(RegExp(r'\s+'));
    if (pts.length >= 2) {
      return (pts[0][0] + pts[1][0]).toUpperCase();
    }
    return pts[0][0].toUpperCase();
  }

  String formatImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConstants.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))));

    final att = _todayData?['attendance'] as Map<String, dynamic>?;
    final settings = _todayData?['settings'] as Map<String, dynamic>?;
    final rules = _todayData?['rules'] as Map<String, dynamic>?;
    
    final hasCheckedIn = att != null && att['check_in_time'] != null && att['check_in_time'].toString().isNotEmpty;
    final hasCheckedOut = att != null && att['check_out_time'] != null && att['check_out_time'].toString().isNotEmpty;
    final displayStatus = _todayData?['display_status'] ?? '';
    
    final isDoneForDay = hasCheckedIn && hasCheckedOut;
    final isHoliday = displayStatus == 'HOLIDAY';
    final isCheckInOpen = !isHoliday && displayStatus != 'NOT_STARTED' && displayStatus != 'EARLY_LEAVE';

    final checkInTime = hasCheckedIn ? att!['check_in_time'].toString().substring(11, 16) : '--:--';
    final checkOutTime = hasCheckedOut ? att!['check_out_time'].toString().substring(11, 16) : '--:--';
    final dendaToday = (att?['salary_deduction'] as num? ?? 0).toInt();

    final ciStart = settings?['check_in_start'] ?? '00:00';
    final ciEnd = settings?['check_in_end'] ?? '00:00';
    final coStart = settings?['check_out_start'] ?? '00:00';
    final coEnd = settings?['check_out_end'] ?? '00:00';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hi, ${_getShortName(_profileData?['name'] ?? 'Karyawan')}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(AppDateFormatter.formatFullDate(_todayData?['date'] ?? DateTime.now().toString()), style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                              ],
                            ),
                            Row(
                              children: [
                                Consumer<NotificationProvider>(
                                  builder: (context, notifProvider, child) {
                                    final count = notifProvider.unreadCount;
                                    return Stack(clipBehavior: Clip.none, children: [
                                      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())), icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28)),
                                      if (count > 0) Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
                                    ]);
                                  },
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => widget.onNavigate(4), 
                                  child: CircleAvatar(
                                    radius: 22, 
                                    backgroundColor: Colors.white24, 
                                    backgroundImage: (_profileData?['photo_url'] != null && _profileData!['photo_url'].toString().isNotEmpty) 
                                        ? NetworkImage(formatImageUrl(_profileData!['photo_url'])) 
                                        : null, 
                                    child: (_profileData?['photo_url'] == null || _profileData!['photo_url'].toString().isEmpty) 
                                        ? Text(
                                            _getInitials(_profileData?['name'] ?? ''),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          ) 
                                        : null
                                  )
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Status Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1E3A8A), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Image.asset('assets/images/videnti.png', width: 70, fit: BoxFit.contain),
                      ),
                      Positioned.fill(child: CustomPaint(painter: CircularPatternPainter())),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.work_outline, color: Colors.white, size: 20)),
                              const SizedBox(width: 12),
                              const Text('Status Hari Ini', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            () {
                              if (isHoliday) return 'Hari Libur';
                              if (isDoneForDay) return 'Sudah Pulang';
                              if (hasCheckedIn) return 'Sedang Bekerja';
                              return 'Belum Absen';
                            }(),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildCardDetail('Jam Masuk', checkInTime),
                              const SizedBox(width: 24),
                              _buildCardDetail('Jam Pulang', checkOutTime),
                              if (dendaToday > 0) ...[
                                const SizedBox(width: 24),
                                _buildCardDetail('Denda', 'Rp ${CurrencyInputFormatter.formatNumber(dendaToday)}', color: Colors.redAccent),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Jam Saat Ini', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(_currentTime, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Location Details Card
              if (_nearestLoc != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (_isInRadius ? Colors.green : Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.location_on_rounded, color: _isInRadius ? Colors.green : Colors.grey, size: 28)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_nearestLoc!['name'] ?? 'Lokasi Kantor', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 4),
                              Text('Jarak: ${_distance != null ? '${_distance!.toStringAsFixed(0)} m' : '-'}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _isInRadius ? Colors.green : Colors.red)),
                              const SizedBox(height: 2),
                              Text('Radius aman: ${(_nearestLoc!['radius'] ?? 100).toStringAsFixed(0)} m', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        if (_isInRadius) Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle), child: const Icon(Icons.check, color: Color(0xFF166534), size: 20)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(icon: Icons.login_rounded, label: 'Masuk', color: const Color(0xFF22C55E), disabled: !isCheckInOpen || hasCheckedIn, onTap: () => _handleAction('check_in')),
                    _buildQuickAction(icon: Icons.logout_rounded, label: 'Pulang', color: const Color(0xFFF59E0B), disabled: !hasCheckedIn || hasCheckedOut, onTap: () => _handleAction('check_out')),
                    _buildQuickAction(icon: Icons.assignment_outlined, label: 'Izin', color: const Color(0xFF3B82F6), disabled: isDoneForDay, onTap: () => widget.onNavigate(2)),
                    _buildQuickAction(icon: Icons.history_rounded, label: 'Riwayat', color: const Color(0xFF8B5CF6), disabled: false, onTap: () => widget.onNavigate(1)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Ketentuan Operasional Kantor
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ketentuan Operasional Kantor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
                      child: Column(
                        children: [
                          _buildModernRuleRow(
                            icon: Icons.login_outlined,
                            label: 'Jam Masuk',
                            value: '$ciStart - $ciEnd',
                            iconColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                          _buildModernRuleRow(
                            icon: Icons.logout_outlined,
                            label: 'Jam Pulang',
                            value: '$coStart - $coEnd',
                            iconColor: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFFFFFBEB),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ketentuan Denda Kantor
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ketentuan Denda Kantor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFEE2E2))),
                      child: Column(
                        children: [
                          _buildModernRuleRow(
                            icon: Icons.timer_outlined,
                            label: 'Terlambat Masuk',
                            value: 'Rp ${CurrencyInputFormatter.formatNumber((rules?['late_fine'] ?? rules?['late_penalty'] ?? 100000).toInt())}',
                            iconColor: const Color(0xFFDC2626),
                            bgColor: Colors.white,
                            isDenda: true,
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFFEE2E2))),
                          _buildModernRuleRow(
                            icon: Icons.person_off_outlined,
                            label: 'Alpha (Tanpa Keterangan)',
                            value: 'Rp ${CurrencyInputFormatter.formatNumber((rules?['absent_fine'] ?? rules?['alpha_penalty'] ?? 200000).toInt())}',
                            iconColor: const Color(0xFFDC2626),
                            bgColor: Colors.white,
                            isDenda: true,
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFFEE2E2))),
                          _buildModernRuleRow(
                            icon: Icons.running_with_errors_outlined,
                            label: 'Pulang Mendahului',
                            value: 'Rp ${CurrencyInputFormatter.formatNumber((rules?['early_leave_fine'] ?? rules?['early_leave_penalty'] ?? 50000).toInt())}',
                            iconColor: const Color(0xFFDC2626),
                            bgColor: Colors.white,
                            isDenda: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetail(String label, String value, {Color? color}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
    ]);
  }

  Widget _buildModernRuleRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color bgColor,
    bool isDenda = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDenda ? const Color(0xFF991B1B) : const Color(0xFF475569),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDenda ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDenda ? const Color(0xFFFEE2E2) : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDenda ? const Color(0xFFB91C1C) : const Color(0xFF1E293B),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required Color color, required bool disabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: disabled || _actionLoading ? null : onTap,
      child: Column(children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: disabled ? Colors.grey.shade100 : color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: disabled ? Colors.grey.shade200 : color.withOpacity(0.2), width: 1.5)), child: Icon(icon, color: disabled ? Colors.grey.shade400 : color, size: 28)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: disabled ? Colors.grey.shade400 : const Color(0xFF64748B))),
      ]),
    );
  }
}

class CircularPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), i * 40.0, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
