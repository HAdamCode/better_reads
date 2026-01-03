import 'package:flutter/material.dart';
import '../models/shelf_theme.dart';
import 'shelf_painters.dart';

class WoodenShelfDivider extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? margin;
  final bool isTop;
  final ShelfTheme? theme;
  final int seed;

  const WoodenShelfDivider({
    super.key,
    this.height,
    this.margin,
    this.isTop = false,
    this.theme,
    this.seed = 123,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = theme ?? ShelfTheme.classicWood();
    final effectiveHeight = height ?? currentTheme.dividerHeight;

    // For minimalist theme, return a simple thin line
    if (currentTheme.type == ShelfThemeType.minimalist) {
      return Container(
        height: effectiveHeight,
        margin: margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          color: currentTheme.dividerMiddleColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      );
    }

    // For other themes, use gradient and texture
    return Container(
      height: effectiveHeight,
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isTop
              ? [
                  currentTheme.dividerDarkColor.withValues(alpha: 0.8),
                  currentTheme.dividerMiddleColor,
                  currentTheme.dividerLightColor.withValues(alpha: 0.9),
                ]
              : [
                  currentTheme.dividerLightColor.withValues(alpha: 0.9),
                  currentTheme.dividerMiddleColor,
                  currentTheme.dividerDarkColor.withValues(alpha: 0.8),
                ],
          stops: const [0.0, 0.3, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isTop ? 0.3 : 0.25),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isTop
                ? currentTheme.dividerDarkColor.withValues(alpha: 0.5)
                : currentTheme.dividerLightColor.withValues(alpha: 0.6),
            width: 1,
          ),
          bottom: BorderSide(
            color: isTop
                ? currentTheme.dividerLightColor.withValues(alpha: 0.6)
                : currentTheme.dividerDarkColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: CustomPaint(
        painter: ShelfPainterFactory.getDividerPainter(currentTheme, seed: seed),
        size: Size.infinite,
      ),
    );
  }
}
