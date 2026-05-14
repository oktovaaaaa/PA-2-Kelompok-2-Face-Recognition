import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/error_mapper.dart';
import 'splash_gate.dart';
import '../../../common/widgets/wavy_background.dart';
import '../../../common/widgets/app_dialog.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/services/notification_service.dart';

class OtpLoginScreen extends StatefulWidget {
  final String email;
  const OtpLoginScreen({super.key, required this.email});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _repo = AuthRepository();
  final _otp = TextEditingController();
  bool _loading = false;

  int _resendTimer = 0;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startTimer(); // Mulai timer otomatis saat masuk halaman
  }

  void _startTimer() {
    setState(() => _resendTimer = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendTimer--);
      return _resendTimer > 0;
    });
  }

  Future<void> _resend() async {
    if (_resendTimer > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await _repo.sendOtp(widget.email);
      if (mounted) {
        AppDialog.showSuccess(context, 'OTP baru telah dikirim ke email Anda');
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showError(context, 'Gagal mengirim ulang OTP: ${ErrorMapper.map(e)}');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      await _repo.verifyLoginOtp(
        email: widget.email,
        code: _otp.text.trim(),
      );

      if (!mounted) return;
      
      // Sync FCM token setelah login berhasil
      NotificationService.syncToken();
      
      // Delegasikan ke SplashGate agar routing handling menjadi seragam (admin maupun employee)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashGate()),
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


  @override
  Widget build(BuildContext context) {
    return WavyBackground(
      isAuth: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E3A8A), size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 8), // Padding atas minimal
              // Illustration from assets
              Image.asset(
                'assets/images/videntiotp.png',
                height: 320, // Sedikit diperkecil agar pas 1 layar
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.mark_email_read_rounded, color: Color(0xFF1E3A8A), size: 100),
              ),
              // Jarak ke kartu dihapus sama sekali agar pas di bawah gambar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24), // Padding vertikal kartu dikurangi
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Verifikasi OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24, // Sedikit dikecilkan
                        fontWeight: FontWeight.w900, 
                        color: Color(0xFF1E3A8A), 
                        letterSpacing: 0.5
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masukkan kode verifikasi yang telah kami kirimkan ke email:\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12, // Sedikit dikecilkan
                        color: Colors.black54, 
                        height: 1.4,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    const SizedBox(height: 24), // Dirapatkan dari 32
                    Pinput(
                      controller: _otp,
                      length: 6,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      defaultPinTheme: PinTheme(
                        width: 44, // Dipersempit agar muat di layar kecil
                        height: 52,
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 44,
                        height: 52,
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF2563EB), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // Dirapatkan dari 32
                    SizedBox(
                      width: double.infinity,
                      height: 52, // Sedikit diperpendek
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _loading ? null : _verify,
                        child: _loading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Verifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16), // Dirapatkan dari 24
                    TextButton(
                      onPressed: (_resendTimer > 0 || _resending) ? null : _resend,
                      child: Column(
                        children: [
                          Text(
                            'Belum mendapatkan kode?',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _resendTimer > 0 
                                ? 'Kirim ulang dalam ${_resendTimer}s' 
                                : 'Kirim ulang',
                            style: TextStyle(
                              color: _resendTimer > 0 ? Colors.grey : const Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20), // Jarak bawah minimal agar tetap melayang



            ],
          ),
        ),
      ),
    );
  }
}