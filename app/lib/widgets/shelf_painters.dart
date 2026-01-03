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

/// Vertical filigree/scrollwork painter for romance side panels - Elegant ornate library
class FiligreeVerticalPainter extends CustomPainter {
  final Color? baseColor;
  final Color? accentColor;
  final int seed;

  // Romance color palette
  static const _blushLight = Color(0xFFFAF0EA);
  static const _blushMid = Color(0xFFE8D4D4);
  static const _roseGold = Color(0xFFB76E79);
  static const _deepRose = Color(0xFFA65D68);
  static const _gold = Color(0xFFD4AF37);

  FiligreeVerticalPainter({this.baseColor, this.accentColor, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();
    final base = baseColor ?? _roseGold;
    final accent = accentColor ?? _gold;

    // Layer 1: Base gradient (lighter center, darker edges)
    final baseGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _deepRose.withValues(alpha: 0.25),
        _blushMid.withValues(alpha: 0.1),
        _deepRose.withValues(alpha: 0.25),
      ],
    );
    paint.shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Layer 2: Subtle vertical texture lines
    paint.style = PaintingStyle.stroke;
    paint.color = _deepRose.withValues(alpha: 0.15);
    paint.strokeWidth = 0.3;
    for (double x = 2; x < size.width - 1; x += 2 + random.nextDouble()) {
      final path = Path();
      path.moveTo(x, 0);
      for (double y = 0; y < size.height; y += 10) {
        path.lineTo(x + (random.nextDouble() - 0.5) * 0.5, y + 10);
      }
      canvas.drawPath(path, paint);
    }

    // Layer 3: Elegant vertical S-curves (scrollwork)
    paint.color = base.withValues(alpha: 0.45);
    paint.strokeWidth = 1.2;
    paint.strokeCap = StrokeCap.round;

    for (double y = 8; y < size.height - 8; y += 22 + random.nextDouble() * 6) {
      final path = Path();
      final startX = 3 + random.nextDouble() * 2;
      path.moveTo(startX, y);

      // Main S-curve
      path.cubicTo(
        size.width * 0.75, y + 5 + random.nextDouble() * 3,
        size.width * 0.25, y + 14 + random.nextDouble() * 3,
        startX + 1, y + 22,
      );
      canvas.drawPath(path, paint);

      // Decorative flourish at apex
      if (y % 44 < 22) {
        _drawSmallFlourish(canvas, Offset(size.width * 0.6, y + 6), base, random);
      }
    }

    // Layer 4: Fine decorative tendrils
    paint.color = base.withValues(alpha: 0.3);
    paint.strokeWidth = 0.6;
    for (double y = 20; y < size.height - 20; y += 30 + random.nextDouble() * 15) {
      final tendrilPath = Path();
      final startX = 2 + random.nextDouble() * 3;
      tendrilPath.moveTo(startX, y);
      tendrilPath.quadraticBezierTo(
        size.width * 0.4, y - 3,
        size.width * 0.5, y + 2,
      );
      // Curl back
      tendrilPath.quadraticBezierTo(
        size.width * 0.35, y + 5,
        size.width * 0.25, y + 3,
      );
      canvas.drawPath(tendrilPath, paint);
    }

    // Layer 5: Gold accent dots and small diamonds
    paint.color = accent.withValues(alpha: 0.55);
    paint.style = PaintingStyle.fill;
    for (double y = 12; y < size.height - 12; y += 28 + random.nextDouble() * 10) {
      final x = 4 + random.nextDouble() * 5;
      // Main dot
      canvas.drawCircle(Offset(x, y), 1.8, paint);
      // Small satellite dots
      paint.color = accent.withValues(alpha: 0.35);
      canvas.drawCircle(Offset(x + 2, y - 3), 0.8, paint);
      canvas.drawCircle(Offset(x + 2, y + 3), 0.8, paint);
      paint.color = accent.withValues(alpha: 0.55);
    }

    // Layer 6: Edge highlight
    paint.style = PaintingStyle.stroke;
    paint.color = _blushLight.withValues(alpha: 0.25);
    paint.strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width - 1, 0), Offset(size.width - 1, size.height), paint);

    // Layer 7: Deep shadow on outer edge
    paint.color = _deepRose.withValues(alpha: 0.35);
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(0.5, 0), Offset(0.5, size.height), paint);
  }

  void _drawSmallFlourish(Canvas canvas, Offset center, Color color, math.Random random) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    final size = 3 + random.nextDouble() * 2;

    // Tiny decorative curl
    final path = Path();
    path.moveTo(center.dx - size, center.dy);
    path.quadraticBezierTo(
      center.dx, center.dy - size * 0.8,
      center.dx + size, center.dy,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FiligreeVerticalPainter oldDelegate) => oldDelegate.seed != seed;
}

/// Horizontal filigree/scrollwork painter for romance shelf dividers - Elegant ornate library
class FiligreeHorizontalPainter extends CustomPainter {
  final Color? baseColor;
  final Color? accentColor;
  final int seed;

  // Romance color palette
  static const _blushLight = Color(0xFFFAF0EA);
  static const _blushMid = Color(0xFFE8D4D4);
  static const _roseGold = Color(0xFFB76E79);
  static const _deepRose = Color(0xFFA65D68);
  static const _gold = Color(0xFFD4AF37);

  FiligreeHorizontalPainter({this.baseColor, this.accentColor, this.seed = 123});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();
    final base = baseColor ?? _roseGold;
    final accent = accentColor ?? _gold;

    // Layer 1: Base gradient
    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _deepRose.withValues(alpha: 0.2),
        _blushMid.withValues(alpha: 0.08),
        _deepRose.withValues(alpha: 0.25),
      ],
    );
    paint.shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Layer 2: Subtle horizontal texture lines
    paint.style = PaintingStyle.stroke;
    paint.color = _deepRose.withValues(alpha: 0.12);
    paint.strokeWidth = 0.3;
    for (double y = 2; y < size.height - 1; y += 1.5 + random.nextDouble() * 0.5) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 15) {
        path.lineTo(x + 15, y + (random.nextDouble() - 0.5) * 0.3);
      }
      canvas.drawPath(path, paint);
    }

    // Layer 3: Main scrollwork pattern (elegant waves)
    paint.color = base.withValues(alpha: 0.4);
    paint.strokeWidth = 1.0;
    paint.strokeCap = StrokeCap.round;

    final midY = size.height / 2;

    // Upper wave pattern
    for (double x = 15; x < size.width - 15; x += 35 + random.nextDouble() * 10) {
      final path = Path();
      path.moveTo(x, midY);
      path.cubicTo(
        x + 8, midY - 3.5,
        x + 27, midY - 3.5,
        x + 35, midY,
      );
      canvas.drawPath(path, paint);

      // Small decorative curl at peak
      if ((x ~/ 35) % 2 == 0) {
        _drawTinyCurl(canvas, Offset(x + 17, midY - 4), base, true);
      }
    }

    // Lower wave pattern (offset)
    for (double x = 30; x < size.width - 30; x += 35 + random.nextDouble() * 10) {
      final path = Path();
      path.moveTo(x, midY);
      path.cubicTo(
        x + 8, midY + 3,
        x + 27, midY + 3,
        x + 35, midY,
      );
      canvas.drawPath(path, paint);

      // Small decorative curl at trough
      if ((x ~/ 35) % 2 == 1) {
        _drawTinyCurl(canvas, Offset(x + 17, midY + 4), base, false);
      }
    }

    // Layer 4: Gold accent elements
    paint.style = PaintingStyle.fill;

    // Main accent diamonds
    for (double x = 45 + random.nextDouble() * 20; x < size.width - 45; x += 70 + random.nextDouble() * 25) {
      _drawOrnamentedDiamond(canvas, x, midY, 3.0, accent);
    }

    // Small accent dots along the top and bottom edges
    paint.color = accent.withValues(alpha: 0.4);
    for (double x = 20; x < size.width - 20; x += 25 + random.nextDouble() * 10) {
      canvas.drawCircle(Offset(x, 3), 1.0, paint);
      canvas.drawCircle(Offset(x + 12, size.height - 3), 1.0, paint);
    }

    // Layer 5: Decorative border lines
    paint.style = PaintingStyle.stroke;
    paint.color = base.withValues(alpha: 0.3);
    paint.strokeWidth = 0.8;

    // Double line at top
    canvas.drawLine(Offset(0, 1.5), Offset(size.width, 1.5), paint);
    paint.color = base.withValues(alpha: 0.15);
    paint.strokeWidth = 0.5;
    canvas.drawLine(Offset(0, 3.5), Offset(size.width, 3.5), paint);

    // Double line at bottom
    paint.color = base.withValues(alpha: 0.3);
    paint.strokeWidth = 0.8;
    canvas.drawLine(Offset(0, size.height - 1.5), Offset(size.width, size.height - 1.5), paint);
    paint.color = base.withValues(alpha: 0.15);
    paint.strokeWidth = 0.5;
    canvas.drawLine(Offset(0, size.height - 3.5), Offset(size.width, size.height - 3.5), paint);

    // Layer 6: Top highlight
    paint.color = _blushLight.withValues(alpha: 0.2);
    paint.strokeWidth = 1.0;
    canvas.drawLine(Offset(0, 1), Offset(size.width, 1), paint);

    // Layer 7: Bottom shadow
    paint.color = _deepRose.withValues(alpha: 0.3);
    paint.strokeWidth = 1.2;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), paint);
  }

  void _drawTinyCurl(Canvas canvas, Offset center, Color color, bool upward) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    final dir = upward ? -1.0 : 1.0;
    final path = Path();
    path.moveTo(center.dx - 3, center.dy);
    path.quadraticBezierTo(
      center.dx, center.dy + dir * 2,
      center.dx + 3, center.dy,
    );
    canvas.drawPath(path, paint);
  }

  void _drawOrnamentedDiamond(Canvas canvas, double cx, double cy, double size, Color color) {
    final paint = Paint();

    // Outer glow
    paint.color = color.withValues(alpha: 0.2);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), size * 1.5, paint);

    // Main diamond
    paint.color = color.withValues(alpha: 0.5);
    final path = Path();
    path.moveTo(cx, cy - size);
    path.lineTo(cx + size * 0.6, cy);
    path.lineTo(cx, cy + size);
    path.lineTo(cx - size * 0.6, cy);
    path.close();
    canvas.drawPath(path, paint);

    // Inner highlight
    paint.color = color.withValues(alpha: 0.7);
    final innerPath = Path();
    innerPath.moveTo(cx, cy - size * 0.4);
    innerPath.lineTo(cx + size * 0.25, cy);
    innerPath.lineTo(cx, cy + size * 0.4);
    innerPath.lineTo(cx - size * 0.25, cy);
    innerPath.close();
    canvas.drawPath(innerPath, paint);

    // Tiny dots around the diamond
    paint.color = color.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(cx - size * 1.2, cy), 0.8, paint);
    canvas.drawCircle(Offset(cx + size * 1.2, cy), 0.8, paint);
  }

  @override
  bool shouldRepaint(covariant FiligreeHorizontalPainter oldDelegate) => oldDelegate.seed != seed;
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
    }
  }
}
