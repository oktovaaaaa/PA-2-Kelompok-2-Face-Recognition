// lib/features/admin/presentation/screens/tabs/admin_profile_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../location_management_screen.dart';
import '../../../../common/widgets/premium_bottom_nav.dart';
import '../holiday_management_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';
import 'package:flutter/services.dart';
import '../../../../../core/utils/currency_formatter.dart';
import 'package:front_end/features/auth/presentation/screens/landing_screen.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../common/widgets/app_dialog.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../auth/data/auth_repository.dart';
import 'package:pinput/pinput.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _company;
  Map<String, dynamic>? _settings;
  bool _loading = true;
  File? _imageFile;
  final _repo = AuthRepository();
  int _otpCountdown = 0;
  Timer? _otpTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpTimer() {
    setState(() => _otpCountdown = 30);
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown == 0) {
        timer.cancel();
      } else {
        setState(() => _otpCountdown--);
      }
    });
  }

  Future<void> _logout() async {
    final act = await AppDialog.showConfirm(
      context,
      title: 'Keluar Aplikasi',
      message: 'Apakah Anda yakin ingin keluar dari sesi ini?',
      confirmText: 'Ya, Keluar',
      confirmColor: Colors.red.shade600,
    );

    if (act != true) return;
    await SessionStorage.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LandingScreen()), (_) => false);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profileRes = await ApiClient.get('/api/profile');
      final companyRes = await ApiClient.get('/api/admin/company');
      final settingsRes = await ApiClient.get('/api/admin/attendance-settings');
      if (mounted) {
        setState(() {
          _profile = profileRes.data as Map<String, dynamic>?;
          _company = companyRes.data as Map<String, dynamic>?;
          _settings = settingsRes.data as Map<String, dynamic>?;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() => _loading = true);
      try {
        final uploadRes = await ApiClient.uploadFile(file);
        if (uploadRes.status) {
          final photoUrl = uploadRes.data['url'];
          // Update profile dengan photo_url baru
          await ApiClient.put('/api/profile', {
            'name': _profile?['name'] ?? '',
            'phone': _profile?['phone'] ?? '',
            'birth_place': _profile?['birth_place'] ?? '',
            'birth_date': _profile?['birth_date'] ?? '',
            'address': _profile?['address'] ?? '',
            'photo_url': photoUrl,
          });
          setState(() {
            _imageFile = file;
            if (_profile != null) {
              _profile!['photo_url'] = photoUrl;
            }
          });
          if (mounted) {
            AppDialog.showSuccess(context, 'Foto pengaturan berhasil diperbarui.');
          }
        }
      } catch (e) {
        if (mounted) AppDialog.showError(context, 'Gagal memperbarui foto: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: _profile?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _profile?['phone'] ?? '');
    final birthPlaceCtrl = TextEditingController(text: _profile?['birth_place'] ?? '');
    final birthDateCtrl = TextEditingController(text: _profile?['birth_date'] ?? '');
    final addressCtrl = TextEditingController(text: _profile?['address'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Data Diri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              // Tambahkan Picker di dalam modal
              Center(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx); // Tutup modal dulu
                    _pickImage(); // Jalankan picker
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.1), width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: (_profile?['photo_url'] != null && _profile!['photo_url'].toString().isNotEmpty)
                              ? NetworkImage('${AppConstants.baseUrl}${_profile!['photo_url']}')
                              : null,
                          child: (_profile?['photo_url'] == null || _profile!['photo_url'].toString().isEmpty)
                              ? const Icon(Icons.person_rounded, size: 40, color: Color(0xFF94A3B8))
                              : null,
                        ),
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFF2563EB),
                          child: Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(controller: nameCtrl, label: 'Nama Lengkap', prefixIcon: Icons.person_outline_rounded),
              const SizedBox(height: 16),
              AppTextField(controller: phoneCtrl, label: 'Nomor Telepon', prefixIcon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              AppTextField(controller: birthPlaceCtrl, label: 'Tempat Lahir', prefixIcon: Icons.location_city_outlined),
              const SizedBox(height: 16),
              AppTextField(
                controller: birthDateCtrl, 
                label: 'Tanggal Lahir', 
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: () async {
                  final initial = DateTime.tryParse(birthDateCtrl.text) ?? DateTime(2000, 1, 1);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB))), child: child!);
                    },
                  );
                  if (picked != null) {
                    birthDateCtrl.text = picked.toString().substring(0, 10);
                  }
                },
              ),
              const SizedBox(height: 16),
              AppTextField(controller: addressCtrl, label: 'Alamat', prefixIcon: Icons.home_outlined, maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final res = await ApiClient.put('/api/profile', {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'birth_place': birthPlaceCtrl.text.trim(),
                      'birth_date': birthDateCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                    });
                    if (!mounted) return;
                    if (res.success) {
                      AppDialog.showSuccess(context, 'Pengaturan Berhasil Diperbarui');
                    } else {
                      AppDialog.showError(context, res.message ?? 'Gagal memperbarui profil');
                    }
                    if (res.success) _load();
                  },
                  child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editCompany() {
    final nameCtrl = TextEditingController(text: _company?['Name'] ?? _company?['name'] ?? '');
    final addressCtrl = TextEditingController(text: _company?['Address'] ?? _company?['address'] ?? '');
    final emailCtrl = TextEditingController(text: _company?['Email'] ?? _company?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: _company?['Phone'] ?? _company?['phone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Perusahaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
              const SizedBox(height: 24),
              _buildField(nameCtrl, 'Nama Perusahaan', Icons.business_outlined),
              _buildField(addressCtrl, 'Alamat Lengkap', Icons.map_outlined, maxLines: 2),
              _buildField(emailCtrl, 'Email Resmi', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
              _buildField(phoneCtrl, 'Telepon Kantor', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final res = await ApiClient.post('/api/admin/company', {
                      'Name': nameCtrl.text.trim(),
                      'Address': addressCtrl.text.trim(),
                      'Email': emailCtrl.text.trim(),
                      'Phone': phoneCtrl.text.trim(),
                    });
                    if (!mounted) return;
                    if (res.success) {
                      AppDialog.showSuccess(context, 'Instansi Berhasil Diperbarui');
                    } else {
                      AppDialog.showError(context, res.message ?? 'Gagal memperbarui instansi');
                    }
                    if (res.success) _load();
                  },
                  child: const Text('Update Instansi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editAttendanceSettings() {
    final checkInStartCtrl = TextEditingController(text: _settings?['check_in_start'] ?? '07:00');
    final checkInEndCtrl = TextEditingController(text: _settings?['check_in_end'] ?? '09:00');
    final checkOutStartCtrl = TextEditingController(text: _settings?['check_out_start'] ?? '16:00');
    final checkOutEndCtrl = TextEditingController(text: _settings?['check_out_end'] ?? '18:00');
    final penaltyCtrl = TextEditingController(
        text: _settings?['alpha_penalty'] != null
            ? CurrencyInputFormatter.formatNumber((_settings!['alpha_penalty'] as num).toInt())
            : '0');
    final latePenaltyCtrl = TextEditingController(
        text: _settings?['late_penalty'] != null
            ? CurrencyInputFormatter.formatNumber((_settings!['late_penalty'] as num).toInt())
            : '0');
    final earlyLeavePenaltyCtrl = TextEditingController(
        text: _settings?['early_leave_penalty'] != null
            ? CurrencyInputFormatter.formatNumber((_settings!['early_leave_penalty'] as num).toInt())
            : '0');
    
    // Parse work_days from settings
    List<String> workDays = (_settings?['work_days'] as String? ?? 'Monday,Tuesday,Wednesday,Thursday,Friday').split(',');
    if (workDays.isEmpty || (workDays.length == 1 && workDays[0] == "")) {
      workDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    }

    List<Map<String, dynamic>> tiers = [];
    if (_settings?['late_penalty_tiers'] != null) {
      final rawTiers = _settings!['late_penalty_tiers'];
      if (rawTiers is String && rawTiers.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawTiers);
          if (decoded is List) {
            tiers = List<Map<String, dynamic>>.from(decoded);
          }
        } catch (e) {
          print("Error decoding late_penalty_tiers: $e");
        }
      } else if (rawTiers is Iterable) {
        tiers = List<Map<String, dynamic>>.from(rawTiers);
      }
    }

    // Stable controllers management
    List<TextEditingController> hourCtrls = tiers.map((t) => TextEditingController(text: t['hours'].toString())).toList();
    List<TextEditingController> penaltyCtrls = tiers.map((t) => TextEditingController(text: CurrencyInputFormatter.formatNumber((t['penalty'] as num).toInt()))).toList();

    // Backup original penalty value for restoration
    final String originalBasicPenalty = _settings?['late_penalty'] != null
        ? CurrencyInputFormatter.formatNumber((_settings!['late_penalty'] as num).toInt())
        : '0';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20, 
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jam Operasional', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0F172A))
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Section 1: Waktu Absensi ---
                _buildSectionLabel('Waktu Absensi Masuk'),
                Row(
                  children: [
                    Expanded(child: _buildField(checkInStartCtrl, 'Mulai', Icons.access_time_rounded)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField(checkInEndCtrl, 'Selesai', Icons.timer_off_outlined)),
                  ],
                ),
                _buildSectionLabel('Waktu Absensi Pulang'),
                Row(
                  children: [
                    Expanded(child: _buildField(checkOutStartCtrl, 'Mulai', Icons.access_time_rounded)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField(checkOutEndCtrl, 'Selesai', Icons.timer_off_outlined)),
                  ],
                ),

                const Divider(height: 32),

                // --- Section 2: Sanksi & Denda ---
                _buildSectionLabel('Sanksi Ketidakhadiran (Alpha)'),
                _buildField(
                  penaltyCtrl, 
                  'Denda Alpha (Rp)', 
                  Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()]
                ),

                _buildSectionLabel('Denda Terlambat Dasar'),
                Builder(
                  builder: (context) {
                    bool hasTiers = tiers.isNotEmpty;
                    if (hasTiers) {
                      latePenaltyCtrl.text = "Otomatis (Berjenjang)";
                    } else if (latePenaltyCtrl.text == "Otomatis (Berjenjang)") {
                      latePenaltyCtrl.text = originalBasicPenalty;
                    }

                    return _buildField(
                      latePenaltyCtrl, 
                      'Denda Per Keterlambatan Dasar', 
                      Icons.warning_amber_rounded,
                      keyboardType: TextInputType.number,
                      readOnly: hasTiers,
                      color: hasTiers ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                      inputFormatters: hasTiers ? [] : [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                    );
                  }
                ),

                _buildSectionLabel('Denda Pulang di Jam Kerja'),
                _buildField(
                  earlyLeavePenaltyCtrl, 
                  'Denda Pulang Awal (Rp)', 
                  Icons.exit_to_app_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()]
                ),
                
                const SizedBox(height: 12),

                // --- Section 3: Denda Berjenjang ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Denda Berjenjang (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        Text('Sanksi tambahan berdasarkan lama keterlambatan', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                    if (tiers.length < 5)
                      IconButton.filled(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        onPressed: () => setModalState(() {
                          tiers.add({'hours': 1, 'penalty': 10000.0});
                          hourCtrls.add(TextEditingController(text: '1'));
                          penaltyCtrls.add(TextEditingController(text: '10.000'));
                        }),
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (tiers.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('Belum ada sanksi berjenjang', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontStyle: FontStyle.italic)),
                    ),
                  ),

                ...List.generate(tiers.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            hourCtrls[index],
                            'Jam Ke-', Icons.timer_outlined,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => tiers[index]['hours'] = int.tryParse(v) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildField(
                            penaltyCtrls[index],
                            'Besar Sanksi (Rp)', Icons.payments_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                            onChanged: (v) => tiers[index]['penalty'] = CurrencyInputFormatter.unformat(v).toDouble(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                          onPressed: () => setModalState(() {
                            tiers.removeAt(index);
                            hourCtrls.removeAt(index);
                            penaltyCtrls.removeAt(index);
                          }),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final res = await ApiClient.put('/api/admin/attendance-settings', {
                        'check_in_start': checkInStartCtrl.text.trim(),
                        'check_in_end': checkInEndCtrl.text.trim(),
                        'check_out_start': checkOutStartCtrl.text.trim(),
                        'check_out_end': checkOutEndCtrl.text.trim(),
                        'alpha_penalty': CurrencyInputFormatter.unformat(penaltyCtrl.text.trim()).toDouble(),
                        'late_penalty': tiers.isNotEmpty ? 0 : CurrencyInputFormatter.unformat(latePenaltyCtrl.text.trim()).toDouble(),
                        'late_penalty_tiers': tiers,
                        'early_leave_penalty': CurrencyInputFormatter.unformat(earlyLeavePenaltyCtrl.text.trim()).toDouble(),
                        'work_days': workDays.join(','),
                      });
                      if (!mounted) return;
                      if (res.success) {
                        AppDialog.showSuccess(context, 'Pengaturan operasional disimpan');
                      } else {
                        AppDialog.showError(context, res.message ?? 'Gagal menyimpan pengaturan');
                      }
                      if (res.success) _load();
                    },
                    child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, List<TextInputFormatter>? inputFormatters, bool readOnly = false, Color? color, VoidCallback? onTap, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            filled: true,
            fillColor: color ?? const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _val(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return '-';
    for (final k in keys) {
      final v = map[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '-';
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
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Header Premium
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                            image: (_profile?['photo_url'] != null && _profile!['photo_url'].toString().isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage('${AppConstants.baseUrl}${_profile!['photo_url']}'),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (_profile?['photo_url'] == null || _profile!['photo_url'].toString().isEmpty)
                              ? Center(
                                  child: Text(
                                    _getInitials(_profile?['name'] ?? 'Bos'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_profile?['name'] ?? 'Bos', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(_profile?['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
  
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildDataCard(
                    title: 'Data Diri',
                    icon: Icons.badge_outlined,
                    color: const Color(0xFF2563EB),
                    onEdit: _editProfile,
                    rows: [
                      _infoRow('Nama', _val(_profile, ['name'])),
                      _infoRow('Email', _val(_profile, ['email'])),
                      _infoRow('Telepon', _val(_profile, ['phone'])),
                      _infoRow('Tempat Lahir', _val(_profile, ['birth_place'])),
                      _infoRow('Tgl Lahir', _val(_profile, ['birth_date'])),
                      _infoRow('Alamat', _val(_profile, ['address'])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDataCard(
                    title: 'Data Perusahaan',
                    icon: Icons.business_center_outlined,
                    color: const Color(0xFF1E3A8A),
                    onEdit: _editCompany,
                    rows: [
                      _infoRow('Nama', _val(_company, ['Name', 'name'])),
                      _infoRow('Instansi', _val(_company, ['Address', 'address'])),
                      _infoRow('Kontak', _val(_company, ['Phone', 'phone'])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDataCard(
                    title: 'Lokasi Kantor',
                    icon: Icons.location_on_outlined,
                    color: const Color(0xFF2563EB),
                    onEdit: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLocationManagementScreen()));
                    },
                    rows: [
                      _infoRow('Status', 'Kelola titik geofencing kantor'),
                      _infoRow('Peta', 'Pilih koordinat & radius'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDataCard(
                    title: 'Waktu Operasional',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFF2563EB),
                    onEdit: _editAttendanceSettings,
                    rows: [
                      _infoRow('Check-In', '${_val(_settings, ['check_in_start'])} - ${_val(_settings, ['check_in_end'])}'),
                      _infoRow('Check-Out', '${_val(_settings, ['check_out_start'])} - ${_val(_settings, ['check_out_end'])}'),
                      _infoRow('Sanksi Alpha', 'Rp ${CurrencyInputFormatter.formatNumber((_settings?['alpha_penalty'] as num?)?.toInt() ?? 0)}'),
                      if (_settings?['late_penalty_tiers'] == null || _settings!['late_penalty_tiers'].toString() == "[]" || _settings!['late_penalty_tiers'].toString() == "")
                        _infoRow('Sanksi Terlambat', 'Rp ${CurrencyInputFormatter.formatNumber((_settings?['late_penalty'] as num?)?.toInt() ?? 0)}')
                      else
                        _infoRow('Sanksi Terlambat', 'Berjenjang (Aktif)'),
                      _infoRow('Sanksi Pulang Awal', 'Rp ${CurrencyInputFormatter.formatNumber((_settings?['early_leave_penalty'] as num?)?.toInt() ?? 0)}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDataCard(
                    title: 'Hari Libur',
                    icon: Icons.beach_access_rounded,
                    color: const Color(0xFF2563EB),
                    onEdit: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HolidayManagementScreen())).then((_) => _load());
                    },
                    rows: [
                      _infoRow('Jadwal Kerja', _settings?['work_days']?.toString().split(',').length == 7 ? 'Setiap Hari' : (_settings?['work_days']?.toString() ?? 'Senin - Jumat').replaceAll('Monday', 'Sen').replaceAll('Tuesday', 'Sel').replaceAll('Wednesday', 'Rab').replaceAll('Thursday', 'Kam').replaceAll('Friday', 'Jum').replaceAll('Saturday', 'Sab').replaceAll('Sunday', 'Min')),
                      _infoRow('Status', 'Kelola hari libur khusus'),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildSecurityCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 24),
                SizedBox(width: 16),
                Text('Keamanan Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            onTap: _showChangePasswordModal,
            leading: const Icon(Icons.lock_reset_rounded, color: Color(0xFF1E3A8A)),
            title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Wajib masukkan password lama & OTP email', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
          const Divider(height: 1, indent: 70),
          ListTile(
            onTap: _showChangePinModal,
            leading: const Icon(Icons.pin_rounded, color: Color(0xFF1E3A8A)),
            title: const Text('Ubah PIN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Wajib masukkan PIN lama & OTP email', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
          const Divider(height: 1, indent: 70),
          ListTile(
            onTap: _showDeleteAccountFlow,
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            title: const Text('Hapus Akun Permanen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.red)),
            subtitle: const Text('Seluruh data instansi akan terhapus total', style: TextStyle(fontSize: 12, color: Colors.red)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordModal() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    
    bool sendingOtp = false;
    bool otpSent = false;
    int localCountdown = 0;
    Timer? localTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void startLocalTimer() {
            setModalState(() => localCountdown = 30);
            localTimer?.cancel();
            localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (localCountdown == 0) {
                timer.cancel();
              } else {
                setModalState(() => localCountdown--);
              }
            });
          }

          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                    IconButton(onPressed: () {
                      localTimer?.cancel();
                      Navigator.pop(context);
                    }, icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  otpSent 
                    ? 'Silakan masukkan kode OTP yang telah dikirim ke email Anda dan buat password baru.'
                    : 'Untuk keamanan Admin, silakan masukkan password lama Anda untuk meminta kode OTP verifikasi.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)
                ),
                const SizedBox(height: 24),
                
                // STEP 1: PASSWORD LAMA
                AppTextField(
                  controller: oldPassCtrl, 
                  label: 'Password Lama', 
                  obscure: true, 
                  prefixIcon: Icons.lock_outline_rounded,
                  enabled: !otpSent,
                ),
                const SizedBox(height: 24),

                if (!otpSent) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: sendingOtp ? null : () async {
                        if (oldPassCtrl.text.isEmpty) {
                          AppDialog.showError(context, 'Masukkan password lama Anda');
                          return;
                        }
                        setModalState(() => sendingOtp = true);
                        try {
                          await _repo.requestProfileOtp();
                          startLocalTimer();
                          setModalState(() {
                            sendingOtp = false;
                            otpSent = true;
                          });
                          AppDialog.showSuccess(context, 'Kode OTP berhasil dikirim ke email');
                        } catch (e) {
                          setModalState(() => sendingOtp = false);
                          AppDialog.showError(context, 'Gagal: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: sendingOtp 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Kirim Kode OTP ke Email', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  // STEP 2: OTP & PASSWORD BARU
                  const Text('Kode OTP (6 Digit)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Center(
                    child: Pinput(
                      controller: otpCtrl,
                      length: 6,
                      defaultPinTheme: PinTheme(
                        width: 46, height: 52,
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF3B82F6))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: localCountdown > 0 ? null : () async {
                        setModalState(() => sendingOtp = true);
                        try {
                          await _repo.requestProfileOtp();
                          startLocalTimer();
                          setModalState(() => sendingOtp = false);
                          AppDialog.showSuccess(context, 'OTP dikirim ulang');
                        } catch (e) {
                          setModalState(() => sendingOtp = false);
                          AppDialog.showError(context, 'Gagal: $e');
                        }
                      },
                      child: Text(localCountdown > 0 ? 'Kirim Ulang dalam $localCountdown s' : 'Kirim Ulang OTP'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(controller: newPassCtrl, label: 'Password Baru', obscure: true, prefixIcon: Icons.vpn_key_outlined),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: sendingOtp ? null : () async {
                        if (otpCtrl.text.length != 6 || newPassCtrl.text.isEmpty) {
                          AppDialog.showError(context, 'Lengkapi OTP dan Password Baru');
                          return;
                        }
                        setModalState(() => sendingOtp = true);
                        try {
                          await _repo.changePassword(
                            oldPassword: oldPassCtrl.text, 
                            otpCode: otpCtrl.text, 
                            newPassword: newPassCtrl.text
                          );
                          Navigator.pop(context); // Close modal
                          AppDialog.showSuccess(context, 'Password berhasil diperbarui');
                        } catch (e) {
                          setModalState(() => sendingOtp = false);
                          AppDialog.showError(context, 'Gagal: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: sendingOtp 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan Password Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
      ),
    );
  }

  void _showChangePinModal() {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    
    bool sendingOtp = false;
    bool otpSent = false;
    int localCountdown = 0;
    Timer? localTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void startLocalTimer() {
            setModalState(() => localCountdown = 30);
            localTimer?.cancel();
            localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (localCountdown == 0) {
                timer.cancel();
              } else {
                setModalState(() => localCountdown--);
              }
            });
          }

          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ubah PIN Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                    IconButton(onPressed: () {
                      localTimer?.cancel();
                      Navigator.pop(context);
                    }, icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  otpSent 
                    ? 'Silakan masukkan kode OTP yang telah dikirim ke email Anda dan buat PIN baru.'
                    : 'Sebagai Admin, Anda perlu memverifikasi identitas dengan PIN lama untuk meminta OTP.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)
                ),
                const SizedBox(height: 24),
                
                // STEP 1: PIN LAMA
                const Text('PIN Lama', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                Center(
                  child: Pinput(
                    controller: oldPinCtrl,
                    length: 6,
                    obscureText: true,
                    enabled: !otpSent,
                    defaultPinTheme: PinTheme(
                      width: 46, height: 52,
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (!otpSent) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: sendingOtp ? null : () async {
                        if (oldPinCtrl.text.length != 6) {
                          AppDialog.showError(context, 'Masukkan PIN lama 6 digit');
                          return;
                        }
                        setModalState(() => sendingOtp = true);
                        try {
                          await _repo.requestProfileOtp();
                          startLocalTimer();
                          setModalState(() {
                            sendingOtp = false;
                            otpSent = true;
                          });
                          AppDialog.showSuccess(context, 'OTP berhasil dikirim ke email Anda');
                        } catch (e) {
                          setModalState(() => sendingOtp = false);
                          AppDialog.showError(context, 'Gagal mengirim OTP: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: sendingOtp 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Kirim Kode OTP ke Email', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  // STEP 2: OTP & PIN BARU
                  const Text('Kode OTP (Cek Email)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Center(
                    child: Pinput(
                      controller: otpCtrl,
                      length: 6,
                      defaultPinTheme: PinTheme(
                        width: 46, height: 52,
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF3B82F6))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: localCountdown > 0 ? null : () async {
                        setModalState(() => sendingOtp = true);
                        try {
                          await _repo.requestProfileOtp();
                          startLocalTimer();
                          setModalState(() => sendingOtp = false);
                          AppDialog.showSuccess(context, 'OTP dikirim ulang');
                        } catch (e) {
                          setModalState(() => sendingOtp = false);
                          AppDialog.showError(context, 'Gagal: $e');
                        }
                      },
                      child: Text(localCountdown > 0 ? 'Kirim Ulang dalam $localCountdown s' : 'Kirim Ulang OTP'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('PIN Baru', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Center(
                    child: Pinput(
                      controller: newPinCtrl,
                      length: 6,
                      obscureText: true,
                      defaultPinTheme: PinTheme(
                        width: 46, height: 52,
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: sendingOtp ? null : () async {
                        if (otpCtrl.text.length != 6 || newPinCtrl.text.length != 6) {
                          AppDialog.showError(context, 'Lengkapi OTP dan PIN Baru');
                          return;
                        }
                        setModalState(() => sendingOtp = true);
                        try {
                          await _repo.changePin(
                            oldPin: oldPinCtrl.text, 
                            otpCode: otpCtrl.text, 
                            newPin: newPinCtrl.text
                          );
                          Navigator.pop(context); // Close modal
                          AppDialog.showSuccess(context, 'PIN berhasil diperbarui');
                        } catch (e) {
                          setModalState(() => sendingOtp = false);
                          AppDialog.showError(context, 'Gagal: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB), 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      child: sendingOtp 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan PIN Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
      ),
    );
  }

  void _showDeleteAccountFlow() async {
    final name = (_profile?['name'] ?? '').toString();
    if (name.isEmpty || name == '-') {
      AppDialog.showError(context, 'Data profil belum dimuat sepenuhnya. Harap tunggu sebentar atau muat ulang halaman.');
      return;
    }

    // STEP 1: Konfirmasi awal
    final step1 = await AppDialog.showConfirm(
      context,
      title: 'Hapus Akun Permanen',
      message: 'Anda akan menghapus akun admin Anda secara permanen.\n\nTindakan ini TIDAK DAPAT DIBATALKAN.\nSeluruh data pribadi, riwayat absensi, denda, dan catatan lainnya akan hilang selamanya.\n\nApakah Anda yakin ingin melanjutkan?',
      confirmText: 'Ya, Lanjutkan',
      confirmColor: Colors.orange,
    );
    if (step1 != true || !mounted) return;

    // STEP 2: Minta password
    final passwordCtrl = TextEditingController();
    bool passwordLoading = false;
    String? passwordFromStep2;

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
                    Icon(Icons.lock_outline_rounded, color: Colors.red, size: 28),
                    SizedBox(width: 12),
                    Text('Verifikasi Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0F172A))),
                  ]),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Masukkan password akun Anda untuk membuktikan identitas.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 24),
              AppTextField(controller: passwordCtrl, label: 'Password Anda', obscure: true, prefixIcon: Icons.vpn_key_rounded),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: passwordLoading ? null : () async {
                    if (passwordCtrl.text.trim().isEmpty) {
                      AppDialog.showError(context, 'Password tidak boleh kosong');
                      return;
                    }
                    
                    setModalState(() => passwordLoading = true);
                    try {
                      final res = await ApiClient.post('/api/profile/verify-password', {
                        'password': passwordCtrl.text.trim(),
                      });
                      
                      if (res.success) {
                        passwordFromStep2 = passwordCtrl.text.trim();
                        if (context.mounted) Navigator.pop(context);
                      } else {
                        if (context.mounted) AppDialog.showError(context, res.message ?? 'Password salah');
                        setModalState(() => passwordLoading = false);
                      }
                    } catch (e) {
                      if (context.mounted) AppDialog.showError(context, 'Terjadi kesalahan verifikasi: $e');
                      setModalState(() => passwordLoading = false);
                    }
                  },
                  child: passwordLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verifikasi & Lanjutkan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (passwordFromStep2 == null || passwordFromStep2!.isEmpty || !mounted) return;

    // STEP 3: Ketik SAYA YAKIN
    final phraseCtrl = TextEditingController();
    bool deleteLoading = false;

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
                child: const Text(
                  'Ini adalah langkah terakhir yang tidak dapat diurungkan.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  children: [
                    const TextSpan(text: 'Ketik '),
                    TextSpan(
                      text: 'SAYA YAKIN MENGHAPUS AKUN ${(_profile?['name'] ?? '').toString().toUpperCase()}', 
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 13)
                    ),
                    const TextSpan(text: ' pada kotak di bawah untuk memproses penghapusan akun secara permanen.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: phraseCtrl, 
                label: 'Ketik frasa di atas', 
                prefixIcon: Icons.text_fields_rounded
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
                  onPressed: () {
                    final expectedPhrase = 'SAYA YAKIN MENGHAPUS AKUN ${(_profile?['name'] ?? '').toString().toUpperCase()}';
                    if (phraseCtrl.text.trim() != expectedPhrase) {
                      AppDialog.showError(context, 'Frasa konfirmasi harus persis: $expectedPhrase');
                      return;
                    }
                    Navigator.pop(context);
                    _showFinalStep4(passwordFromStep2!, expectedPhrase);
                  },
                  child: const Text('Lanjutkan ke Tahap Akhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinalStep4(String password, String phrase) async {
    bool finalAgreed = false;
    bool deleteLoading = false;

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
                    Icon(Icons.shield_rounded, color: Colors.red, size: 28),
                    SizedBox(width: 12),
                    Text('Persetujuan Akhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.red)),
                  ]),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Harap baca pernyataan di bawah ini dengan sangat teliti:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  children: [
                    _bulletWarning('Seluruh akun karyawan perusahaan ini akan dihapus permanen.'),
                    const SizedBox(height: 8),
                    _bulletWarning('Data absensi, gaji, dan riwayat denda akan dimusnahkan.'),
                    const SizedBox(height: 8),
                    _bulletWarning('Data yang dihapus TIDAK DAPAT dipulihkan kembali.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: finalAgreed,
                onChanged: (val) => setModalState(() => finalAgreed = val ?? false),
                activeColor: Colors.red,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Saya mengerti dan setuju bahwa dengan menghapus akun ini, seluruh data perusahaan dan karyawan akan terhapus permanen dan tidak dapat dipulihkan.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: (deleteLoading || !finalAgreed) ? null : () async {
                    setModalState(() => deleteLoading = true);
                    try {
                      final res = await ApiClient.delete('/api/profile', body: {
                        'password': password,
                        'confirmation_phrase': phrase,
                      });
                      if (!mounted) return;
                      if (res.success) {
                        Navigator.pop(context);
                        await SessionStorage.clear();
                        if (!mounted) return;
                        AppDialog.showSuccess(context, 'Akun dan Data Instansi Berhasil Dihapus');
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LandingScreen()),
                          (route) => false,
                        );
                      } else {
                        AppDialog.showError(context, res.message ?? 'Gagal memproses penghapusan');
                        setModalState(() => deleteLoading = false);
                      }
                    } catch (e) {
                      if (mounted) AppDialog.showError(context, 'Terjadi kesalahan: $e');
                      setModalState(() => deleteLoading = false);
                    }
                  },
                  child: deleteLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('HAPUS PERUSAHAAN & DATA SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulletWarning(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildDataCard({required String title, required IconData icon, required Color color, required VoidCallback onEdit, required List<Widget> rows}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)))),
                IconButton(onPressed: onEdit, icon: Icon(Icons.edit_note_rounded, color: color, size: 28)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(20), child: Column(children: rows)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)))),
        ],
      ),
    );
  }
}
