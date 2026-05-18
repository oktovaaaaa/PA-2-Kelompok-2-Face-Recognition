import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/error_mapper.dart';
import 'admin_dashboard_screen.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/wavy_background.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/services/notification_service.dart';
import 'otp_login_screen.dart';
import 'splash_gate.dart';
import '../../../auth/presentation/screens/forgot_password_screen.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import '../../../auth/presentation/screens/register_choice_screen.dart';
import '../../../common/widgets/app_dialog.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool pinOnlyMode;
  const LoginScreen({super.key, this.pinOnlyMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _repo = AuthRepository();
  final _localAuth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pin = TextEditingController();

  bool _loading = false;
  bool _canCheckBiometrics = false;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      _canCheckBiometrics = isSupported && canCheck;
      
      if (mounted) setState(() {});
      
      if (widget.pinOnlyMode && _canCheckBiometrics) {
        // Beri sedikit jeda agar UI siap
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !authProvider.isSessionLocked) return;
          _authenticateBiometrics();
        });
      }
    } catch (_) {}
  }

  AuthProvider get authProvider => Provider.of<AuthProvider>(context, listen: false);

  Future<void> _authenticateBiometrics() async {
    if (!_canCheckBiometrics || _isUnlocked) return;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan biometrik untuk login cepat',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        setState(() => _isUnlocked = true);
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          authProvider.unlockSession();

          if (widget.pinOnlyMode) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashGate()),
            (_) => false,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _repo.login(
        email: _email.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpLoginScreen(email: _email.text.trim()),
        ),
      );
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      AppDialog.showError(context, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _loading = true);
    try {
      final authData = await _repo.getGoogleAuthData();
      if (authData == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final idToken = authData['idToken']!;
      final email = authData['email']!;

      await _repo.googleLogin(idToken);
      
      if (!mounted) return;
      AppDialog.showInfo(context, 'Login Google diproses, periksa email Anda untuk OTP.');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpLoginScreen(email: email),
        ),
      );
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      AppDialog.showError(context, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Future<void> _loginPin() async {
    if (_isUnlocked) return;
    
    final pinText = _pin.text.trim();
    if (pinText.length != 6) {
      await AppDialog.showError(context, 'PIN harus 6 digit.', useRoot: !widget.pinOnlyMode);
      return;
    }

    setState(() => _loading = true);
    try {
      // Debug log untuk membantu analisa kenapa PIN gagal
      final userId = await SessionStorage.getUserId();
      final deviceId = await SessionStorage.getOrCreateDeviceId();
      print("DEBUG: Attempting PIN login for User: $userId, Device: $deviceId");

      await _repo.loginPin(pinText);
      
      if (!mounted) return;

      // Cek lagi apakah sudah diunlock oleh proses lain (misal biometrik yang paralel)
      if (_isUnlocked) return;
      
      setState(() => _isUnlocked = true);
      
      // Berhasil: Buka sesi
      authProvider.unlockSession();

      if (!widget.pinOnlyMode) {
        NotificationService.syncToken();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashGate()),
          (_) => false,
        );
      }
    } catch (e) {
      if (!mounted || _isUnlocked) return;
      
      final msg = ErrorMapper.map(e);
      
      // Tunggu user menekan "Oke" di dialog sebelum membersihkan PIN
      await AppDialog.showError(context, msg, useRoot: !widget.pinOnlyMode);
      
      if (!mounted) return;
      
      // Hanya hapus PIN jika benar-benar gagal (bukan karena error jaringan/rebuild)
      if (msg.toLowerCase().contains('pin') || msg.toLowerCase().contains('salah') || msg.toLowerCase().contains('tidak valid')) {
        _pin.clear();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;


  @override
  Widget build(BuildContext context) {
    final pinOnly = widget.pinOnlyMode;

    return WavyBackground(
      isAuth: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!pinOnly)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        // Jika root (misal setelah registrasi), panggil LandingScreen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => LandingScreen()),
                          (_) => false,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E3A8A), size: 20),
                    ),
                  ),
                ),
              if (pinOnly) ...[
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/videntipin.png',
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.lock_person_rounded, color: Color(0xFF1E3A8A), size: 100),
                ),
                const SizedBox(height: 16),
              ] else 
                const SizedBox(height: 32),
                
              Text(
                pinOnly ? 'Login PIN' : 'Selamat Datang!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pinOnly ? 'Masukkan PIN untuk melanjutkan' : 'Masuk ke akun Anda untuk memulai sesi',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: pinOnly
                    ? Column(
                        children: [
                          Pinput(
                            controller: _pin,
                            length: 6,
                            obscureText: true,
                            autofillHints: null,
                            keyboardType: TextInputType.number,
                            onCompleted: (_) => _loginPin(),
                            hapticFeedbackType: HapticFeedbackType.lightImpact,
                            defaultPinTheme: PinTheme(
                              width: 44,
                              height: 52,
                              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 44,
                              height: 52,
                              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFF2563EB), width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_canCheckBiometrics) ...[
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: _authenticateBiometrics,
                              icon: const Icon(Icons.fingerprint, color: Color(0xFF2563EB)),
                              label: const Text('Gunakan Biometrik', style: TextStyle(color: Color(0xFF2563EB))),
                            ),
                          ],
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
                              onPressed: _loginPin,
                              child: _loading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Buka Kunci', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _email,
                              label: 'Alamat Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: _required,
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              controller: _password,
                              label: 'Kata Sandi',
                              obscure: true,
                              validator: _required,
                            ),
                            const SizedBox(height: 24),
                            // Optional: Checkbox Remember Me (visually only for aesthetic)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24, height: 24,
                                      child: Checkbox(
                                        value: true, 
                                        onChanged: (v) {},
                                        activeColor: const Color(0xFF2563EB),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Ingat saya', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Lupa sandi?', 
                                    style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB), // Deep royal blue
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                onPressed: _loginEmail,
                                  child: _loading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade200)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Atau masuk dengan', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade200)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Hapus Facebook & Apple, hanya simpan Google Login di tengah
                            Center(
                              child: _buildSocialBtn(Icons.g_mobiledata, Colors.red, _loading ? null : _loginGoogle),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Belum punya akun? ',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const RegisterChoiceScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Daftar',
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialBtn(IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Image.network(
          'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 38),
        ),
      ),
    );
  }
}