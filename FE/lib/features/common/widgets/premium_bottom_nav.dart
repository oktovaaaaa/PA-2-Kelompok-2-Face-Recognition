// lib/features/common/widgets/premium_bottom_nav.dart

import 'package:flutter/material.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color activeColor;
  final Color inactiveColor;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor = const Color(0xFF3B82F6),
    this.inactiveColor = const Color(0xFF94A3B8),
  });

  @override
  Widget build(BuildContext context) {
    // Expected items: 4 (2 left, 2 right) + 1 Center Home (Index 0)
    // Layout indices: [1, 2] | [0 (Home)] | [3, 4]
    
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 90),
            painter: BNBCustomPainter(),
          ),
          Center(
            heightFactor: 0.6,
            child: FloatingActionButton(
              backgroundColor: activeColor,
              elevation: 4,
              onPressed: () => onTap(0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
            ),
          ),
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildItem(1),
                _buildItem(2),
                const SizedBox(width: 60), // Space for FAB
                _buildItem(3),
                _buildItem(4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index) {
    if (index >= items.length) return const Spacer();
    final item = items[index];
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Icon(
              item.icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;
  const BottomNavItem({required this.icon, required this.label});
}

class BNBCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 0);
    
    double center = size.width / 2;
    double notchWidth = 80;
    double curveDepth = 35;
    
    path.lineTo(center - notchWidth, 0);
    
    path.quadraticBezierTo(
      center - (notchWidth * 0.6), 0,
      center - (notchWidth * 0.4), curveDepth * 0.4,
    );
    
    path.arcToPoint(
      Offset(center + (notchWidth * 0.4), curveDepth * 0.4),
      radius: const Radius.circular(35),
      clockwise: false,
    );
    
    path.quadraticBezierTo(
      center + (notchWidth * 0.6), 0,
      center + notchWidth, 0,
    );
    
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.1), 12, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
