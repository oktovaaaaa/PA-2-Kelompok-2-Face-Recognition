import 'package:flutter/material.dart';

class FacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    double w = size.width * 0.75;
    double h = size.width * 0.95;
    Rect rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: w,
      height: h,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
