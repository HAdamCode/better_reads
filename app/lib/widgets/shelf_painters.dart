import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shelf_theme.dart';

/// Vertical wood grain painter for side panels
class WoodGrainPainter extends CustomPainter {
  final List<Color>? grainColors;
  final Color? highlightColor;

  WoodGrainPainter({this.grainColors, this.highlightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    final colors = grainColors ??
        [
          const Color(0xFF4A3222),
          const Color(0xFF3D2817),
          const Color(0xFF5D3A1A),
          const Color(0xFF4A3222),
        ];

    // Vertical grain streaks
    final grainPositions = [2.0, 5.0, 8.0, 11.0];

    for (int i = 0; i < grainPositions.length && i < colors.length; i++) {
      paint.color = colors[i].withValues(alpha: 0.6);
      paint.strokeWidth = 1.5;

      final path = Path();
      final x = grainPositions[i];
      path.moveTo(x, 0);

      for (double y = 0; y < size.height; y += 20) {
        final wobble = (y % 40 < 20) ? 0.5 : -0.5;
        path.lineTo(x + wobble, y + 20);
      }

      canvas.drawPath(path, paint);
    }

    // Darker vertical accent lines
    paint.color = const Color(0xFF2D1A0A).withValues(alpha: 0.3);
    paint.strokeWidth = 0.5;
    canvas.drawLine(Offset(3, 0), Offset(3, size.height), paint);
    canvas.drawLine(Offset(9, 0), Offset(9, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Horizontal wood grain painter for shelf dividers
class HorizontalWoodGrainPainter extends CustomPainter {
  final List<Color>? grainColors;
  final Color? highlightColor;

  HorizontalWoodGrainPainter({this.grainColors, this.highlightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Main wood grain lines - darker streaks
    final darkGrainY = [3.0, 7.0, 11.0];
    paint.color = const Color(0xFF5D4020).withValues(alpha: 0.5);
    paint.strokeWidth = 1.5;

    for (final y in darkGrainY) {
      if (y >= size.height) continue;
      final path = Path();
      path.moveTo(0, y);

      for (double x = 0; x < size.width; x += 15) {
        final wave = (x % 45 < 15) ? 0.8 : (x % 45 < 30) ? -0.5 : 0.3;
        path.quadraticBezierTo(
          x + 7.5,
          y + wave,
          x + 15,
          y + (wave * 0.5),
        );
      }
      canvas.drawPath(path, paint);
    }

    // Lighter grain highlights
    final highlight = highlightColor ?? const Color(0xFFE8D4B8);
    paint.color = highlight.withValues(alpha: 0.4);
    paint.strokeWidth = 1.0;
    final lightGrainY = [5.0, 9.0];

    for (final y in lightGrainY) {
      if (y >= size.height) continue;
      final path = Path();
      path.moveTo(0, y);

      for (double x = 0; x < size.width; x += 20) {
        final wave = (x % 40 < 20) ? 0.6 : -0.4;
        path.quadraticBezierTo(
          x + 10,
          y + wave,
          x + 20,
          y - (wave * 0.3),
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

/// Stone texture painter for fantasy side panels
class StoneTexturePainter extends CustomPainter {
  final Color? glowColor;
  final Color? starColor;
  final int seed;

  StoneTexturePainter({this.glowColor, this.starColor, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Vertical crack lines (irregular stone texture)
    final crackPositions = [3.0, 7.0, 11.0, 14.0];
    final random = math.Random(seed); // Use provided seed for variation

    for (final x in crackPositions) {
      if (x >= size.width) continue;
      paint.color = const Color(0xFF1A1620).withValues(alpha: 0.4 + random.nextDouble() * 0.2);
      paint.strokeWidth = 0.8 + random.nextDouble() * 0.5;

      final path = Path();
      path.moveTo(x, 0);

      double currentX = x;
      for (double y = 0; y < size.height; y += 15) {
        final drift = (random.nextDouble() - 0.5) * 2;
        currentX = (currentX + drift).clamp(0, size.width);
        path.lineTo(currentX, y + 15);
      }

      canvas.drawPath(path, paint);
    }

    // Subtle horizontal crack accents
    paint.color = const Color(0xFF1A1620).withValues(alpha: 0.25);
    paint.strokeWidth = 0.5;
    for (double y = 25; y < size.height; y += 40 + random.nextDouble() * 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * (0.3 + random.nextDouble() * 0.4), y + random.nextDouble() * 2),
        paint,
      );
    }

    // Inner edge magical glow
    if (glowColor != null) {
      paint.color = glowColor!.withValues(alpha: 0.15);
      paint.strokeWidth = 2;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(Offset(1, 0), Offset(1, size.height), paint);
    }

    // Twinkling stars/sparkles scattered on side panel
    if (starColor != null) {
      _drawSparkles(canvas, size, starColor!, random);
    }
  }

  void _drawSparkles(Canvas canvas, Size size, Color color, math.Random random) {
    final sparkleRandom = math.Random(seed * 3 + 77); // Vary based on seed
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw small twinkling stars
    for (int i = 0; i < 5; i++) {
      final x = 2 + sparkleRandom.nextDouble() * (size.width - 4);
      final y = 20 + sparkleRandom.nextDouble() * (size.height - 40);
      final brightness = 0.4 + sparkleRandom.nextDouble() * 0.6;
      final starSize = 1.0 + sparkleRandom.nextDouble() * 1.5;

      // Star core (bright)
      paint.color = color.withValues(alpha: brightness);
      canvas.drawCircle(Offset(x, y), starSize * 0.5, paint);

      // Star glow (softer)
      paint.color = color.withValues(alpha: brightness * 0.3);
      canvas.drawCircle(Offset(x, y), starSize, paint);

      // Draw tiny cross sparkle
      paint.color = color.withValues(alpha: brightness * 0.7);
      paint.strokeWidth = 0.5;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x - starSize, y), Offset(x + starSize, y), paint);
      canvas.drawLine(Offset(x, y - starSize), Offset(x, y + starSize), paint);
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rune pattern painter for fantasy shelf dividers
class RunePatternPainter extends CustomPainter {
  final Color? runeColor;
  final Color? glowColor;
  final Color? starColor;
  final int seed;

  RunePatternPainter({this.runeColor, this.glowColor, this.starColor, this.seed = 123});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rune = runeColor ?? const Color(0xFFD4AF37);

    // Base horizontal lines
    paint.color = const Color(0xFF1A1620).withValues(alpha: 0.3);
    paint.strokeWidth = 0.5;
    paint.style = PaintingStyle.stroke;

    for (double y = 3; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Decorative rune-like patterns
    paint.color = rune.withValues(alpha: 0.3);
    paint.strokeWidth = 1.0;

    final random = math.Random(seed); // Use provided seed for variation
    final runePositions = <double>[];
    double x = 30;
    while (x < size.width - 30) {
      runePositions.add(x);
      _drawRune(canvas, paint, x, size.height / 2, size.height * 0.5);
      x += 60 + random.nextDouble() * 40;
    }

    // Draw twinkling stars between runes
    if (starColor != null) {
      _drawStarsBetweenRunes(canvas, size, runePositions, starColor!);
    }

    // Subtle connecting lines between runes
    paint.color = rune.withValues(alpha: 0.15);
    paint.strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Glow effect on edges
    if (glowColor != null) {
      final glowPaint = Paint()
        ..color = glowColor!.withValues(alpha: 0.1)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, 1), Offset(size.width, 1), glowPaint);
      canvas.drawLine(
        Offset(0, size.height - 1),
        Offset(size.width, size.height - 1),
        glowPaint,
      );
    }
  }

  void _drawStarsBetweenRunes(Canvas canvas, Size size, List<double> runePositions, Color color) {
    final starRandom = math.Random(seed * 7 + 456); // Vary based on seed
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw stars between and around runes
    for (int i = 0; i < runePositions.length + 1; i++) {
      final startX = i == 0 ? 5.0 : runePositions[i - 1] + 15;
      final endX = i >= runePositions.length ? size.width - 5 : runePositions[i] - 15;

      if (endX - startX < 20) continue;

      // Place 1-2 stars in this gap
      final numStars = 1 + starRandom.nextInt(2);
      for (int j = 0; j < numStars; j++) {
        final x = startX + starRandom.nextDouble() * (endX - startX);
        final y = 3 + starRandom.nextDouble() * (size.height - 6);
        final brightness = 0.5 + starRandom.nextDouble() * 0.5;
        final starSize = 1.5 + starRandom.nextDouble() * 2.0;

        // Draw 4-point star shape
        _drawFourPointStar(canvas, paint, x, y, starSize, color, brightness);
      }
    }
  }

  void _drawFourPointStar(Canvas canvas, Paint paint, double cx, double cy,
      double size, Color color, double brightness) {
    // Bright core
    paint.color = color.withValues(alpha: brightness);
    canvas.drawCircle(Offset(cx, cy), size * 0.3, paint);

    // Outer glow
    paint.color = color.withValues(alpha: brightness * 0.25);
    canvas.drawCircle(Offset(cx, cy), size * 0.8, paint);

    // Cross sparkle rays
    paint.color = color.withValues(alpha: brightness * 0.8);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.8;

    // Horizontal ray
    canvas.drawLine(Offset(cx - size, cy), Offset(cx + size, cy), paint);
    // Vertical ray
    canvas.drawLine(Offset(cx, cy - size), Offset(cx, cy + size), paint);
    // Diagonal rays (shorter)
    canvas.drawLine(Offset(cx - size * 0.5, cy - size * 0.5),
                    Offset(cx + size * 0.5, cy + size * 0.5), paint);
    canvas.drawLine(Offset(cx + size * 0.5, cy - size * 0.5),
                    Offset(cx - size * 0.5, cy + size * 0.5), paint);

    paint.style = PaintingStyle.fill;
  }

  void _drawRune(Canvas canvas, Paint paint, double cx, double cy, double runeSize) {
    final random = math.Random(cx.toInt());
    final runeType = random.nextInt(4);

    final path = Path();
    final halfSize = runeSize / 2;

    switch (runeType) {
      case 0: // Diamond rune
        path.moveTo(cx, cy - halfSize);
        path.lineTo(cx + halfSize * 0.6, cy);
        path.lineTo(cx, cy + halfSize);
        path.lineTo(cx - halfSize * 0.6, cy);
        path.close();
        break;
      case 1: // Cross rune
        path.moveTo(cx - halfSize * 0.4, cy);
        path.lineTo(cx + halfSize * 0.4, cy);
        path.moveTo(cx, cy - halfSize);
        path.lineTo(cx, cy + halfSize);
        break;
      case 2: // Triangle rune
        path.moveTo(cx, cy - halfSize);
        path.lineTo(cx + halfSize * 0.5, cy + halfSize * 0.6);
        path.lineTo(cx - halfSize * 0.5, cy + halfSize * 0.6);
        path.close();
        break;
      case 3: // Circle with dot
        canvas.drawCircle(Offset(cx, cy), halfSize * 0.4, paint);
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), halfSize * 0.1, paint);
        paint.style = PaintingStyle.stroke;
        return;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vertical filigree/scrollwork painter for romance side panels
class FiligreeVerticalPainter extends CustomPainter {
  final Color? baseColor;
  final Color? accentColor;
  final int seed;

  FiligreeVerticalPainter({this.baseColor, this.accentColor, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final base = baseColor ?? const Color(0xFFB76E79);
    final accent = accentColor ?? const Color(0xFFD4AF37);
    final random = math.Random(seed);

    // Vertical scrollwork lines
    paint.color = base.withValues(alpha: 0.4);
    paint.strokeWidth = 1.0;

    // Draw elegant S-curves
    for (double y = 10; y < size.height - 10; y += 25) {
      final path = Path();
      final startX = 3 + random.nextDouble() * 2;
      path.moveTo(startX, y);
      path.cubicTo(
        size.width * 0.7, y + 8,
        size.width * 0.3, y + 17,
        startX + 2, y + 25,
      );
      canvas.drawPath(path, paint);
    }

    // Gold accent dots/flourishes
    paint.color = accent.withValues(alpha: 0.5);
    paint.style = PaintingStyle.fill;
    for (double y = 15; y < size.height - 15; y += 35) {
      final x = 5 + random.nextDouble() * 4;
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Horizontal filigree/scrollwork painter for romance shelf dividers
class FiligreeHorizontalPainter extends CustomPainter {
  final Color? baseColor;
  final Color? accentColor;
  final int seed;

  FiligreeHorizontalPainter({this.baseColor, this.accentColor, this.seed = 123});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final base = baseColor ?? const Color(0xFFB76E79);
    final accent = accentColor ?? const Color(0xFFD4AF37);
    final random = math.Random(seed);

    // Horizontal scrollwork pattern
    paint.color = base.withValues(alpha: 0.35);
    paint.strokeWidth = 0.8;

    // Draw elegant horizontal curves
    final midY = size.height / 2;
    for (double x = 20; x < size.width - 20; x += 40) {
      // Upper flourish
      final path = Path();
      path.moveTo(x, midY);
      path.cubicTo(
        x + 10, midY - 4,
        x + 30, midY - 4,
        x + 40, midY,
      );
      canvas.drawPath(path, paint);

      // Lower mirror flourish
      final pathLower = Path();
      pathLower.moveTo(x + 20, midY);
      pathLower.cubicTo(
        x + 30, midY + 3,
        x + 50, midY + 3,
        x + 60, midY,
      );
      canvas.drawPath(pathLower, paint);
    }

    // Gold accent diamonds
    paint.color = accent.withValues(alpha: 0.45);
    paint.style = PaintingStyle.fill;
    for (double x = 50; x < size.width - 50; x += 80 + random.nextDouble() * 30) {
      _drawSmallDiamond(canvas, paint, x, midY, 2.5);
    }

    // Thin border lines
    paint.color = base.withValues(alpha: 0.25);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;
    canvas.drawLine(Offset(0, 2), Offset(size.width, 2), paint);
    canvas.drawLine(Offset(0, size.height - 2), Offset(size.width, size.height - 2), paint);
  }

  void _drawSmallDiamond(Canvas canvas, Paint paint, double cx, double cy, double size) {
    final path = Path();
    path.moveTo(cx, cy - size);
    path.lineTo(cx + size * 0.6, cy);
    path.lineTo(cx, cy + size);
    path.lineTo(cx - size * 0.6, cy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Factory to get the appropriate painter based on theme
class ShelfPainterFactory {
  static CustomPainter? getSidePanelPainter(ShelfTheme theme, {int seed = 42}) {
    switch (theme.textureType) {
      case ShelfTextureType.none:
        return null;
      case ShelfTextureType.woodGrain:
        return WoodGrainPainter(
          grainColors: theme.grainColors,
          highlightColor: theme.grainHighlightColor,
        );
      case ShelfTextureType.stoneRune:
        return StoneTexturePainter(
          glowColor: theme.accentGlowColor,
          starColor: theme.starAccentColor,
          seed: seed,
        );
      case ShelfTextureType.ornateFiligree:
        return FiligreeVerticalPainter(
          baseColor: theme.sidePanelMiddleColor,
          accentColor: theme.grainHighlightColor,
          seed: seed,
        );
    }
  }

  static CustomPainter? getDividerPainter(ShelfTheme theme, {int seed = 123}) {
    switch (theme.textureType) {
      case ShelfTextureType.none:
        return null;
      case ShelfTextureType.woodGrain:
        return HorizontalWoodGrainPainter(
          grainColors: theme.grainColors,
          highlightColor: theme.grainHighlightColor,
        );
      case ShelfTextureType.stoneRune:
        return RunePatternPainter(
          runeColor: theme.grainHighlightColor,
          glowColor: theme.accentGlowColor,
          starColor: theme.starAccentColor,
          seed: seed,
        );
      case ShelfTextureType.ornateFiligree:
        return FiligreeHorizontalPainter(
          baseColor: theme.dividerMiddleColor,
          accentColor: theme.grainHighlightColor,
          seed: seed,
        );
    }
  }
}
