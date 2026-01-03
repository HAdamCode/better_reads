import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shelf_theme.dart';

/// Vertical wood grain painter for side panels - Rustic library style
class WoodGrainPainter extends CustomPainter {
  final List<Color>? grainColors;
  final Color? highlightColor;
  final int seed;

  WoodGrainPainter({this.grainColors, this.highlightColor, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();

    // Rich rustic color palette
    final baseColors = grainColors ??
        [
          const Color(0xFF3D2517), // Deep walnut
          const Color(0xFF4A2E1C), // Rich brown
          const Color(0xFF5C3A22), // Warm mahogany
          const Color(0xFF4A3222), // Medium brown
          const Color(0xFF6B4423), // Amber brown
        ];

    // Layer 1: Base wood tone gradient
    final baseGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFF3D2517).withValues(alpha: 0.3),
        const Color(0xFF5C3A22).withValues(alpha: 0.2),
        const Color(0xFF3D2517).withValues(alpha: 0.3),
      ],
    );
    paint.shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Layer 2: Multiple grain line layers (5+ for depth)
    paint.style = PaintingStyle.stroke;
    for (int layer = 0; layer < 6; layer++) {
      final layerAlpha = 0.15 + (layer * 0.08);
      final xOffset = 1.5 + (layer * 2.0) + random.nextDouble() * 1.5;

      if (xOffset >= size.width) continue;

      paint.color = baseColors[layer % baseColors.length].withValues(alpha: layerAlpha);
      paint.strokeWidth = 0.5 + random.nextDouble() * 1.0;

      final path = Path();
      path.moveTo(xOffset, 0);

      double currentX = xOffset;
      for (double y = 0; y < size.height; y += 8 + random.nextDouble() * 6) {
        final wobble = (random.nextDouble() - 0.5) * 1.5;
        currentX = (currentX + wobble).clamp(0, size.width);
        path.lineTo(currentX, y);
      }
      path.lineTo(currentX, size.height);

      canvas.drawPath(path, paint);
    }

    // Layer 3: Fine grain detail lines
    paint.color = const Color(0xFF2D1A0A).withValues(alpha: 0.2);
    paint.strokeWidth = 0.3;
    for (double x = 1; x < size.width - 1; x += 1.5 + random.nextDouble()) {
      final path = Path();
      path.moveTo(x, 0);
      for (double y = 0; y < size.height; y += 12) {
        final drift = (random.nextDouble() - 0.5) * 0.8;
        path.lineTo(x + drift, y + 12);
      }
      canvas.drawPath(path, paint);
    }

    // Layer 4: Wood knots (1-2 per panel)
    final numKnots = 1 + random.nextInt(2);
    for (int i = 0; i < numKnots; i++) {
      final knotX = 3 + random.nextDouble() * (size.width - 6);
      final knotY = 30 + random.nextDouble() * (size.height - 60);
      final knotSize = 3 + random.nextDouble() * 4;
      _drawWoodKnot(canvas, knotX, knotY, knotSize, random);
    }

    // Layer 5: Age spots / staining
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final spotX = random.nextDouble() * size.width;
      final spotY = random.nextDouble() * size.height;
      final spotSize = 2 + random.nextDouble() * 4;
      paint.color = const Color(0xFF2D1A0A).withValues(alpha: 0.08 + random.nextDouble() * 0.06);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(spotX, spotY), width: spotSize, height: spotSize * 1.5),
        paint,
      );
    }

    // Layer 6: Edge wear highlights (lighter worn areas)
    paint.color = const Color(0xFFD4A574).withValues(alpha: 0.15);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    // Inner edge highlight (worn from book spines)
    canvas.drawLine(Offset(size.width - 1, 0), Offset(size.width - 1, size.height), paint);

    // Layer 7: Deep shadow on outer edge
    paint.color = const Color(0xFF1A0D05).withValues(alpha: 0.4);
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(0.5, 0), Offset(0.5, size.height), paint);
  }

  void _drawWoodKnot(Canvas canvas, double cx, double cy, double size, math.Random random) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Outer rings (lighter)
    for (double r = size; r > size * 0.3; r -= 0.8) {
      final alpha = 0.15 + (1 - r / size) * 0.25;
      paint.color = Color.lerp(
        const Color(0xFF5C3A22),
        const Color(0xFF2D1A0A),
        1 - r / size,
      )!.withValues(alpha: alpha);
      paint.strokeWidth = 0.4 + random.nextDouble() * 0.3;

      // Slightly irregular oval
      final ovalWidth = r * (0.9 + random.nextDouble() * 0.2);
      final ovalHeight = r * (1.1 + random.nextDouble() * 0.3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: ovalWidth, height: ovalHeight),
        paint,
      );
    }

    // Dark center
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF1A0D05).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(cx, cy), size * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant WoodGrainPainter oldDelegate) => oldDelegate.seed != seed;
}

/// Horizontal wood grain painter for shelf dividers - Rustic library style
class HorizontalWoodGrainPainter extends CustomPainter {
  final List<Color>? grainColors;
  final Color? highlightColor;
  final int seed;

  HorizontalWoodGrainPainter({this.grainColors, this.highlightColor, this.seed = 123});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();

    // Rich rustic color palette
    final darkWood = const Color(0xFF3D2517);
    final mediumWood = const Color(0xFF5C3A22);
    final lightWood = const Color(0xFF7A4A2A);
    final highlight = highlightColor ?? const Color(0xFFD4A574);

    // Layer 1: Base gradient for depth
    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        darkWood.withValues(alpha: 0.2),
        mediumWood.withValues(alpha: 0.15),
        darkWood.withValues(alpha: 0.25),
      ],
    );
    paint.shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Layer 2: Multiple flowing grain lines (6+ layers)
    paint.style = PaintingStyle.stroke;
    for (int layer = 0; layer < 7; layer++) {
      final yBase = 1.5 + (layer * (size.height / 7));
      if (yBase >= size.height) continue;

      final layerAlpha = 0.12 + (layer % 3) * 0.08;
      paint.color = Color.lerp(darkWood, lightWood, layer / 7)!.withValues(alpha: layerAlpha);
      paint.strokeWidth = 0.4 + random.nextDouble() * 0.8;

      final path = Path();
      path.moveTo(0, yBase);

      double currentY = yBase;
      for (double x = 0; x < size.width; x += 10 + random.nextDouble() * 8) {
        final wave = (random.nextDouble() - 0.5) * 1.2;
        currentY = (currentY + wave).clamp(1, size.height - 1);
        path.quadraticBezierTo(
          x + 5,
          currentY + (random.nextDouble() - 0.5) * 0.8,
          x + 10,
          currentY,
        );
      }

      canvas.drawPath(path, paint);
    }

    // Layer 3: Fine grain detail (many thin lines)
    paint.color = const Color(0xFF2D1A0A).withValues(alpha: 0.15);
    paint.strokeWidth = 0.25;
    for (double y = 1; y < size.height - 1; y += 1.0 + random.nextDouble() * 0.5) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 20) {
        final wobble = (random.nextDouble() - 0.5) * 0.5;
        path.lineTo(x + 20, y + wobble);
      }
      canvas.drawPath(path, paint);
    }

    // Layer 4: Occasional wood knots (0-2)
    final numKnots = random.nextInt(3);
    for (int i = 0; i < numKnots; i++) {
      final knotX = 40 + random.nextDouble() * (size.width - 80);
      final knotY = size.height * 0.3 + random.nextDouble() * (size.height * 0.4);
      final knotSize = 2 + random.nextDouble() * 3;
      _drawSmallKnot(canvas, knotX, knotY, knotSize, random);
    }

    // Layer 5: Warm highlight streaks (worn/polished areas)
    paint.color = highlight.withValues(alpha: 0.2);
    paint.strokeWidth = 1.5;
    for (int i = 0; i < 3; i++) {
      final startX = random.nextDouble() * size.width * 0.3;
      final y = 2 + random.nextDouble() * (size.height - 4);
      final length = 30 + random.nextDouble() * 60;

      final path = Path();
      path.moveTo(startX, y);
      path.quadraticBezierTo(
        startX + length / 2,
        y + (random.nextDouble() - 0.5) * 2,
        startX + length,
        y + (random.nextDouble() - 0.5),
      );
      canvas.drawPath(path, paint);
    }

    // Layer 6: Age darkening at edges
    paint.style = PaintingStyle.fill;
    final edgeShadow = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1A0D05).withValues(alpha: 0.25),
        Colors.transparent,
        Colors.transparent,
        const Color(0xFF1A0D05).withValues(alpha: 0.2),
      ],
      stops: const [0.0, 0.15, 0.85, 1.0],
    );
    paint.shader = edgeShadow.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Layer 7: Top edge wear highlight (where books slide)
    paint.color = highlight.withValues(alpha: 0.12);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;
    canvas.drawLine(Offset(0, 1.5), Offset(size.width, 1.5), paint);
  }

  void _drawSmallKnot(Canvas canvas, double cx, double cy, double size, math.Random random) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Concentric rings
    for (double r = size; r > size * 0.3; r -= 0.6) {
      paint.color = const Color(0xFF2D1A0A).withValues(alpha: 0.1 + (1 - r / size) * 0.15);
      paint.strokeWidth = 0.3;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: r * 1.3,
          height: r * 0.8,
        ),
        paint,
      );
    }

    // Dark center
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF1A0D05).withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: size * 0.4, height: size * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant HorizontalWoodGrainPainter oldDelegate) => oldDelegate.seed != seed;
}

/// Stone texture painter for fantasy side panels - Enchanted ancient library
class StoneTexturePainter extends CustomPainter {
  final Color? glowColor;
  final Color? starColor;
  final int seed;

  // Fantasy stone color palette
  static const _stoneDeep = Color(0xFF1A1620);
  static const _stoneMid = Color(0xFF2D2438);
  static const _stoneHighlight = Color(0xFF4A3F5C);
  static const _mossDark = Color(0xFF1A3028);

  StoneTexturePainter({this.glowColor, this.starColor, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();

    // Layer 1: Base stone gradient (darker edges, lighter center)
    final baseGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _stoneDeep.withValues(alpha: 0.4),
        _stoneMid.withValues(alpha: 0.2),
        _stoneDeep.withValues(alpha: 0.4),
      ],
    );
    paint.shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Layer 2: Stone block divisions (subtle horizontal lines)
    paint.style = PaintingStyle.stroke;
    paint.color = _stoneDeep.withValues(alpha: 0.35);
    paint.strokeWidth = 1.2;
    for (double y = 30 + random.nextDouble() * 20; y < size.height - 20; y += 40 + random.nextDouble() * 30) {
      final path = Path();
      path.moveTo(0, y);
      path.lineTo(size.width, y + (random.nextDouble() - 0.5) * 3);
      canvas.drawPath(path, paint);
    }

    // Layer 3: Vertical cracks (weathered stone)
    for (int i = 0; i < 5; i++) {
      final x = 2 + random.nextDouble() * (size.width - 4);
      paint.color = _stoneDeep.withValues(alpha: 0.3 + random.nextDouble() * 0.2);
      paint.strokeWidth = 0.6 + random.nextDouble() * 0.6;

      final path = Path();
      path.moveTo(x, 0);

      double currentX = x;
      for (double y = 0; y < size.height; y += 12 + random.nextDouble() * 8) {
        final drift = (random.nextDouble() - 0.5) * 2.5;
        currentX = (currentX + drift).clamp(0, size.width);
        path.lineTo(currentX, y);
      }
      path.lineTo(currentX, size.height);
      canvas.drawPath(path, paint);
    }

    // Layer 4: Pitting and weathering (small dots/marks)
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final pitSize = 0.8 + random.nextDouble() * 1.5;
      paint.color = _stoneDeep.withValues(alpha: 0.2 + random.nextDouble() * 0.15);
      canvas.drawCircle(Offset(x, y), pitSize, paint);
    }

    // Layer 5: Moss patches (aged stone effect)
    for (int i = 0; i < 3; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final mossSize = 3 + random.nextDouble() * 5;
      paint.color = _mossDark.withValues(alpha: 0.15 + random.nextDouble() * 0.1);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: mossSize, height: mossSize * 1.3),
        paint,
      );
    }

    // Layer 6: Stone highlight edges
    paint.style = PaintingStyle.stroke;
    paint.color = _stoneHighlight.withValues(alpha: 0.2);
    paint.strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width - 1, 0), Offset(size.width - 1, size.height), paint);

    // Layer 7: Deep shadow on outer edge
    paint.color = _stoneDeep.withValues(alpha: 0.5);
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(0.5, 0), Offset(0.5, size.height), paint);

    // Layer 8: Inner edge magical glow
    if (glowColor != null) {
      paint.color = glowColor!.withValues(alpha: 0.2);
      paint.strokeWidth = 2.5;
      canvas.drawLine(Offset(size.width - 2, 0), Offset(size.width - 2, size.height), paint);
      // Soft glow fade
      paint.color = glowColor!.withValues(alpha: 0.08);
      paint.strokeWidth = 4;
      canvas.drawLine(Offset(size.width - 4, 0), Offset(size.width - 4, size.height), paint);
    }

    // Layer 9: Twinkling stars/sparkles
    if (starColor != null) {
      _drawSparkles(canvas, size, starColor!, random);
    }
  }

  void _drawSparkles(Canvas canvas, Size size, Color color, math.Random random) {
    final sparkleRandom = math.Random(seed * 3 + 77);
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw small twinkling stars (more of them for magical effect)
    for (int i = 0; i < 7; i++) {
      final x = 2 + sparkleRandom.nextDouble() * (size.width - 4);
      final y = 15 + sparkleRandom.nextDouble() * (size.height - 30);
      final brightness = 0.4 + sparkleRandom.nextDouble() * 0.6;
      final starSize = 1.0 + sparkleRandom.nextDouble() * 1.8;

      // Outer glow
      paint.color = color.withValues(alpha: brightness * 0.15);
      canvas.drawCircle(Offset(x, y), starSize * 1.8, paint);

      // Star glow (softer)
      paint.color = color.withValues(alpha: brightness * 0.35);
      canvas.drawCircle(Offset(x, y), starSize, paint);

      // Star core (bright)
      paint.color = color.withValues(alpha: brightness);
      canvas.drawCircle(Offset(x, y), starSize * 0.4, paint);

      // Cross sparkle rays
      paint.color = color.withValues(alpha: brightness * 0.6);
      paint.strokeWidth = 0.5;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x - starSize * 1.2, y), Offset(x + starSize * 1.2, y), paint);
      canvas.drawLine(Offset(x, y - starSize * 1.2), Offset(x, y + starSize * 1.2), paint);
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(covariant StoneTexturePainter oldDelegate) => oldDelegate.seed != seed;
}

/// Rune pattern painter for fantasy shelf dividers - Ancient magical library
class RunePatternPainter extends CustomPainter {
  final Color? runeColor;
  final Color? glowColor;
  final Color? starColor;
  final int seed;

  // Fantasy stone colors
  static const _stoneDeep = Color(0xFF1A1620);
  static const _stoneMid = Color(0xFF2D2438);
  static const _stoneHighlight = Color(0xFF4A3F5C);

  RunePatternPainter({this.runeColor, this.glowColor, this.starColor, this.seed = 123});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();
    final rune = runeColor ?? const Color(0xFFD4AF37);

    // Layer 1: Base stone gradient
    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _stoneDeep.withValues(alpha: 0.3),
        _stoneMid.withValues(alpha: 0.15),
        _stoneDeep.withValues(alpha: 0.35),
      ],
    );
    paint.shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Layer 2: Stone texture lines (horizontal grain)
    paint.style = PaintingStyle.stroke;
    paint.color = _stoneDeep.withValues(alpha: 0.2);
    paint.strokeWidth = 0.4;
    for (double y = 2; y < size.height; y += 2.5 + random.nextDouble()) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 15) {
        final wobble = (random.nextDouble() - 0.5) * 0.4;
        path.lineTo(x + 15, y + wobble);
      }
      canvas.drawPath(path, paint);
    }

    // Layer 3: Carved channel for runes (subtle indentation)
    paint.color = _stoneDeep.withValues(alpha: 0.25);
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.25, size.width, size.height * 0.75),
      paint,
    );

    // Layer 4: Decorative rune patterns with glowing effect
    final runePositions = <double>[];
    double x = 25 + random.nextDouble() * 15;
    while (x < size.width - 25) {
      runePositions.add(x);
      _drawEnhancedRune(canvas, x, size.height / 2, size.height * 0.55, rune, glowColor);
      x += 50 + random.nextDouble() * 35;
    }

    // Layer 5: Connecting arcane lines between runes
    paint.color = rune.withValues(alpha: 0.12);
    paint.strokeWidth = 0.8;
    paint.style = PaintingStyle.stroke;

    // Wavy connecting line
    final connectPath = Path();
    connectPath.moveTo(0, size.height / 2);
    for (double px = 0; px < size.width; px += 20) {
      final wave = math.sin(px * 0.05 + seed) * 1.5;
      connectPath.lineTo(px, size.height / 2 + wave);
    }
    canvas.drawPath(connectPath, paint);

    // Layer 6: Stars between runes
    if (starColor != null) {
      _drawStarsBetweenRunes(canvas, size, runePositions, starColor!);
    }

    // Layer 7: Edge wear and highlights
    paint.color = _stoneHighlight.withValues(alpha: 0.15);
    paint.strokeWidth = 1.0;
    canvas.drawLine(Offset(0, 1.5), Offset(size.width, 1.5), paint);

    // Layer 8: Bottom shadow
    paint.color = _stoneDeep.withValues(alpha: 0.4);
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), paint);

    // Layer 9: Magical glow on edges
    if (glowColor != null) {
      paint.color = glowColor!.withValues(alpha: 0.15);
      paint.strokeWidth = 2.5;
      canvas.drawLine(Offset(0, 1), Offset(size.width, 1), paint);
      canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), paint);
    }
  }

  void _drawEnhancedRune(Canvas canvas, double cx, double cy, double runeSize, Color runeColor, Color? glow) {
    final random = math.Random(cx.toInt() + seed);
    final runeType = random.nextInt(5);
    final paint = Paint();
    final halfSize = runeSize / 2;

    // Draw glow behind rune
    if (glow != null) {
      paint.color = glow.withValues(alpha: 0.15);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), halfSize * 0.8, paint);
    }

    // Draw rune outline with glow
    paint.color = runeColor.withValues(alpha: 0.35);
    paint.strokeWidth = 1.5;
    paint.style = PaintingStyle.stroke;

    final path = Path();

    switch (runeType) {
      case 0: // Diamond with inner diamond
        path.moveTo(cx, cy - halfSize);
        path.lineTo(cx + halfSize * 0.6, cy);
        path.lineTo(cx, cy + halfSize);
        path.lineTo(cx - halfSize * 0.6, cy);
        path.close();
        canvas.drawPath(path, paint);
        // Inner diamond
        paint.strokeWidth = 0.8;
        paint.color = runeColor.withValues(alpha: 0.25);
        final innerPath = Path();
        innerPath.moveTo(cx, cy - halfSize * 0.4);
        innerPath.lineTo(cx + halfSize * 0.25, cy);
        innerPath.lineTo(cx, cy + halfSize * 0.4);
        innerPath.lineTo(cx - halfSize * 0.25, cy);
        innerPath.close();
        canvas.drawPath(innerPath, paint);
        break;
      case 1: // Cross with serifs
        path.moveTo(cx - halfSize * 0.5, cy);
        path.lineTo(cx + halfSize * 0.5, cy);
        path.moveTo(cx, cy - halfSize);
        path.lineTo(cx, cy + halfSize);
        // Serifs
        path.moveTo(cx - halfSize * 0.15, cy - halfSize);
        path.lineTo(cx + halfSize * 0.15, cy - halfSize);
        path.moveTo(cx - halfSize * 0.15, cy + halfSize);
        path.lineTo(cx + halfSize * 0.15, cy + halfSize);
        canvas.drawPath(path, paint);
        break;
      case 2: // Triangle with eye
        path.moveTo(cx, cy - halfSize);
        path.lineTo(cx + halfSize * 0.55, cy + halfSize * 0.6);
        path.lineTo(cx - halfSize * 0.55, cy + halfSize * 0.6);
        path.close();
        canvas.drawPath(path, paint);
        // Eye in center
        paint.strokeWidth = 0.8;
        canvas.drawCircle(Offset(cx, cy + halfSize * 0.1), halfSize * 0.15, paint);
        break;
      case 3: // Circle with dot and rays
        canvas.drawCircle(Offset(cx, cy), halfSize * 0.45, paint);
        paint.style = PaintingStyle.fill;
        paint.color = runeColor.withValues(alpha: 0.4);
        canvas.drawCircle(Offset(cx, cy), halfSize * 0.12, paint);
        // Rays
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 0.6;
        for (int i = 0; i < 4; i++) {
          final angle = i * math.pi / 2;
          canvas.drawLine(
            Offset(cx + math.cos(angle) * halfSize * 0.5, cy + math.sin(angle) * halfSize * 0.5),
            Offset(cx + math.cos(angle) * halfSize * 0.7, cy + math.sin(angle) * halfSize * 0.7),
            paint,
          );
        }
        break;
      case 4: // Arrow/chevron
        path.moveTo(cx - halfSize * 0.4, cy - halfSize * 0.3);
        path.lineTo(cx, cy - halfSize * 0.7);
        path.lineTo(cx + halfSize * 0.4, cy - halfSize * 0.3);
        path.moveTo(cx - halfSize * 0.4, cy + halfSize * 0.2);
        path.lineTo(cx, cy - halfSize * 0.1);
        path.lineTo(cx + halfSize * 0.4, cy + halfSize * 0.2);
        path.moveTo(cx, cy + halfSize * 0.1);
        path.lineTo(cx, cy + halfSize * 0.7);
        canvas.drawPath(path, paint);
        break;
    }
  }

  void _drawStarsBetweenRunes(Canvas canvas, Size size, List<double> runePositions, Color color) {
    final starRandom = math.Random(seed * 7 + 456);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < runePositions.length + 1; i++) {
      final startX = i == 0 ? 5.0 : runePositions[i - 1] + 12;
      final endX = i >= runePositions.length ? size.width - 5 : runePositions[i] - 12;

      if (endX - startX < 15) continue;

      final numStars = 1 + starRandom.nextInt(3);
      for (int j = 0; j < numStars; j++) {
        final x = startX + starRandom.nextDouble() * (endX - startX);
        final y = 2 + starRandom.nextDouble() * (size.height - 4);
        final brightness = 0.5 + starRandom.nextDouble() * 0.5;
        final starSize = 1.2 + starRandom.nextDouble() * 1.8;

        _drawFourPointStar(canvas, paint, x, y, starSize, color, brightness);
      }
    }
  }

  void _drawFourPointStar(Canvas canvas, Paint paint, double cx, double cy,
      double size, Color color, double brightness) {
    // Outer glow
    paint.color = color.withValues(alpha: brightness * 0.15);
    canvas.drawCircle(Offset(cx, cy), size * 1.2, paint);

    // Mid glow
    paint.color = color.withValues(alpha: brightness * 0.3);
    canvas.drawCircle(Offset(cx, cy), size * 0.7, paint);

    // Bright core
    paint.color = color.withValues(alpha: brightness);
    canvas.drawCircle(Offset(cx, cy), size * 0.25, paint);

    // Cross sparkle rays
    paint.color = color.withValues(alpha: brightness * 0.7);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.6;
    canvas.drawLine(Offset(cx - size, cy), Offset(cx + size, cy), paint);
    canvas.drawLine(Offset(cx, cy - size), Offset(cx, cy + size), paint);

    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant RunePatternPainter oldDelegate) => oldDelegate.seed != seed;
}

/// Vertical filigree/scrollwork painter for romance side panels
/// Beauty and the Beast / Bridgerton / Classic Romantic Era aesthetic
class FiligreeVerticalPainter extends CustomPainter {
  final Color? baseColor;
  final Color? accentColor;
  final Color? shimmerColor;
  final int seed;

  // Enhanced Romance color palette - Beauty and the Beast / Bridgerton
  static const _champagneRose = Color(0xFFF5DFD7);
  static const _roseGold = Color(0xFFB76E79);
  static const _enchantedRose = Color(0xFF8B2942);
  static const _velvetBurgundy = Color(0xFF5C1A2B);
  static const _antiqueGold = Color(0xFFC9A84C);
  static const _candlelightGold = Color(0xFFE8C87E);
  static const _pearlWhite = Color(0xFFF8F4F0);
  static const _shimmer = Color(0xFFFFFAF5);

  FiligreeVerticalPainter({this.baseColor, this.accentColor, this.shimmerColor, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();
    final base = baseColor ?? _roseGold;
    final accent = accentColor ?? _antiqueGold;

    // Layer 1: Base gradient with silk sheen feel
    final baseGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _velvetBurgundy.withValues(alpha: 0.2),
        _champagneRose.withValues(alpha: 0.08),
        _velvetBurgundy.withValues(alpha: 0.2),
      ],
    );
    paint.shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Layer 2: Damask-inspired texture pattern
    _drawDamaskTexture(canvas, size, random);

    // Layer 3: Baroque corners at top and bottom
    _drawBaroqueCorner(canvas, 0, size.width, true, base, accent);
    _drawBaroqueCorner(canvas, size.height, size.width, false, base, accent);

    // Layer 4: Elegant baroque S-curves (enhanced scrollwork)
    paint.style = PaintingStyle.stroke;
    paint.color = base.withValues(alpha: 0.5);
    paint.strokeWidth = 1.4;
    paint.strokeCap = StrokeCap.round;

    for (double y = 35; y < size.height - 35; y += 28 + random.nextDouble() * 8) {
      final path = Path();
      final startX = 3 + random.nextDouble() * 2;
      path.moveTo(startX, y);

      // Main baroque S-curve with deeper swoops
      path.cubicTo(
        size.width * 0.85, y + 6 + random.nextDouble() * 4,
        size.width * 0.15, y + 18 + random.nextDouble() * 4,
        startX + 1, y + 28,
      );
      canvas.drawPath(path, paint);

      // Secondary curl at end
      paint.strokeWidth = 0.8;
      paint.color = base.withValues(alpha: 0.35);
      final curlPath = Path();
      curlPath.moveTo(startX + 1, y + 28);
      curlPath.quadraticBezierTo(
        startX + 6, y + 32,
        startX + 4, y + 36,
      );
      canvas.drawPath(curlPath, paint);
      paint.strokeWidth = 1.4;
      paint.color = base.withValues(alpha: 0.5);
    }

    // Layer 5: Rose motifs (Beauty and the Beast inspired)
    for (double y = 55; y < size.height - 55; y += 55 + random.nextDouble() * 10) {
      final roseX = size.width * 0.5 + (random.nextDouble() - 0.5) * 4;
      _drawStylizedRose(canvas, Offset(roseX, y), 8 + random.nextDouble() * 2, _enchantedRose, accent);
    }

    // Layer 6: Fine decorative tendrils with leaf endings
    paint.color = base.withValues(alpha: 0.35);
    paint.strokeWidth = 0.7;
    for (double y = 25; y < size.height - 25; y += 35 + random.nextDouble() * 15) {
      final tendrilPath = Path();
      final startX = 2 + random.nextDouble() * 3;
      tendrilPath.moveTo(startX, y);
      tendrilPath.quadraticBezierTo(
        size.width * 0.5, y - 4,
        size.width * 0.6, y + 3,
      );
      tendrilPath.quadraticBezierTo(
        size.width * 0.45, y + 7,
        size.width * 0.35, y + 5,
      );
      canvas.drawPath(tendrilPath, paint);

      // Small leaf at end
      _drawTinyLeaf(canvas, Offset(size.width * 0.35, y + 5), 3, base);
    }

    // Layer 7: Gold diamonds with glow effect
    paint.style = PaintingStyle.fill;
    for (double y = 18; y < size.height - 18; y += 32 + random.nextDouble() * 12) {
      final x = 5 + random.nextDouble() * 4;
      // Glow behind diamond
      paint.color = _candlelightGold.withValues(alpha: 0.2);
      canvas.drawCircle(Offset(x, y), 4, paint);
      // Main diamond
      _drawSmallDiamond(canvas, x, y, 2.5, accent.withValues(alpha: 0.6));
      // Satellite dots
      paint.color = accent.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(x + 3, y - 4), 1.0, paint);
      canvas.drawCircle(Offset(x + 3, y + 4), 1.0, paint);
    }

    // Layer 8: Magical sparkles (enchanted rose effect)
    final sparkleRandom = math.Random(seed * 5 + 123);
    for (int i = 0; i < 5; i++) {
      final x = 3 + sparkleRandom.nextDouble() * (size.width - 6);
      final y = 20 + sparkleRandom.nextDouble() * (size.height - 40);
      _drawMagicalSparkle(canvas, Offset(x, y), 1.2 + sparkleRandom.nextDouble() * 0.8, shimmerColor ?? _shimmer);
    }

    // Layer 9: Pearl edge highlight with gradient fade
    paint.style = PaintingStyle.stroke;
    paint.color = _pearlWhite.withValues(alpha: 0.3);
    paint.strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width - 1, 0), Offset(size.width - 1, size.height), paint);
    paint.color = _pearlWhite.withValues(alpha: 0.15);
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(size.width - 2.5, 0), Offset(size.width - 2.5, size.height), paint);

    // Layer 10: Velvet shadow on outer edge
    paint.color = _velvetBurgundy.withValues(alpha: 0.4);
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(0.5, 0), Offset(0.5, size.height), paint);
  }

  void _drawDamaskTexture(Canvas canvas, Size size, math.Random random) {
    // Subtle diamond/lozenge pattern
    for (double y = 10; y < size.height; y += 18) {
      for (double x = 4; x < size.width - 2; x += 8) {
        final offset = (y ~/ 18) % 2 == 0 ? 0.0 : 4.0;
        _drawDamaskElement(canvas, Offset(x + offset, y), 2.5, _velvetBurgundy.withValues(alpha: 0.06));
      }
    }
  }

  void _drawDamaskElement(Canvas canvas, Offset center, double elementSize, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - elementSize);
    path.quadraticBezierTo(center.dx + elementSize * 0.6, center.dy, center.dx, center.dy + elementSize);
    path.quadraticBezierTo(center.dx - elementSize * 0.6, center.dy, center.dx, center.dy - elementSize);
    canvas.drawPath(path, paint);
  }

  void _drawBaroqueCorner(Canvas canvas, double cornerY, double panelWidth, bool isTop, Color baseColor, Color gold) {
    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final yDir = isTop ? 1.0 : -1.0;
    final startY = isTop ? cornerY + 5 : cornerY - 5;

    // Main curling scroll from corner
    final scrollPath = Path();
    scrollPath.moveTo(2, startY);
    scrollPath.cubicTo(
      panelWidth * 0.7, startY + yDir * 10,
      panelWidth * 0.3, startY + yDir * 20,
      panelWidth * 0.55, startY + yDir * 28,
    );
    // Curl back
    scrollPath.quadraticBezierTo(
      panelWidth * 0.75, startY + yDir * 25,
      panelWidth * 0.6, startY + yDir * 20,
    );
    canvas.drawPath(scrollPath, paint);

    // Secondary flourish
    paint.strokeWidth = 0.9;
    paint.color = baseColor.withValues(alpha: 0.35);
    final flourishPath = Path();
    flourishPath.moveTo(panelWidth * 0.55, startY + yDir * 15);
    flourishPath.quadraticBezierTo(
      panelWidth * 0.85, startY + yDir * 12,
      panelWidth * 0.75, startY + yDir * 6,
    );
    canvas.drawPath(flourishPath, paint);

    // Gold accent dots
    paint.style = PaintingStyle.fill;
    paint.color = gold.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(panelWidth * 0.55, startY + yDir * 28), 1.8, paint);
    canvas.drawCircle(Offset(panelWidth * 0.6, startY + yDir * 20), 1.2, paint);
  }

  void _drawStylizedRose(Canvas canvas, Offset center, double roseSize, Color roseColor, Color goldCenter) {
    final paint = Paint();

    // Outer petals (4 overlapping curves in spiral)
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2) + 0.25;
      final petalSize = roseSize * (0.95 - i * 0.12);

      final petalPath = Path();
      petalPath.moveTo(center.dx, center.dy);
      petalPath.quadraticBezierTo(
        center.dx + math.cos(angle) * petalSize,
        center.dy + math.sin(angle) * petalSize,
        center.dx + math.cos(angle + 0.9) * petalSize * 0.65,
        center.dy + math.sin(angle + 0.9) * petalSize * 0.65,
      );
      petalPath.quadraticBezierTo(
        center.dx + math.cos(angle + 1.3) * petalSize * 0.25,
        center.dy + math.sin(angle + 1.3) * petalSize * 0.25,
        center.dx,
        center.dy,
      );

      paint.style = PaintingStyle.fill;
      paint.color = roseColor.withValues(alpha: 0.3 + i * 0.05);
      canvas.drawPath(petalPath, paint);

      // Petal outline
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 0.5;
      paint.color = roseColor.withValues(alpha: 0.45);
      canvas.drawPath(petalPath, paint);
    }

    // Inner spiral center
    paint.style = PaintingStyle.fill;
    paint.color = roseColor.withValues(alpha: 0.5);
    canvas.drawCircle(center, roseSize * 0.18, paint);

    // Gold accent dot at center (enchanted effect)
    paint.color = goldCenter.withValues(alpha: 0.65);
    canvas.drawCircle(center, roseSize * 0.08, paint);

    // Two small leaves below the rose
    final leafColor = _enchantedRose.withValues(alpha: 0.35);
    for (int side = -1; side <= 1; side += 2) {
      _drawTinyLeaf(canvas, Offset(center.dx + side * roseSize * 0.6, center.dy + roseSize * 0.7), roseSize * 0.35, Color.lerp(leafColor, _roseGold, 0.3)!);
    }
  }

  void _drawTinyLeaf(Canvas canvas, Offset tip, double leafSize, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(tip.dx, tip.dy);
    leafPath.quadraticBezierTo(
      tip.dx - leafSize * 0.5, tip.dy - leafSize * 0.3,
      tip.dx, tip.dy - leafSize,
    );
    leafPath.quadraticBezierTo(
      tip.dx + leafSize * 0.5, tip.dy - leafSize * 0.3,
      tip.dx, tip.dy,
    );
    canvas.drawPath(leafPath, paint);
  }

  void _drawSmallDiamond(Canvas canvas, double cx, double cy, double diamondSize, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(cx, cy - diamondSize);
    path.lineTo(cx + diamondSize * 0.6, cy);
    path.lineTo(cx, cy + diamondSize);
    path.lineTo(cx - diamondSize * 0.6, cy);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMagicalSparkle(Canvas canvas, Offset center, double sparkleSize, Color color) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Outer soft glow
    paint.color = color.withValues(alpha: 0.15);
    canvas.drawCircle(center, sparkleSize * 2.5, paint);

    // Mid glow
    paint.color = color.withValues(alpha: 0.35);
    canvas.drawCircle(center, sparkleSize * 1.2, paint);

    // Bright core
    paint.color = color.withValues(alpha: 0.85);
    canvas.drawCircle(center, sparkleSize * 0.4, paint);

    // 4-point star rays
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.4;
    paint.color = color.withValues(alpha: 0.6);
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * sparkleSize * 0.6, center.dy + math.sin(angle) * sparkleSize * 0.6),
        Offset(center.dx + math.cos(angle) * sparkleSize * 1.8, center.dy + math.sin(angle) * sparkleSize * 1.8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FiligreeVerticalPainter oldDelegate) => oldDelegate.seed != seed;
}

/// Horizontal filigree/scrollwork painter for romance shelf dividers
/// Beauty and the Beast / Bridgerton / Classic Romantic Era aesthetic
class FiligreeHorizontalPainter extends CustomPainter {
  final Color? baseColor;
  final Color? accentColor;
  final Color? shimmerColor;
  final int seed;

  // Enhanced Romance color palette - Beauty and the Beast / Bridgerton
  static const _roseGold = Color(0xFFB76E79);
  static const _enchantedRose = Color(0xFF8B2942);
  static const _velvetBurgundy = Color(0xFF5C1A2B);
  static const _antiqueGold = Color(0xFFC9A84C);
  static const _candlelightGold = Color(0xFFE8C87E);
  static const _pearlWhite = Color(0xFFF8F4F0);
  static const _shimmer = Color(0xFFFFFAF5);

  FiligreeHorizontalPainter({this.baseColor, this.accentColor, this.shimmerColor, this.seed = 123});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();
    final base = baseColor ?? _roseGold;
    final accent = accentColor ?? _antiqueGold;
    final midY = size.height / 2;

    // Layer 1: Base gradient with candlelight warmth
    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _velvetBurgundy.withValues(alpha: 0.18),
        _candlelightGold.withValues(alpha: 0.06),
        _velvetBurgundy.withValues(alpha: 0.22),
      ],
    );
    paint.shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Layer 2: Damask texture pattern
    _drawDamaskTexture(canvas, size);

    // Layer 3: Baroque scrollwork (enhanced waves with deeper curves)
    paint.style = PaintingStyle.stroke;
    paint.color = base.withValues(alpha: 0.45);
    paint.strokeWidth = 1.2;
    paint.strokeCap = StrokeCap.round;

    // Upper wave pattern with baroque curls
    for (double x = 12; x < size.width - 12; x += 40 + random.nextDouble() * 12) {
      final path = Path();
      path.moveTo(x, midY);
      path.cubicTo(
        x + 10, midY - 4,
        x + 30, midY - 4,
        x + 40, midY,
      );
      canvas.drawPath(path, paint);

      // Decorative curl at peak
      if ((x ~/ 40) % 2 == 0) {
        _drawTinyCurl(canvas, Offset(x + 20, midY - 4.5), base, true);
      }
    }

    // Lower wave pattern
    for (double x = 32; x < size.width - 32; x += 40 + random.nextDouble() * 12) {
      final path = Path();
      path.moveTo(x, midY);
      path.cubicTo(
        x + 10, midY + 3.5,
        x + 30, midY + 3.5,
        x + 40, midY,
      );
      canvas.drawPath(path, paint);

      if ((x ~/ 40) % 2 == 1) {
        _drawTinyCurl(canvas, Offset(x + 20, midY + 4.5), base, false);
      }
    }

    // Layer 4: ROSE GARLAND - Primary feature (Beauty and the Beast)
    _drawRoseGarland(canvas, size, random);

    // Layer 5: Connecting vine between roses
    _drawConnectingVine(canvas, size, random);

    // Layer 6: Gold diamonds with enhanced glow
    for (double x = 55 + random.nextDouble() * 25; x < size.width - 55; x += 85 + random.nextDouble() * 30) {
      _drawOrnamentedDiamond(canvas, x, midY, 3.5, accent);
    }

    // Layer 7: Pearl dots along borders (Bridgerton elegance)
    for (double x = 18; x < size.width - 18; x += 22 + random.nextDouble() * 8) {
      _drawPearlDot(canvas, Offset(x, 3.5), 1.2);
      _drawPearlDot(canvas, Offset(x + 11, size.height - 3.5), 1.2);
    }

    // Layer 8: Ornate triple-line borders (thin-thick-thin)
    paint.style = PaintingStyle.stroke;
    // Top border
    paint.color = base.withValues(alpha: 0.2);
    paint.strokeWidth = 0.4;
    canvas.drawLine(Offset(0, 1.5), Offset(size.width, 1.5), paint);
    paint.color = base.withValues(alpha: 0.35);
    paint.strokeWidth = 0.9;
    canvas.drawLine(Offset(0, 3), Offset(size.width, 3), paint);
    paint.color = base.withValues(alpha: 0.2);
    paint.strokeWidth = 0.4;
    canvas.drawLine(Offset(0, 4.5), Offset(size.width, 4.5), paint);

    // Bottom border
    paint.color = base.withValues(alpha: 0.2);
    paint.strokeWidth = 0.4;
    canvas.drawLine(Offset(0, size.height - 1.5), Offset(size.width, size.height - 1.5), paint);
    paint.color = base.withValues(alpha: 0.35);
    paint.strokeWidth = 0.9;
    canvas.drawLine(Offset(0, size.height - 3), Offset(size.width, size.height - 3), paint);
    paint.color = base.withValues(alpha: 0.2);
    paint.strokeWidth = 0.4;
    canvas.drawLine(Offset(0, size.height - 4.5), Offset(size.width, size.height - 4.5), paint);

    // Layer 9: Edge flourishes at left and right
    _drawEdgeFlourish(canvas, Offset(8, midY), 12, true, base, accent);
    _drawEdgeFlourish(canvas, Offset(size.width - 8, midY), 12, false, base, accent);

    // Layer 10: Magical sparkles near roses
    final sparkleRandom = math.Random(seed * 7 + 789);
    for (int i = 0; i < 6; i++) {
      final x = 30 + sparkleRandom.nextDouble() * (size.width - 60);
      final y = 3 + sparkleRandom.nextDouble() * (size.height - 6);
      _drawMagicalSparkle(canvas, Offset(x, y), 1.0 + sparkleRandom.nextDouble() * 0.6, shimmerColor ?? _shimmer);
    }

    // Layer 11: Pearl sheen highlight at top
    paint.color = _pearlWhite.withValues(alpha: 0.25);
    paint.strokeWidth = 1.2;
    canvas.drawLine(Offset(0, 0.8), Offset(size.width, 0.8), paint);

    // Velvet shadow at bottom
    paint.color = _velvetBurgundy.withValues(alpha: 0.35);
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(0, size.height - 0.8), Offset(size.width, size.height - 0.8), paint);
  }

  void _drawDamaskTexture(Canvas canvas, Size size) {
    for (double y = 4; y < size.height - 2; y += 6) {
      for (double x = 8; x < size.width - 4; x += 12) {
        final offset = (y ~/ 6) % 2 == 0 ? 0.0 : 6.0;
        _drawDamaskElement(canvas, Offset(x + offset, y), 2, _velvetBurgundy.withValues(alpha: 0.05));
      }
    }
  }

  void _drawDamaskElement(Canvas canvas, Offset center, double elementSize, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - elementSize);
    path.quadraticBezierTo(center.dx + elementSize * 0.5, center.dy, center.dx, center.dy + elementSize);
    path.quadraticBezierTo(center.dx - elementSize * 0.5, center.dy, center.dx, center.dy - elementSize);
    canvas.drawPath(path, paint);
  }

  void _drawRoseGarland(Canvas canvas, Size size, math.Random random) {
    final midY = size.height / 2;

    // Draw roses along the center line
    for (double x = 45 + random.nextDouble() * 20; x < size.width - 45; x += 90 + random.nextDouble() * 25) {
      _drawStylizedRose(canvas, Offset(x, midY), 7 + random.nextDouble() * 1.5);
    }
  }

  void _drawStylizedRose(Canvas canvas, Offset center, double roseSize) {
    final paint = Paint();

    // Outer petals (4 overlapping curves)
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2) + 0.3;
      final petalSize = roseSize * (0.9 - i * 0.1);

      final petalPath = Path();
      petalPath.moveTo(center.dx, center.dy);
      petalPath.quadraticBezierTo(
        center.dx + math.cos(angle) * petalSize,
        center.dy + math.sin(angle) * petalSize,
        center.dx + math.cos(angle + 0.85) * petalSize * 0.6,
        center.dy + math.sin(angle + 0.85) * petalSize * 0.6,
      );
      petalPath.quadraticBezierTo(
        center.dx + math.cos(angle + 1.2) * petalSize * 0.2,
        center.dy + math.sin(angle + 1.2) * petalSize * 0.2,
        center.dx,
        center.dy,
      );

      paint.style = PaintingStyle.fill;
      paint.color = _enchantedRose.withValues(alpha: 0.28 + i * 0.05);
      canvas.drawPath(petalPath, paint);

      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 0.4;
      paint.color = _enchantedRose.withValues(alpha: 0.4);
      canvas.drawPath(petalPath, paint);
    }

    // Center spiral
    paint.style = PaintingStyle.fill;
    paint.color = _enchantedRose.withValues(alpha: 0.45);
    canvas.drawCircle(center, roseSize * 0.15, paint);

    // Gold center dot
    paint.color = _antiqueGold.withValues(alpha: 0.6);
    canvas.drawCircle(center, roseSize * 0.06, paint);

    // Two small leaves
    for (int side = -1; side <= 1; side += 2) {
      _drawTinyLeaf(canvas, Offset(center.dx + side * roseSize * 0.55, center.dy + roseSize * 0.6), roseSize * 0.3);
    }
  }

  void _drawTinyLeaf(Canvas canvas, Offset tip, double leafSize) {
    final paint = Paint()
      ..color = _enchantedRose.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(tip.dx, tip.dy);
    leafPath.quadraticBezierTo(
      tip.dx - leafSize * 0.4, tip.dy - leafSize * 0.25,
      tip.dx, tip.dy - leafSize,
    );
    leafPath.quadraticBezierTo(
      tip.dx + leafSize * 0.4, tip.dy - leafSize * 0.25,
      tip.dx, tip.dy,
    );
    canvas.drawPath(leafPath, paint);
  }

  void _drawConnectingVine(Canvas canvas, Size size, math.Random random) {
    final paint = Paint()
      ..color = _roseGold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;

    // Wavy connecting line
    final vinePath = Path();
    vinePath.moveTo(20, midY);
    for (double x = 20; x < size.width - 20; x += 25) {
      final wave = math.sin(x * 0.08 + seed) * 2;
      vinePath.lineTo(x, midY + wave);
    }
    canvas.drawPath(vinePath, paint);

    // Small leaf accents along vine
    for (double x = 35; x < size.width - 35; x += 45 + random.nextDouble() * 20) {
      final y = midY + math.sin(x * 0.08 + seed) * 2;
      final dir = random.nextBool() ? 1.0 : -1.0;
      _drawTinyLeaf(canvas, Offset(x, y + dir * 3), 2.5);
    }
  }

  void _drawPearlDot(Canvas canvas, Offset center, double pearlSize) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Soft glow
    paint.color = _pearlWhite.withValues(alpha: 0.2);
    canvas.drawCircle(center, pearlSize * 1.5, paint);

    // Main pearl
    paint.color = _pearlWhite.withValues(alpha: 0.5);
    canvas.drawCircle(center, pearlSize, paint);

    // Highlight
    paint.color = _shimmer.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(center.dx - pearlSize * 0.3, center.dy - pearlSize * 0.3), pearlSize * 0.35, paint);
  }

  void _drawEdgeFlourish(Canvas canvas, Offset position, double flourishSize, bool isLeft, Color baseColor, Color gold) {
    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final dir = isLeft ? 1.0 : -1.0;

    // Curling scroll from edge
    final flourishPath = Path();
    flourishPath.moveTo(position.dx, position.dy);
    flourishPath.cubicTo(
      position.dx + dir * flourishSize * 0.6, position.dy - flourishSize * 0.3,
      position.dx + dir * flourishSize * 0.8, position.dy + flourishSize * 0.2,
      position.dx + dir * flourishSize * 0.5, position.dy + flourishSize * 0.4,
    );
    // Curl back
    flourishPath.quadraticBezierTo(
      position.dx + dir * flourishSize * 0.3, position.dy + flourishSize * 0.5,
      position.dx + dir * flourishSize * 0.4, position.dy + flourishSize * 0.3,
    );
    canvas.drawPath(flourishPath, paint);

    // Gold accent dot
    paint.style = PaintingStyle.fill;
    paint.color = gold.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(position.dx + dir * flourishSize * 0.5, position.dy + flourishSize * 0.4), 1.5, paint);
  }

  void _drawTinyCurl(Canvas canvas, Offset center, Color color, bool upward) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    final dir = upward ? -1.0 : 1.0;
    final path = Path();
    path.moveTo(center.dx - 4, center.dy);
    path.quadraticBezierTo(
      center.dx, center.dy + dir * 2.5,
      center.dx + 4, center.dy,
    );
    canvas.drawPath(path, paint);
  }

  void _drawOrnamentedDiamond(Canvas canvas, double cx, double cy, double diamondSize, Color color) {
    final paint = Paint();

    // Outer candlelight glow
    paint.color = _candlelightGold.withValues(alpha: 0.2);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), diamondSize * 2, paint);

    // Main diamond
    paint.color = color.withValues(alpha: 0.55);
    final path = Path();
    path.moveTo(cx, cy - diamondSize);
    path.lineTo(cx + diamondSize * 0.6, cy);
    path.lineTo(cx, cy + diamondSize);
    path.lineTo(cx - diamondSize * 0.6, cy);
    path.close();
    canvas.drawPath(path, paint);

    // Inner highlight
    paint.color = color.withValues(alpha: 0.75);
    final innerPath = Path();
    innerPath.moveTo(cx, cy - diamondSize * 0.4);
    innerPath.lineTo(cx + diamondSize * 0.25, cy);
    innerPath.lineTo(cx, cy + diamondSize * 0.4);
    innerPath.lineTo(cx - diamondSize * 0.25, cy);
    innerPath.close();
    canvas.drawPath(innerPath, paint);

    // Satellite dots
    paint.color = color.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(cx - diamondSize * 1.4, cy), 1.0, paint);
    canvas.drawCircle(Offset(cx + diamondSize * 1.4, cy), 1.0, paint);
  }

  void _drawMagicalSparkle(Canvas canvas, Offset center, double sparkleSize, Color color) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Outer glow
    paint.color = color.withValues(alpha: 0.12);
    canvas.drawCircle(center, sparkleSize * 2.2, paint);

    // Mid glow
    paint.color = color.withValues(alpha: 0.3);
    canvas.drawCircle(center, sparkleSize * 1.0, paint);

    // Core
    paint.color = color.withValues(alpha: 0.8);
    canvas.drawCircle(center, sparkleSize * 0.35, paint);

    // Star rays
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.35;
    paint.color = color.withValues(alpha: 0.5);
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * sparkleSize * 0.5, center.dy + math.sin(angle) * sparkleSize * 0.5),
        Offset(center.dx + math.cos(angle) * sparkleSize * 1.5, center.dy + math.sin(angle) * sparkleSize * 1.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FiligreeHorizontalPainter oldDelegate) => oldDelegate.seed != seed;
}

/// Rainbow sparkle painter for Pride theme side panels
/// Bold, vibrant LGBTQ+ celebration with hearts, sparkles, and rainbow stripes
class RainbowSparklePainter extends CustomPainter {
  final List<Color>? rainbowColors;
  final Color? glowColor;
  final Color? sparkleColor;
  final int seed;

  // Pride flag colors - BOLD and VIBRANT
  static const _red = Color(0xFFE53935);
  static const _orange = Color(0xFFFF9800);
  static const _yellow = Color(0xFFFFEB3B);
  static const _green = Color(0xFF4CAF50);
  static const _blue = Color(0xFF2196F3);
  static const _purple = Color(0xFF9C27B0);
  static const _pink = Color(0xFFE91E63);
  static const _white = Color(0xFFFFFFFF);

  RainbowSparklePainter({
    this.rainbowColors,
    this.glowColor,
    this.sparkleColor,
    this.seed = 42,
  });

  double _seededRandom(int index) {
    final hash = (seed * 31 + index * 17) & 0x7FFFFFFF;
    return (hash % 10000) / 10000.0;
  }

  int _randomIndex = 0;

  double _nextRandom() {
    return _seededRandom(_randomIndex++);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _randomIndex = 0;
    final colors = rainbowColors ?? [_red, _orange, _yellow, _green, _blue, _purple];

    // Layer 1: BOLD rainbow stripes (the main visual)
    _drawBoldRainbowStripes(canvas, size, colors);

    // Layer 2: Hearts scattered
    _drawHearts(canvas, size, colors);

    // Layer 3: Big sparkles
    _drawSparkles(canvas, size);

    // Layer 4: Edge highlights
    _drawEdgeHighlights(canvas, size);
  }

  void _drawBoldRainbowStripes(Canvas canvas, Size size, List<Color> colors) {
    final paint = Paint();
    final stripeHeight = size.height / colors.length;

    // Draw bold, solid rainbow stripes
    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i].withValues(alpha: 0.85); // BOLD alpha
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight + 1),
        paint,
      );
    }

    // Add subtle gradient overlay for depth
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.1),
          Colors.black.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);
  }

  void _drawHearts(Canvas canvas, Size size, List<Color> colors) {
    // Draw hearts at random positions - MORE and BIGGER
    for (int i = 0; i < 4; i++) {
      final x = 3 + _nextRandom() * (size.width - 6);
      final y = 25 + _nextRandom() * (size.height - 50);
      final heartSize = 5 + _nextRandom() * 4;

      _drawHeart(canvas, Offset(x, y), heartSize, _white);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final shadowPath = Path();
    shadowPath.moveTo(center.dx + 0.5, center.dy + size * 0.35);
    shadowPath.cubicTo(
      center.dx - size * 0.5 + 0.5, center.dy + 0.5,
      center.dx - size * 0.5 + 0.5, center.dy - size * 0.4 + 0.5,
      center.dx + 0.5, center.dy - size * 0.2 + 0.5,
    );
    shadowPath.cubicTo(
      center.dx + size * 0.5 + 0.5, center.dy - size * 0.4 + 0.5,
      center.dx + size * 0.5 + 0.5, center.dy + 0.5,
      center.dx + 0.5, center.dy + size * 0.35,
    );
    canvas.drawPath(shadowPath, shadowPaint);

    // Main heart
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size * 0.5, center.dy,
      center.dx - size * 0.5, center.dy - size * 0.4,
      center.dx, center.dy - size * 0.2,
    );
    path.cubicTo(
      center.dx + size * 0.5, center.dy - size * 0.4,
      center.dx + size * 0.5, center.dy,
      center.dx, center.dy + size * 0.3,
    );

    canvas.drawPath(path, paint);

    // Pink outline for pop
    final outlinePaint = Paint()
      ..color = _pink.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, outlinePaint);
  }

  void _drawSparkles(Canvas canvas, Size size) {
    // White sparkles with glow
    for (int i = 0; i < 6; i++) {
      final x = 2 + _nextRandom() * (size.width - 4);
      final y = 10 + _nextRandom() * (size.height - 20);
      final sparkleSize = 2 + _nextRandom() * 2.5;

      _drawSparkle(canvas, Offset(x, y), sparkleSize);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Glow
    paint.color = _white.withValues(alpha: 0.4);
    canvas.drawCircle(center, size * 1.5, paint);

    // Core
    paint.color = _white.withValues(alpha: 0.95);

    // 4-point star
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.25, center.dy - size * 0.25);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.25, center.dy + size * 0.25);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.25, center.dy + size * 0.25);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.25, center.dy - size * 0.25);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawEdgeHighlights(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // White highlight on inner edge
    paint.color = _white.withValues(alpha: 0.5);
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(size.width - 1, 0), Offset(size.width - 1, size.height), paint);

    // Darker shadow on outer edge
    paint.color = Colors.black.withValues(alpha: 0.3);
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(0.5, 0), Offset(0.5, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant RainbowSparklePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

/// Rainbow garland painter for Pride theme shelf dividers
/// Bold horizontal rainbow stripes with hearts and celebratory elements
class RainbowGarlandPainter extends CustomPainter {
  final List<Color>? rainbowColors;
  final Color? glowColor;
  final Color? sparkleColor;
  final int seed;

  // Pride flag colors - BOLD
  static const _red = Color(0xFFE53935);
  static const _orange = Color(0xFFFF9800);
  static const _yellow = Color(0xFFFFEB3B);
  static const _green = Color(0xFF4CAF50);
  static const _blue = Color(0xFF2196F3);
  static const _purple = Color(0xFF9C27B0);
  static const _pink = Color(0xFFE91E63);
  static const _white = Color(0xFFFFFFFF);

  RainbowGarlandPainter({
    this.rainbowColors,
    this.glowColor,
    this.sparkleColor,
    this.seed = 123,
  });

  double _seededRandom(int index) {
    final hash = (seed * 31 + index * 17) & 0x7FFFFFFF;
    return (hash % 10000) / 10000.0;
  }

  int _randomIndex = 0;

  double _nextRandom() {
    return _seededRandom(_randomIndex++);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _randomIndex = 0;
    final colors = rainbowColors ?? [_red, _orange, _yellow, _green, _blue, _purple];

    // Layer 1: BOLD rainbow stripes
    _drawBoldRainbowStripes(canvas, size, colors);

    // Layer 2: Heart garland - BIGGER hearts
    _drawHeartGarland(canvas, size);

    // Layer 3: Sparkles between hearts
    _drawSparkles(canvas, size);

    // Layer 4: Edge highlights
    _drawEdgeHighlights(canvas, size);
  }

  void _drawBoldRainbowStripes(Canvas canvas, Size size, List<Color> colors) {
    final stripeHeight = size.height / colors.length;
    final paint = Paint();

    // Draw BOLD, solid rainbow stripes
    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i].withValues(alpha: 0.9); // VERY bold
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight + 0.5),
        paint,
      );
    }

    // Subtle 3D effect
    final topHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _white.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topHighlight);
  }

  void _drawHeartGarland(Canvas canvas, Size size) {
    final midY = size.height / 2;

    // BIG white hearts with colored outlines - spaced along the divider
    for (double x = 50; x < size.width - 30; x += 80) {
      final yOffset = math.sin(x * 0.08) * 1.5;
      _drawBigHeart(canvas, Offset(x, midY + yOffset), 8);
    }
  }

  void _drawBigHeart(Canvas canvas, Offset center, double size) {
    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final shadowPath = Path();
    shadowPath.moveTo(center.dx + 1, center.dy + size * 0.4);
    shadowPath.cubicTo(
      center.dx - size * 0.55 + 1, center.dy + size * 0.1 + 1,
      center.dx - size * 0.55 + 1, center.dy - size * 0.35 + 1,
      center.dx + 1, center.dy - size * 0.15 + 1,
    );
    shadowPath.cubicTo(
      center.dx + size * 0.55 + 1, center.dy - size * 0.35 + 1,
      center.dx + size * 0.55 + 1, center.dy + size * 0.1 + 1,
      center.dx + 1, center.dy + size * 0.4,
    );
    canvas.drawPath(shadowPath, shadowPaint);

    // Main white heart
    final paint = Paint()
      ..color = _white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.35);
    path.cubicTo(
      center.dx - size * 0.55, center.dy + size * 0.1,
      center.dx - size * 0.55, center.dy - size * 0.35,
      center.dx, center.dy - size * 0.15,
    );
    path.cubicTo(
      center.dx + size * 0.55, center.dy - size * 0.35,
      center.dx + size * 0.55, center.dy + size * 0.1,
      center.dx, center.dy + size * 0.35,
    );

    canvas.drawPath(path, paint);

    // Pink/magenta outline for pop
    final outlinePaint = Paint()
      ..color = _pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outlinePaint);

    // Shine highlight
    final highlightPaint = Paint()
      ..color = _white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - size * 0.18, center.dy - size * 0.12),
      size * 0.15,
      highlightPaint,
    );
  }

  void _drawSparkles(Canvas canvas, Size size) {
    // White sparkles with glow
    for (int i = 0; i < 12; i++) {
      final x = 15 + _nextRandom() * (size.width - 30);
      final y = 3 + _nextRandom() * (size.height - 6);
      final sparkleSize = 2 + _nextRandom() * 2;

      _drawSparkle(canvas, Offset(x, y), sparkleSize);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Glow
    paint.color = _white.withValues(alpha: 0.5);
    canvas.drawCircle(center, size * 1.3, paint);

    // Core star
    paint.color = _white.withValues(alpha: 0.95);
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.2, center.dy - size * 0.2);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.2, center.dy + size * 0.2);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.2, center.dy + size * 0.2);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.2, center.dy - size * 0.2);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawEdgeHighlights(Canvas canvas, Size size) {
    // Top edge bright highlight
    final topPaint = Paint()
      ..color = _white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, 1), Offset(size.width, 1), topPaint);

    // Bottom edge shadow
    final bottomPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), bottomPaint);
  }

  @override
  bool shouldRepaint(covariant RainbowGarlandPainter oldDelegate) =>
      oldDelegate.seed != seed;
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
          seed: seed,
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
      case ShelfTextureType.rainbowSparkle:
        return RainbowSparklePainter(
          rainbowColors: theme.grainColors,
          glowColor: theme.accentGlowColor,
          sparkleColor: theme.starAccentColor,
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
          seed: seed,
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
      case ShelfTextureType.rainbowSparkle:
        return RainbowGarlandPainter(
          rainbowColors: theme.grainColors,
          glowColor: theme.accentGlowColor,
          sparkleColor: theme.starAccentColor,
          seed: seed,
        );
    }
  }
}
