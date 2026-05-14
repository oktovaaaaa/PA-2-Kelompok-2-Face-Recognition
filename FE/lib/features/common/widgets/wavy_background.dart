import 'package:flutter/material.dart';

class WavyBackground extends StatelessWidget {
  final Widget child;
  final bool isAuth;

  const WavyBackground({
    super.key,
    required this.child,
    this.isAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Top Premium Waves
          Positioned(
            top: 0, left: 0, right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 220),
              painter: _TopOrganicWavePainter(),
            ),
          ),

          // Bottom Premium Waves
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 320),
              painter: _BottomOrganicWavePainter(),
            ),
          ),
          
          // Main Content
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopOrganicWavePainter extends CustomPainter {
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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BottomOrganicWavePainter extends CustomPainter {
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
