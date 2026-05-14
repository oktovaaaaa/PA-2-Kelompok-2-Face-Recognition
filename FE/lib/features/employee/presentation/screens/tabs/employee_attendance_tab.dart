import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';
import '../face_verification_screen.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/providers/notification_provider.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../common/presentation/screens/notification_screen.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/app_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class EmployeeAttendanceTab extends StatefulWidget {
  final Function(int)? onNavigate;
  const EmployeeAttendanceTab({super.key, this.onNavigate});

  @override
  State<EmployeeAttendanceTab> createState() => _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState extends State<EmployeeAttendanceTab> {
  Map<String, dynamic>? _todayData;
  Map<String, dynamic>? _profileData;
  bool _loading = false;
  bool _actionLoading = false;
  String? _userName;
  bool _isSalaryVisible = false;

  // Geofencing State
  List<dynamic> _locations = [];
  Position? _currentPosition;
  double? _distanceToNearest;
  Map<String, dynamic>? _nearestLocation;
  StreamSubscription<Position>? _positionStream;
  bool _locationError = false;
  String _locationErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationError = true;
        _locationErrorMessage = 'GPS tidak aktif';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = true;
          _locationErrorMessage = 'Izin lokasi ditolak';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError = true;
        _locationErrorMessage = 'Izin lokasi ditolak permanen';
      });
      return;
    }

    // Start listening to location changes
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best, // Gunakan accuracy terbaik untuk presisi radius
        distanceFilter: 5, // Update tiap pergerakan kecil untuk kelancaran UI
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationError = false; // Temukan sinyal -> Hapus status error
          _locationErrorMessage = '';
          _calculateNearestLocation();
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _locationError = true;
          _locationErrorMessage = 'Gagal memperbarui lokasi. Mohon cari tempat terbuka.';
        });
      }
    });

    try {
      // Masukkan ke pencarian awal tapi jangan tunjukkan error jika timeout
      // karena positionStream di atas akan tetap bekerja di latar belakang
      setState(() {
        _locationError = false;
        _locationErrorMessage = 'Sedang mencari sinyal GPS...';
      });

      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _currentPosition = lastPos;
          _calculateNearestLocation();
        });
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        // Jika timeout, jangan anggap error fatal, biarkan stream di atas yang bekerja
        return lastPos ?? Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
      });
      
      if (mounted && pos.latitude != 0) {
        setState(() {
          _currentPosition = pos;
          _locationError = false;
          _locationErrorMessage = '';
          _calculateNearestLocation();
        });
      }
    } catch (e) {
      debugPrint('GPS Detection Error: $e');
      if (mounted) {
        setState(() {
          _locationError = true;
          _locationErrorMessage = 'Sinyal GPS sedang lemah. Mencoba kembali...';
        });
      }
    }
  }

  void _retryLocation() {
    _positionStream?.cancel();
    setState(() {
      _currentPosition = null;
      _locationError = false;
      _locationErrorMessage = '';
    });
    _initLocation();
  }

  void _calculateNearestLocation() {
    if (_currentPosition == null || _locations.isEmpty) return;

    double minDistance = -1;
    Map<String, dynamic>? nearest;

    for (var loc in _locations) {
      final double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );

      if (minDistance == -1 || distance < minDistance) {
        minDistance = distance;
        nearest = loc;
      }
    }

    setState(() {
      _distanceToNearest = minDistance;
      _nearestLocation = nearest;
      _locationError = false;
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resAtt = await ApiClient.get('/api/employee/attendance/today');
      final resProf = await ApiClient.get('/api/profile');
      final resLocs = await ApiClient.get('/api/employee/locations');
      final name = await SessionStorage.getUserName();
      
      if (mounted) {
        setState(() {
          _todayData = resAtt.data as Map<String, dynamic>?;
          if (resLocs.success) {
            _locations = resLocs.data as List<dynamic>;
            _calculateNearestLocation();
          }
          if (resProf.success) {
             _profileData = resProf.data as Map<String, dynamic>?;
             _userName = _profileData?['name'] ?? name;
          } else {
             _userName = name;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doAction(String action) async {
    if (_locationError || _currentPosition == null) {
      AppDialog.showError(context, _locationErrorMessage.isNotEmpty ? _locationErrorMessage : 'Mencari lokasi GPS...');
      return;
    }

    final bool isFaceRegistered = _profileData?['face_embedding_registered'] ?? false;
    if (!isFaceRegistered) {
      HapticFeedback.vibrate();
      AppDialog.showError(
        context, 
        'Wajah Tidak Terdeteksi di Sistem.\n\nAnda belum mendaftarkan Face ID. Silakan daftar di tab Profil terlebih dahulu untuk menggunakan fitur absensi.',
      );
      return;
    }

    // [NEW] Buka Layar Verifikasi Wajah
    final String? faceImageB64 = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceVerificationScreen()),
    );

    if (faceImageB64 == null) {
      // User membatalkan verifikasi
      return;
    }

    setState(() => _actionLoading = true);
    try {
      final res = await ApiClient.post('/api/employee/attendance/$action', {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'face_image': faceImageB64,
      });
      if (!mounted) return;
      if (res.success) {
        AppDialog.showSuccess(context, action == 'checkin' ? 'Absen Masuk berhasil!' : 'Absen Keluar berhasil!');
        _load();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal melakukan absensi');
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _formatRp(dynamic amount) {
    if (amount == null) return 'Rp 0';
    return 'Rp ${CurrencyInputFormatter.formatNumber((amount as num).toInt())}';
  }

  String _getShortName(String name) {
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

  @override
  Widget build(BuildContext context) {
    if (_loading && _todayData == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    final att = _todayData?['attendance'] as Map<String, dynamic>?;
    final settings = _todayData?['settings'] as Map<String, dynamic>?;
    final hasCheckedIn = att != null && att['check_in_time'] != null && att['check_in_time'].toString().isNotEmpty;
    final hasCheckedOut = att != null && att['check_out_time'] != null && att['check_out_time'].toString().isNotEmpty;
    final nowTimeStr = _todayData?['current_time'] ?? '--:--:--';
    final displayStatus = _todayData?['display_status'] ?? '';
    
    final baseSalary = (_profileData?['salary'] as num?)?.toDouble() ?? 0.0;
    final totalDeductionMonth = (_todayData?['total_deduction_month'] as num?)?.toDouble() ?? 0.0;
    final totalBonusMonth = (_todayData?['total_bonus_month'] as num?)?.toDouble() ?? 0.0;
    final estimatedSalary = (_todayData?['estimated_total_salary'] as num?)?.toDouble() ?? (baseSalary + totalBonusMonth - totalDeductionMonth);

    final position = (_profileData?['position_name'] ?? 'Karyawan').toString();
    final isDoneForDay = hasCheckedIn && hasCheckedOut;
    final isHoliday = displayStatus == 'HOLIDAY';

    bool isCheckInOpen() => !isHoliday && displayStatus != 'NOT_STARTED' && displayStatus != 'EARLY_LEAVE';

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
                          'Hi, ${_getShortName(_userName ?? 'Karyawan')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDateFormatter.formatFullDate(_todayData?['date'] ?? '-'),
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
                      backgroundImage: (_profileData?['photo_url'] != null && _profileData!['photo_url'].toString().isNotEmpty)
                          ? NetworkImage('${AppConstants.baseUrl}${_profileData!['photo_url']}')
                          : null,
                      child: (_profileData?['photo_url'] == null || _profileData!['photo_url'].toString().isEmpty)
                          ? Text(
                              _getInitials(_userName ?? 'Karyawan'),
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
              child: RefreshIndicator(
                color: const Color(0xFF2563EB),
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  children: [
                    // Wallet Card Premium
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Estimasi Gaji Pokok',
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isSalaryVisible = !_isSalaryVisible;
                                      });
                                    },
                                    child: Icon(
                                      _isSalaryVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.work_rounded, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      position,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSalaryVisible ? _formatRp(estimatedSalary.toInt()) : 'Rp •••••••',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status Hari Ini',
                                    style: TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    () {
                                      if (isHoliday) return 'HARI LIBUR';
                                      if (isDoneForDay) return 'HADIR TEPAT WAKTU';
                                      if (displayStatus == 'LATE') return 'TERLAMBAT';
                                      if (displayStatus == 'ABSENT') return 'ALPHA';
                                      if (displayStatus == 'NOT_STARTED') return 'BELUM MULAI';
                                      if (displayStatus == 'EARLY_LEAVE') return 'PULANG DI JAM KERJA';
                                      if (hasCheckedIn && !hasCheckedOut) return 'SEDANG BEKERJA';
                                      return 'BELUM HADIR';
                                    }().toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ],
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Blur/Shadow Effect
                                  Transform.translate(
                                    offset: const Offset(2, 2),
                                    child: Opacity(
                                      opacity: 0.2,
                                      child: Image.asset(
                                        'assets/images/videnti.png',
                                        width: 72,
                                        height: 72,
                                        color: Colors.black,
                                        colorBlendMode: BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  // Main Logo
                                  Opacity(
                                    opacity: 0.6,
                                    child: Image.asset(
                                      'assets/images/videnti.png',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Geofencing Status Card
                    if (_locations.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: (_distanceToNearest != null && _nearestLocation != null && _distanceToNearest! <= (_nearestLocation!['radius'] as num).toDouble())
                                ? Colors.green.shade200
                                : Colors.red.shade100,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_distanceToNearest != null && _nearestLocation != null && _distanceToNearest! <= (_nearestLocation!['radius'] as num).toDouble())
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                (_distanceToNearest != null && _nearestLocation != null && _distanceToNearest! <= (_nearestLocation!['radius'] as num).toDouble())
                                    ? Icons.location_on_rounded
                                    : Icons.location_off_rounded,
                                color: (_distanceToNearest != null && _nearestLocation != null && _distanceToNearest! <= (_nearestLocation!['radius'] as num).toDouble())
                                    ? Colors.green.shade700
                                    : Colors.red.shade600,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nearestLocation != null ? _nearestLocation!['name'] : 'Mencari Titik Lokasi...',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_locationError)
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red.shade400),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _locationErrorMessage,
                                            style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      _distanceToNearest != null 
                                          ? (_distanceToNearest! >= 1000 
                                              ? 'Jarak: ${(_distanceToNearest! / 1000).toStringAsFixed(2)} km' 
                                              : 'Jarak: ${_distanceToNearest!.toStringAsFixed(0)} m')
                                          : 'Menghitung jarak...',
                                      style: TextStyle(
                                        fontSize: 13, 
                                        fontWeight: FontWeight.w600,
                                        color: (_distanceToNearest != null && _nearestLocation != null && _distanceToNearest! <= (_nearestLocation!['radius'] as num).toDouble())
                                            ? Colors.green.shade700
                                            : Colors.red.shade600,
                                      ),
                                    ),
                                  if (!_locationError && _distanceToNearest != null && _nearestLocation != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Radius aman: ${_nearestLocation?['radius']}m',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_locationError || _currentPosition == null)
                              IconButton(
                                onPressed: _retryLocation,
                                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
                                tooltip: 'Segarkan Lokasi',
                              ),
                            if (!_locationError && _distanceToNearest != null && _nearestLocation != null && _distanceToNearest! > (_nearestLocation!['radius'] as num).toDouble())
                               Icon(Icons.info_outline_rounded, color: Colors.red.shade400, size: 20),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),
  
                    // Action Buttons Grid-Style
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickAction(
                          icon: Icons.login_rounded,
                          label: 'Masuk',
                          color: const Color(0xFF2E7D32),
                          disabled: hasCheckedIn || !isCheckInOpen() || (_distanceToNearest == null || _nearestLocation == null || _distanceToNearest! > (_nearestLocation!['radius'] as num).toDouble()),
                          onTap: () async {
                            final confirmed = await AppDialog.showConfirm(
                              context,
                              title: 'Konfirmasi Masuk',
                              message: 'Apakah Anda yakin ingin melakukan absensi masuk sekarang?',
                              confirmColor: const Color(0xFF2E7D32),
                            );
                            if (confirmed == true) {
                              _doAction('checkin');
                            }
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.logout_rounded,
                          label: 'Pulang',
                          color: const Color(0xFF1E3A8A),
                          disabled: !hasCheckedIn || hasCheckedOut || (_distanceToNearest == null || _nearestLocation == null || _distanceToNearest! > (_nearestLocation!['radius'] as num).toDouble()),
                          onTap: () async {
                            final confirmed = await AppDialog.showConfirm(
                              context,
                              title: 'Konfirmasi Pulang',
                              message: 'Apakah Anda yakin ingin melakukan absensi pulang sekarang?',
                              confirmColor: const Color(0xFF1E3A8A),
                            );
                            if (confirmed == true) {
                              _doAction('checkout');
                            }
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.assignment_late_rounded,
                          label: 'Izin',
                          color: const Color(0xFFD97706),
                          disabled: false,
                          onTap: () {
                            if (widget.onNavigate != null) {
                              widget.onNavigate!(2); // Tab Izin adalah index 2
                            }
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.history_rounded,
                          label: 'Riwayat',
                          color: const Color(0xFF64748B),
                          disabled: false,
                          onTap: () {
                            if (widget.onNavigate != null) {
                              widget.onNavigate!(1); // Tab Riwayat adalah index 1
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
  
                    // Status Kehadiran Detail 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Log Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(nowTimeStr, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
  
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildStatusRow(
                            icon: Icons.login_rounded,
                            title: 'Masuk Kantor',
                            time: att?['check_in_time']?.toString().substring(11, 16) ?? '--:--',
                            status: () {
                              if (hasCheckedIn) return displayStatus == 'LATE' ? 'Terlambat' : 'Hadir';
                              if (displayStatus == 'NOT_STARTED') return 'Belum Mulai';
                              if (displayStatus == 'ABSENT') return 'Alpha';
                              return 'Siap';
                            }(),
                            color: hasCheckedIn 
                                ? (displayStatus == 'LATE' ? Colors.orange : const Color(0xFF2E7D32)) 
                                : (displayStatus == 'ABSENT' ? Colors.red : Colors.grey.shade400),
                            isFirst: true,
                          ),
                          Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                          _buildStatusRow(
                            icon: Icons.logout_rounded,
                            title: 'Pulang Kantor',
                            time: att?['check_out_time']?.toString().substring(11, 16) ?? '--:--',
                            status: () {
                              if (hasCheckedOut) return 'Selesai';
                              if (displayStatus == 'EARLY_LEAVE') return 'Tanpa Absen';
                              return hasCheckedIn ? 'Siap' : 'Tunggu';
                            }(),
                            color: hasCheckedOut 
                                ? const Color(0xFF1E3A8A) 
                                : (displayStatus == 'EARLY_LEAVE' ? Colors.red : Colors.grey.shade400),
                            isFirst: false,
                          ),
                        ],
                      ),
                    ),
                    
                    // -- Improved Rules & Holiday Card --
                    if (isHoliday) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.indigo.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.event_available_rounded, color: Colors.blue.shade800, size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Hari ini, ${AppDateFormatter.formatFullDate(DateTime.now().toString())}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Status: Sedang Libur",
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Sesuai kebijakan instansi, hari ini ditetapkan sebagai hari libur. Selamat menikmati waktu istirahat Anda!",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.blue.shade700, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ] else if (settings != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFF6366f1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF6366f1), size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Ketentuan Absensi Hari Ini",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            
                            // Shift/Hours Section
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRuleItem(
                                    icon: Icons.login_rounded,
                                    label: "Maksimal Masuk",
                                    value: settings['check_in_end'],
                                    subtitle: "Mulai absen: ${settings['check_in_start']}",
                                    color: Colors.green,
                                  ),
                                ),
                                Container(width: 1, height: 45, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 16)),
                                Expanded(
                                  child: _buildRuleItem(
                                    icon: Icons.logout_rounded,
                                    label: "Mulai Pulang",
                                    value: settings['check_out_start'],
                                    subtitle: "Hingga: ${settings['check_out_end']}",
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            Text(
                              "DAFTAR SANKSI",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 12),
                            
                            // Penalties List
                            _buildPenaltyItem(
                              label: "Tanpa Keterangan (Alpha)",
                              value: "Rp ${CurrencyInputFormatter.formatNumber((settings['alpha_penalty'] as num?)?.toInt() ?? 0)}",
                            ),
                            const SizedBox(height: 8),

                            // Tiered or Constant Late Penalty
                            ...(() {
                              final tiersStr = settings['late_penalty_tiers'] as String?;
                              if (tiersStr != null && tiersStr.isNotEmpty && tiersStr != "[]") {
                                try {
                                  final List<dynamic> tiers = jsonDecode(tiersStr);
                                  return tiers.map((tier) {
                                    final hours = tier['hours'] ?? 0;
                                    final penalty = tier['penalty'] ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: _buildPenaltyItem(
                                        label: "Terlambat > $hours Jam",
                                        value: "Rp ${CurrencyInputFormatter.formatNumber(penalty)}",
                                      ),
                                    );
                                  }).toList();
                                } catch (e) {
                                  debugPrint("Error parsing penalty tiers: $e");
                                }
                              }
                              
                              // Fallback to constant penalty
                              return [
                                _buildPenaltyItem(
                                  label: "Terlambat Masuk Kantor",
                                  value: "Rp ${CurrencyInputFormatter.formatNumber((settings['late_penalty'] as num?)?.toInt() ?? 0)}",
                                ),
                                const SizedBox(height: 8),
                              ];
                            })(),
                            
                            _buildPenaltyItem(
                              label: "Pulang Mendahului Jadwal",
                              value: "Rp ${CurrencyInputFormatter.formatNumber((settings['early_leave_penalty'] as num?)?.toInt() ?? 0)}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: disabled || _actionLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: disabled ? Colors.grey.shade200 : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: _actionLoading && label.contains('Masuk') && !disabled // Simple spinner logic
                ? SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: color, strokeWidth: 2))
                : Icon(icon, color: disabled ? Colors.grey.shade400 : color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: disabled ? Colors.grey.shade400 : const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String time,
    required String status,
    required Color color,
    required bool isFirst,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status == 'Selesai' ? color.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'Selesai' ? color : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({required IconData icon, required String label, required String value, String? subtitle, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              if (subtitle != null)
                Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPenaltyItem({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
      ],
    );
  }
}

