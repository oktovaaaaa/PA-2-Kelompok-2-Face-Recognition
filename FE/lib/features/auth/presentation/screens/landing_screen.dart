import 'package:flutter/material.dart';
import '../../../admin/presentation/screens/login_screen.dart';
import 'register_choice_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Premium Waves
          Positioned(
            top: 0, left: 0, right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 220),
              painter: TopPremiumWavePainter(),
            ),
          ),

          // Bottom Premium Waves
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 350),
              painter: WelcomePremiumWavePainter(),
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 4), 
                  
                  // Text Section
                  const Text(
                    'Selamat datang di',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF003AB3),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Logo
                  Image.asset(
                    'assets/images/videnti.png',
                    width: 120, height: 120,
                    errorBuilder: (_, __, ___) => const Icon(Icons.face_retouching_natural_rounded, size: 80, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Videnti',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      letterSpacing: 2, // Jarak huruf lebih lega
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Solusi cerdas untuk\nmanajemen absensi yang lebih baik',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black45,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const Spacer(flex: 3),

                  // Action Buttons (Pill Shaped)
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003AB3),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 4,
                        shadowColor: const Color(0xFF003AB3).withOpacity(0.4),
                      ),
                      child: const Text('Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Versi 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopPremiumWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    
    // Layer 1: Deepest/Darkest
    paint.color = const Color(0xFFDBEAFE).withOpacity(0.3);
    var path1 = Path();
    path1.lineTo(0, size.height * 0.7);
    path1.quadraticBezierTo(size.width * 0.3, size.height * 0.95, size.width, size.height * 0.6);
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint);

    // Layer 2: Middle
    paint.color = const Color(0xFFEFF6FF).withOpacity(0.5);
    var path2 = Path();
    path2.lineTo(0, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.8, size.width, size.height * 0.4);
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint);

    // Layer 3: Top/Lightest
    paint.color = const Color(0xFFF8FAFC).withOpacity(0.4);
    var path3 = Path();
    path3.lineTo(0, size.height * 0.3);
    path3.quadraticBezierTo(size.width * 0.7, size.height * 0.5, size.width, size.height * 0.2);
    path3.lineTo(size.width, 0);
    path3.close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WelcomePremiumWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    
    // Bottom Layer 1
    paint.color = const Color(0xFFDBEAFE).withOpacity(0.4);
    var path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    path1.cubicTo(size.width * 0.3, size.height * 0.5, size.width * 0.6, size.height * 0.95, size.width, size.height * 0.6);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    // Bottom Layer 2
    paint.color = const Color(0xFFEFF6FF).withOpacity(0.6);
    var path2 = Path();
    path2.moveTo(0, size.height * 0.85);
    path2.cubicTo(size.width * 0.25, size.height * 0.7, size.width * 0.5, size.height * 1.0, size.width, size.height * 0.8);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);

    // Bottom Layer 3
    paint.color = const Color(0xFFF0F9FF).withOpacity(0.8);
    var path3 = Path();
    path3.moveTo(0, size.height * 0.95);
    path3.cubicTo(size.width * 0.4, size.height * 0.85, size.width * 0.7, size.height * 1.05, size.width, size.height * 0.95);
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}