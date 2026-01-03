import 'package:flutter/material.dart';
import '../utils/theme.dart';

class WoodenShelfDivider extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;

  const WoodenShelfDivider({
    super.key,
    this.height = 14,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.secondaryColor.withValues(alpha: 0.9), // Light wood highlight
            AppTheme.secondaryColor, // Main wood color
            AppTheme.primaryColor.withValues(alpha: 0.8), // Darker bottom edge
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppTheme.secondaryColor.withValues(alpha: 0.6),
            width: 1,
          ),
          bottom: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
    );
  }
}
