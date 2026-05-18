import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/wavy_background.dart';
import '../../data/auth_repository.dart';
import '../../../admin/presentation/screens/login_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pinput/pinput.dart';
import '../../../common/widgets/app_dialog.dart';

class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _repo = AuthRepository();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pin = TextEditingController();
  final _phone = TextEditingController();
  final _birthPlace = TextEditingController();
  final _birthDate = TextEditingController();
  final _address = TextEditingController();
  final _otpCode = TextEditingController();

  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyPhone = TextEditingController();

  bool _loading = false;
  bool _otpLoading = false;
  bool _otpSent = false;
  int _currentStep = 0;
  File? _imageFile;
  String? _googleIdToken;

  final _dateFormatter = MaskTextInputFormatter(
    mask: '##-##-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  Future<void> _fetchGoogleData() async {
    try {
      final authData = await _repo.getGoogleAuthData();
      if (authData != null) {
        setState(() {
          _googleIdToken = authData['idToken'];
          _email.text = authData['email']!;
          _name.text = authData['name']!;
        });
        if (!mounted) return;
        AppDialog.showInfo(context, 'Akun Google tertaut. Lanjutkan mengisi data.');
      }
    } catch (e) {
      if (!mounted) return;
      AppDialog.showError(context, 'Gagal menghubungkan Google: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _requestOtp() async {
    if (_email.text.isEmpty || !_email.text.contains('@')) {
      AppDialog.showError(context, 'Masukkan email yang valid');
      return;
    }

    setState(() => _otpLoading = true);
    try {
      await _repo.sendOtp(_email.text.trim());
      setState(() => _otpSent = true);
      if (!mounted) return;
      AppDialog.showSuccess(context, 'Kode OTP telah dikirim ke email Anda');
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      AppDialog.showError(context, msg);
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_googleIdToken == null && !_otpSent && _currentStep == 0) {
      AppDialog.showError(context, 'Silakan kirim dan isi kode OTP terlebih dahulu');
      return;
    }

    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      return;
    }

    setState(() => _loading = true);
    try {
      String? photoUrl;
      if (_imageFile != null) {
        final uploadRes = await ApiClient.uploadFile(_imageFile!);
        if (uploadRes.status) {
          photoUrl = uploadRes.data['url'];
        }
      }

      await _repo.registerAdmin(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        pin: _pin.text,
        phone: _phone.text.trim(),
        birthPlace: _birthPlace.text.trim(),
        birthDate: _birthDate.text.trim(),
        address: _address.text.trim(),
        companyName: _companyName.text.trim(),
        companyAddress: _companyAddress.text.trim(),
        companyEmail: _companyEmail.text.trim(),
        companyPhone: _companyPhone.text.trim(),
        photoUrl: photoUrl,
        googleIdToken: _googleIdToken,
        otpCode: _otpCode.text.trim(),
      );
      if (!mounted) return;
      AppDialog.showSuccess(context, 'Registrasi admin berhasil. Silakan login.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      AppDialog.showError(context, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Widget _buildSectionCard({required String title, required IconData icon, required Color color, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WavyBackground(
      isAuth: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24, 
          right: 24, 
          top: 48, 
          bottom: MediaQuery.of(context).viewInsets.bottom + 48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E3A8A), size: 20),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Daftar Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text('Lengkapi data diri dan perusahaan Anda', style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_currentStep == 0) ...[
                    if (_googleIdToken == null) ...[
                      GestureDetector(
                        onTap: _loading ? null : _fetchGoogleData,
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Tautkan dengan akun Google',
                                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 12),
                              Image.network(
                                'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                                width: 32, height: 32,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionCard(
                      title: 'Data Pribadi',
                      icon: Icons.person_rounded,
                      color: const Color(0xFF2563EB),
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2), width: 4),
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                                    child: _imageFile == null
                                        ? const Icon(Icons.camera_alt_rounded, size: 40, color: Color(0xFF94A3B8))
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppTextField(controller: _name, label: 'Nama Lengkap', validator: _required, prefixIcon: Icons.person_outline_rounded),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _email,
                                label: 'Alamat Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: _required,
                                prefixIcon: Icons.email_outlined,
                                enabled: _googleIdToken == null,
                              ),
                            ),
                            if (_googleIdToken == null) ...[
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: SizedBox(
                                  height: 56,
                                  child: TextButton(
                                    onPressed: _otpLoading || _loading ? null : _requestOtp,
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _otpLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        : Text(_otpSent ? 'Kirim Ulang' : 'Kirim OTP', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (_googleIdToken == null && _otpSent) ...[
                          const SizedBox(height: 20),
                          const Text('Masukkan Kode OTP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          const SizedBox(height: 12),
                          Center(
                            child: Pinput(
                              controller: _otpCode,
                              length: 6,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              defaultPinTheme: PinTheme(
                                width: 45,
                                height: 50,
                                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                              ),
                              focusedPinTheme: PinTheme(
                                width: 45,
                                height: 50,
                                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFF2563EB), width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        AppTextField(controller: _password, label: 'Kata Sandi', obscure: true, validator: _required, prefixIcon: Icons.lock_outline_rounded),
                        const SizedBox(height: 16),
                        const Text('PIN Keamanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 12),
                        Center(
                          child: Pinput(
                            controller: _pin,
                            length: 6,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            defaultPinTheme: PinTheme(
                              width: 45,
                              height: 50,
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 45,
                              height: 50,
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFF2563EB), width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'PIN wajib diisi';
                              if (v.length != 6) return 'PIN harus 6 digit';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(controller: _phone, label: 'Nomor Telepon', keyboardType: TextInputType.phone, validator: _required, prefixIcon: Icons.phone_android_rounded),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: AppTextField(controller: _birthPlace, label: 'Tempat Lahir', validator: _required, prefixIcon: Icons.location_city_outlined)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _birthDate,
                                label: 'Tgl Lahir',
                                readOnly: true,
                                prefixIcon: Icons.calendar_today_rounded,
                                onTap: () async {
                                  final initial = DateTime.tryParse(_birthDate.text) ?? DateTime(2000, 1, 1);
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
                                    setState(() {
                                      _birthDate.text = picked.toString().substring(0, 10);
                                    });
                                  }
                                },
                                validator: _required,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(controller: _address, label: 'Alamat', validator: _required, prefixIcon: Icons.home_outlined),
                      ],
                    ),
                  ],
                  if (_currentStep == 1) ...[
                    _buildSectionCard(
                      title: 'Data Perusahaan',
                      icon: Icons.business_rounded,
                      color: const Color(0xFF1E3A8A),
                      children: [
                        AppTextField(controller: _companyName, label: 'Nama Perusahaan', validator: _required, prefixIcon: Icons.business_center_rounded),
                        const SizedBox(height: 16),
                        AppTextField(controller: _companyEmail, label: 'Email Perusahaan', keyboardType: TextInputType.emailAddress, validator: _required, prefixIcon: Icons.business_rounded),
                        const SizedBox(height: 16),
                        AppTextField(controller: _companyPhone, label: 'Telepon Perusahaan', keyboardType: TextInputType.phone, validator: _required, prefixIcon: Icons.phone_android_rounded),
                        const SizedBox(height: 16),
                        AppTextField(controller: _companyAddress, label: 'Alamat Kantor', validator: _required, prefixIcon: Icons.location_on_outlined),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2))
                          : Text(_currentStep == 0 ? 'Selanjutnya' : 'Daftar Sekarang', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_currentStep == 1) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: const Text('Kembali ke Data Pribadi', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}