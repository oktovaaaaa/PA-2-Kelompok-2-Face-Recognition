import 'package:flutter/material.dart';
import '../../../admin/presentation/screens/login_screen.dart';
import 'register_choice_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  
  // Wave Animations
  late Animation<Offset> _topWaveAnimation;
  late Animation<Offset> _bottomWaveAnimation;

  // Sphere Animations
  late Animation<Offset> _sphere1Animation;
  late Animation<Offset> _sphere2Animation;
  late Animation<Offset> _sphere3Animation;
  
  // Content Animations
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<Offset> _buttonPanelAnimation;
  late Animation<double> _panelFadeAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 1. Waves Slide In (0.0 - 0.6)
    _topWaveAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );
    _bottomWaveAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic)),
    );

    // 2. Spheres Slide In (0.1 - 0.7)
    _sphere1Animation = Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.5, curve: Curves.easeOutCubic)),
    );
    _sphere2Animation = Tween<Offset>(begin: const Offset(1.5, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic)),
    );
    _sphere3Animation = Tween<Offset>(begin: const Offset(-1, -1.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)),
    );

    // 3. Content (Logo & Text) (0.4 - 0.9)
    _contentFadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.9, curve: Curves.elasticOut)),
    );
    _contentSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic)),
    );

    // 4. Button Panel Slide Up (0.6 - 1.0)
    _buttonPanelAnimation = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack)),
    );
    _panelFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.6, 0.8, curve: Curves.easeIn)),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Static)
          Container(
            width: double.infinity, height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Animated Background Waves (Corrected Positioned hierarchy)
          Positioned.fill(
            child: SlideTransition(
              position: _topWaveAnimation,
              child: CustomPaint(painter: _WavyTopPainter()),
            ),
          ),
          Positioned.fill(
            child: SlideTransition(
              position: _bottomWaveAnimation,
              child: CustomPaint(painter: _WavyBottomPainter()),
            ),
          ),
          
          // Animated Background Spheres
          Positioned(
            left: -50, bottom: 40,
            child: SlideTransition(
              position: _sphere1Animation,
              child: _buildSphere(size: 160, colors: [const Color(0xFF1D4ED8), const Color(0xFF1E3A8A)], blur: 30),
            ),
          ),
          Positioned(
            right: -20, top: 100,
            child: SlideTransition(
              position: _sphere2Animation,
              child: _buildSphere(size: 100, colors: [Colors.blue.shade300, const Color(0xFF2563EB)], blur: 20),
            ),
          ),
          Positioned(
            left: -40, top: -20,
            child: SlideTransition(
              position: _sphere3Animation,
              child: _buildSphere(size: 120, colors: [const Color(0xFF0F172A), const Color(0xFF1E3A8A)], blur: 40),
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  Expanded(
                    child: FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: SlideTransition(
                        position: _contentSlideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/videnti.png',
                                    width: 180, height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person_search_rounded, size: 100, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'VIDENTI',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2.0),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Absensi cerdas dengan\nteknologi pemindaian wajah.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom Action Panel
                  FadeTransition(
                    opacity: _panelFadeAnimation,
                    child: SlideTransition(
                      position: _buttonPanelAnimation,
                      child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20))],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity, height: 58,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                              child: const Text('Masuk Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Belum memiliki akun? ', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterChoiceScreen())),
                                child: const Text('Daftar', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSphere({required double size, required List<Color> colors, required double blur}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(color: colors.last.withOpacity(0.5), blurRadius: blur, offset: const Offset(10, 10)),
          BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: blur / 2, offset: const Offset(-5, -5)),
        ],
      ),
    );
  }
}

class _WavyTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.45, size.width * 0.5, size.height * 0.35);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.25, size.width, size.height * 0.4);
    path.lineTo(size.width, 0); path.lineTo(0, 0); path.close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.2), const Color(0xFF3B82F6).withOpacity(0.1)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _WavyBottomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.6, size.width * 0.4, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.9, size.width, size.height * 0.65);
    path.lineTo(size.width, size.height); path.lineTo(0, size.height); path.close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF0F172A).withOpacity(0.4), const Color(0xFF1E3A8A).withOpacity(0.2)],
        begin: Alignment.bottomLeft, end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}