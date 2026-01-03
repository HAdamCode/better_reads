import 'package:flutter/material.dart';
import '../utils/theme.dart';

class WoodenShelfDivider extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;
  final bool isTop;

  const WoodenShelfDivider({
    super.key,
    this.height = 14,
    this.margin,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? (isTop ? const EdgeInsets.only(bottom: 0) : const EdgeInsets.only(top: 0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isTop
              ? [
                  AppTheme.primaryColor.withValues(alpha: 0.8), // Darker top edge
                  AppTheme.secondaryColor, // Main wood color
                  AppTheme.secondaryColor.withValues(alpha: 0.9), // Light bottom
                ]
              : [
                  AppTheme.secondaryColor.withValues(alpha: 0.9), // Light wood highlight
                  AppTheme.secondaryColor, // Main wood color
                  AppTheme.primaryColor.withValues(alpha: 0.8), // Darker bottom edge
                ],
          stops: const [0.0, 0.3, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isTop ? 0.3 : 0.25),
            offset: Offset(0, isTop ? 3 : 3),
            blurRadius: 4,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isTop
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : AppTheme.secondaryColor.withValues(alpha: 0.6),
            width: 1,
          ),
          bottom: BorderSide(
            color: isTop
                ? AppTheme.secondaryColor.withValues(alpha: 0.6)
                : AppTheme.primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: CustomPaint(
        painter: _HorizontalWoodGrainPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _HorizontalWoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Main wood grain lines - darker streaks
    final darkGrainY = [3.0, 7.0, 11.0];
    paint.color = const Color(0xFF5D4020).withValues(alpha: 0.5);
    paint.strokeWidth = 1.5;

    for (final y in darkGrainY) {
      final path = Path();
      path.moveTo(0, y);

      // Create natural wavy grain pattern
      for (double x = 0; x < size.width; x += 15) {
        final wave = (x % 45 < 15) ? 0.8 : (x % 45 < 30) ? -0.5 : 0.3;
        path.quadraticBezierTo(
          x + 7.5, y + wave,
          x + 15, y + (wave * 0.5),
        );
      }
      canvas.drawPath(path, paint);
    }

    // Lighter grain highlights
    paint.color = const Color(0xFFE8D4B8).withValues(alpha: 0.4);
    paint.strokeWidth = 1.0;
    final lightGrainY = [5.0, 9.0];

    for (final y in lightGrainY) {
      final path = Path();
      path.moveTo(0, y);

      for (double x = 0; x < size.width; x += 20) {
        final wave = (x % 40 < 20) ? 0.6 : -0.4;
        path.quadraticBezierTo(
          x + 10, y + wave,
          x + 20, y - (wave * 0.3),
        );
      }
      canvas.drawPath(path, paint);
    }

    // Fine grain detail lines
    paint.color = const Color(0xFF4A3010).withValues(alpha: 0.35);
    paint.strokeWidth = 0.5;
    for (double y = 2; y < size.height - 2; y += 2.5) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 25) {
        final wobble = ((x + y * 7) % 50 < 25) ? 0.3 : -0.3;
        path.lineTo(x + 25, y + wobble);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
