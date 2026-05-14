// lib/features/employee/presentation/screens/tabs/employee_profile_tab.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../auth/presentation/screens/landing_screen.dart';
import 'package:flutter/services.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../common/widgets/app_dialog.dart';
import '../../../../auth/data/auth_repository.dart';
import '../face_registration_screen.dart';
import 'package:pinput/pinput.dart';
import '../../../../../core/utils/currency_formatter.dart';

class EmployeeProfileTab extends StatefulWidget {
  const EmployeeProfileTab({super.key});

  @override
  State<EmployeeProfileTab> createState() => _EmployeeProfileTabState();
}

class _EmployeeProfileTabState extends State<EmployeeProfileTab> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  File? _imageFile;
  final ValueNotifier<int> _otpCountdown = ValueNotifier<int>(0);
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
    _otpCountdown.value = 30;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown.value == 0) {
        timer.cancel();
      } else {
        _otpCountdown.value--;
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
      final res = await ApiClient.get('/api/profile');
      if (res.success && mounted) {
        setState(() => _profile = res.data as Map<String, dynamic>?);
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
            AppDialog.showSuccess(context, 'Foto profil berhasil diperbarui.');
          }
        }
      } catch (e) {
        if (mounted) AppDialog.showError(context, 'Gagal memperbarui foto: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final pts = name.trim().split(RegExp(r'\s+'));
    if (pts.length >= 2) {
      return (pts[0][0] + pts[1][0]).toUpperCase();
    }
    return pts[0][0].toUpperCase();
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
              Center(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    _pickImage();
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
                              ? Text(
                                  _getInitials(_v('name')),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 24),
                                )
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
                      'photo_url': _profile?['photo_url'],
                    });
                    if (!mounted) return;
                    if (res.success) {
                      AppDialog.showSuccess(context, 'Profil Berhasil Diperbarui');
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

  void _editBankInfo() {
    final bankNameCtrl = TextEditingController(text: _v('bank_name'));
    final accountNumberCtrl = TextEditingController(text: _v('bank_account_number'));

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
                  const Text('Edit Informasi Rekening', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Pastikan nomor rekening atau ID E-Wallet sudah benar untuk kelancaran penggajian.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 24),
              AppTextField(controller: bankNameCtrl, label: 'Nama Bank atau E-Wallet', prefixIcon: Icons.account_balance_rounded, hint: "BCA, Mandiri, Dana, OVO, dll"),
              const SizedBox(height: 16),
              AppTextField(controller: accountNumberCtrl, label: 'Nomor Rekening', prefixIcon: Icons.numbers_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (bankNameCtrl.text.isEmpty || accountNumberCtrl.text.isEmpty) {
                      AppDialog.showError(context, 'Semua data bank harus diisi');
                      return;
                    }

                    Navigator.pop(ctx);
                    final res = await ApiClient.put('/api/employee/bank-info', {
                      'bank_name': bankNameCtrl.text.trim(),
                      'bank_account_number': accountNumberCtrl.text.trim(),
                    });
                    
                    if (!mounted) return;
                    if (res.success) {
                      AppDialog.showSuccess(context, 'Informasi Bank Berhasil Diperbarui');
                      _load();
                    } else {
                      AppDialog.showError(context, res.message ?? 'Gagal memperbarui informasi bank');
                    }
                  },
                  child: const Text('Simpan Data Rekening', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, bool readOnly = false, VoidCallback? onTap}) {
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
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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

  String _v(String key) => _profile?[key]?.toString() ?? '-';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));

    final salary = (_profile?['salary'] as num? ?? 0);
    final hasSalary = salary > 0;
    final positionName = _v('position_name');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Header Premium with Avatar
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
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
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
                                    _getInitials(_v('name')),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
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
                  const SizedBox(height: 16),
                  Text(_v('name'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(_v('email'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 12),
                  if (positionName != '-')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_outline_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(positionName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
  
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (hasSalary) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gaji Pokok Bulanan', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                'Rp ${CurrencyInputFormatter.formatNumber(salary.toInt())}',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildDataCard(
                    title: 'Data Diri',
                    icon: Icons.person_outline_rounded,
                    color: const Color(0xFF2563EB),
                    onEdit: _editProfile,
                    rows: [
                      _infoRow('Telepon', _v('phone')),
                      _infoRow('Tempat Lahir', _v('birth_place')),
                      _infoRow('Tgl Lahir', _v('birth_date')),
                      _infoRow('Alamat', _v('address')),
                      _infoRow('Status Akun', _v('status') == 'ACTIVE' ? 'Aktif' : 'Diberhentikan'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDataCard(
                    title: 'Informasi Bank atau E-Wallet',
                    icon: Icons.account_balance_rounded,
                    color: const Color(0xFF10B981),
                    onEdit: _editBankInfo,
                    rows: [
                      _infoRow('Gaji Pokok', 'Rp ${CurrencyInputFormatter.formatNumber(salary.toInt())}'),
                      _infoRow('Rekening Bank atau E-Wallet', _v('bank_name')),
                      _infoRow('No. Rekening / ID', _v('bank_account_number')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSecurityCard(),
                  const SizedBox(height: 20),
                  _buildFaceIdCard(),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _logout,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(child: Text('Keluar dari Aplikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red))),
                              const Icon(Icons.chevron_right_rounded, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
            subtitle: const Text('Gunakan password lama atau OTP email', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
          const Divider(height: 1, indent: 70),
          ListTile(
            onTap: _showChangePinModal,
            leading: const Icon(Icons.pin_rounded, color: Color(0xFF1E3A8A)),
            title: const Text('Ubah PIN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Gunakan PIN lama atau OTP email', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
          const Divider(height: 1, indent: 70),
          ListTile(
            onTap: _showDeleteAccountFlow,
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            title: const Text('Resign & Hapus Akun', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.red)),
            subtitle: const Text('Data riwayat tetap tersimpan di perusahaan', style: TextStyle(fontSize: 12, color: Colors.red)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceIdCard() {
    final bool isRegistered = _profile?['face_embedding_registered'] ?? false;
    final String lastUpdated = _profile?['face_updated_at'] != null 
        ? _profile!['face_updated_at'].toString().substring(0, 10) 
        : '-';

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
                Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF2563EB), size: 24),
                SizedBox(width: 16),
                Text('Presensi Face ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRegistered ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRegistered ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
                color: isRegistered ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              isRegistered ? 'Face ID Terdaftar' : 'Face ID Belum Terdaftar',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              isRegistered ? 'Terakhir diperbarui: $lastUpdated' : 'Daftarkan wajah untuk fitur absensi AI',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaceRegistrationScreen()),
                  );
                  if (result == true) {
                    _load();
                  }
                },
                icon: const Icon(Icons.camera_front_rounded, size: 18),
                label: Text(isRegistered ? 'Perbarui Face ID' : 'Daftar Face ID Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRegistered ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordModal() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final repo = AuthRepository();
    
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
                    : 'Untuk keamanan, silakan masukkan password lama Anda untuk meminta kode OTP verifikasi.',
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
                          await repo.requestProfileOtp();
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
                          await repo.requestProfileOtp();
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
                          await repo.changePassword(
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
    final repo = AuthRepository();
    
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
                    : 'Untuk mengubah PIN, kami perlu memverifikasi identitas Anda dengan PIN lama.',
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
                          await repo.requestProfileOtp();
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
                  // STEP 2: OTP & PIN BARU (HANYA MUNCUL SETELAH OTP TERKIRIM)
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
                          await repo.requestProfileOtp();
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
                          await repo.changePin(
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
      message: 'Anda akan menghapus akun karyawan Anda secara permanen.\n\nTindakan ini TIDAK DAPAT DIBATALKAN.\nAnda tidak akan bisa login kembali ke aplikasi ini.\n\nCatatan: Data riwayat absensi, denda, dan cuti Anda tetap tersimpan di perusahaan untuk keperluan pencatatan.\n\nApakah Anda yakin ingin melanjutkan?',
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
                    const TextSpan(text: ' pada kotak di bawah untuk menghapus akun Anda secara permanen.'),
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
                  onPressed: deleteLoading ? null : () async {
                    final expectedPhrase = 'SAYA YAKIN MENGHAPUS AKUN ${(_profile?['name'] ?? '').toString().toUpperCase()}';
                    if (phraseCtrl.text.trim() != expectedPhrase) {
                      AppDialog.showError(context, 'Frasa konfirmasi harus persis: $expectedPhrase');
                      return;
                    }
                    setModalState(() => deleteLoading = true);
                    try {
                      final res = await ApiClient.delete('/api/profile', body: {
                        'password': passwordFromStep2,
                        'confirmation_phrase': expectedPhrase,
                      });
                      if (!mounted) return;
                      if (res.success) {
                        Navigator.pop(context);
                        await SessionStorage.clear();
                        if (!mounted) return;
                        AppDialog.showSuccess(context, 'Proses Resign dan Hapus Akun Berhasil');
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LandingScreen()),
                          (route) => false,
                        );
                      } else {
                        AppDialog.showError(context, res.message ?? 'Gagal memproses pengunduran diri');
                        setModalState(() => deleteLoading = false);
                      }
                    } catch (e) {
                      if (mounted) AppDialog.showError(context, 'Terjadi kesalahan: $e');
                      setModalState(() => deleteLoading = false);
                    }
                  },
                  child: deleteLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever_rounded),
                          SizedBox(width: 8),
                          Text('Resign & Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
