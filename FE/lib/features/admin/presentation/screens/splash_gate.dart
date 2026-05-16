import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/storage/session_storage.dart';
import 'admin_dashboard_screen.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import '../../../employee/presentation/screens/employee_dashboard_screen.dart';
import 'login_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with TickerProviderStateMixin {
  bool _loading = true;
  Widget _target = const SizedBox();
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _check();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    // Smooth progress simulation
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (mounted) setState(() => _progress = i / 100);
    }

    final token = await SessionStorage.getToken();
    final role = await SessionStorage.getRole();

    if (token != null && token.isNotEmpty) {
      final userId = await SessionStorage.getUserId();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            auth.login({
              'id': userId,
              'role': role?.toUpperCase(),
            });
          }
        });
      }
      if (role == 'ADMIN' || role == 'admin') {
        _target = const AdminDashboardScreen();
      } else if (role == 'employee' || role == 'EMPLOYEE') {
        _target = const EmployeeDashboardScreen();
      } else {
        _target = const LoginScreen(pinOnlyMode: true);
      }
    } else {
      _target = const LandingScreen();
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Top Premium Waves
            Positioned(
              top: 0, left: 0, right: 0,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 200),
                painter: TopPremiumWavePainter(),
              ),
            ),

            // High Quality Organic Waves
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 320),
                painter: PremiumWavePainter(),
              ),
            ),
            
            // Central Branding
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle Pulse/Ripple Rings (3D Perspective)
                      AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, _) => CustomPaint(
                          size: const Size(200, 200),
                          painter: LogoRipplePainter(_rippleAnimation.value),
                        ),
                      ),
                      // Logo
                      Hero(
                        tag: 'logo',
                        child: Image.asset(
                          'assets/images/videnti.png',
                          width: 140, height: 140,
                          errorBuilder: (_, __, ___) => const Icon(Icons.face_retouching_natural_rounded, size: 100, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'videnti',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF003AB3),
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),

            // Minimalist Loading Section
            Positioned(
              bottom: 100,
              left: 50, right: 50,
              child: Column(
                children: [
                  Text(
                    'Memuat',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF003AB3).withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _target;
  }
}

class LogoRipplePainter extends CustomPainter {
  final double animationValue;

  LogoRipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Geser pusat lebih jauh ke bawah logo agar tidak bertumpukan
    final center = Offset(size.width / 2, size.height / 2 + 65); 
    
    for (int i = 0; i < 3; i++) {
      final double progress = (animationValue + (i / 3)) % 1.0;
      final double opacity = (1.0 - progress) * 0.4; // Opasitas lebih tebal
      final double scale = progress * 1.8;

      // Gunakan Fill alih-alih Stroke untuk warna yang lebih tebal/berisi
      final paint = Paint()
        ..color = const Color(0xFF2563EB).withOpacity(opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5); // Haluskan pinggirnya

      final Rect rect = Rect.fromCenter(
        center: center,
        width: 160 * scale,   
        height: 45 * scale,   
      );
      
      canvas.drawOval(rect, paint);
      
      // Tambahkan pendaran cahaya (Glow) ekstra di tengah
      if (i == 0) {
        final glowPaint = Paint()
          ..color = const Color(0xFF2563EB).withOpacity(opacity * 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 80, height: 25),
          glowPaint
        );
      }
    }
  }

  @override
  bool shouldRepaint(LogoRipplePainter oldDelegate) => true;
}

class TopPremiumWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    
    // Layer 1
    paint.color = const Color(0xFFDBEAFE).withOpacity(0.3);
    var path1 = Path();
    path1.lineTo(0, size.height * 0.7);
    path1.cubicTo(size.width * 0.3, size.height * 0.9, size.width * 0.6, size.height * 0.5, size.width, size.height * 0.6);
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint);

    // Layer 2
    paint.color = const Color(0xFFEFF6FF).withOpacity(0.5);
    var path2 = Path();
    path2.lineTo(0, size.height * 0.5);
    path2.cubicTo(size.width * 0.4, size.height * 0.7, size.width * 0.7, size.height * 0.3, size.width, size.height * 0.4);
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint);

    // Layer 3
    paint.color = const Color(0xFFF8FAFC).withOpacity(0.4);
    var path3 = Path();
    path3.lineTo(0, size.height * 0.3);
    path3.cubicTo(size.width * 0.3, size.height * 0.4, size.width * 0.7, size.height * 0.2, size.width, size.height * 0.2);
    path3.lineTo(size.width, 0);
    path3.close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(TopPremiumWavePainter oldDelegate) => false;
}

class PremiumWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    
    // Bottom Layer 1
    paint.color = const Color(0xFFDBEAFE).withOpacity(0.4);
    var path1 = Path();
    path1.moveTo(0, size.height * 0.6);
    path1.cubicTo(size.width * 0.3, size.height * 0.4, size.width * 0.7, size.height * 0.8, size.width, size.height * 0.5);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    // Bottom Layer 2
    paint.color = const Color(0xFFEFF6FF).withOpacity(0.6);
    var path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    path2.cubicTo(size.width * 0.3, size.height * 0.6, size.width * 0.7, size.height * 0.9, size.width, size.height * 0.7);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);

    // Bottom Layer 3
    paint.color = const Color(0xFFF0F9FF).withOpacity(0.8);
    var path3 = Path();
    path3.moveTo(0, size.height * 0.9);
    path3.cubicTo(size.width * 0.4, size.height * 0.8, size.width * 0.7, size.height * 1.0, size.width, size.height * 0.85);
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}