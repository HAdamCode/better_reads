import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/shelf_theme.dart';
import '../models/user_book.dart';
import 'book_carousel.dart';
import 'shelf_painters.dart';
import 'wooden_shelf_divider.dart';

class BookcaseShelfRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final List<UserBook> books;
  final String heroTagPrefix;
  final VoidCallback? onTitleTap;
  final VoidCallback? onAddTap;
  final bool showEmptyState;
  final Widget? emptyStateWidget;
  final ShelfTheme? theme;

  const BookcaseShelfRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.books,
    required this.heroTagPrefix,
    this.onTitleTap,
    this.onAddTap,
    this.showEmptyState = true,
    this.emptyStateWidget,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Don't render if empty and showEmptyState is false
    if (books.isEmpty && !showEmptyState) {
      return const SizedBox.shrink();
    }

    final currentTheme = theme ?? ShelfTheme.classicWood();
    final isMinimalist = currentTheme.type == ShelfThemeType.minimalist;
    // Use title hashCode as seed for unique star patterns per shelf
    final shelfSeed = title.hashCode.abs();

    return Container(
      color: currentTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shelf Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: iconColor ?? currentTheme.iconColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: onTitleTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: currentTheme.headerStyle(
                            fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: currentTheme.bodyStyle(
                              fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (onTitleTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: currentTheme.textSecondaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),

          // Top shelf (skip for minimalist)
          if (!isMinimalist)
            WoodenShelfDivider(isTop: true, margin: EdgeInsets.zero, theme: currentTheme, seed: shelfSeed),

          // Bookshelf with side panels and back
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left side panel (skip for minimalist)
                if (!isMinimalist) _buildSidePanel(isLeft: true, theme: currentTheme, seed: shelfSeed),

                // Back panel with books
                Expanded(
                  child: Container(
                    decoration: isMinimalist
                        ? null
                        : BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                currentTheme.backPanelTopColor,
                                currentTheme.backPanelMiddleColor,
                                currentTheme.backPanelBottomColor,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                    child: Column(
                      children: [
                        // Top edge shadow line (skip for minimalist)
                        if (!isMinimalist)
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        // Books Row or Empty State
                        if (books.isEmpty)
                          _buildEmptyState(context, currentTheme)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: BookCarousel(
                              books: books,
                              heroTagPrefix: heroTagPrefix,
                              trailingWidget: onAddTap != null
                                  ? _buildAddButton(context, currentTheme)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Right side panel (skip for minimalist)
                if (!isMinimalist) _buildSidePanel(isLeft: false, theme: currentTheme, seed: shelfSeed + 1),
              ],
            ),
          ),

          // Bottom Shelf
          WoodenShelfDivider(margin: EdgeInsets.zero, theme: currentTheme, seed: shelfSeed + 2),
        ],
      ),
    );
  }

  Widget _buildSidePanel({required bool isLeft, required ShelfTheme theme, int seed = 42}) {
    return Container(
      width: theme.sidePanelWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            theme.sidePanelInnerColor,
            theme.sidePanelMiddleColor,
            theme.sidePanelOuterColor,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: Offset(isLeft ? 2 : -2, 0),
          ),
        ],
      ),
      child: CustomPaint(
        painter: ShelfPainterFactory.getSidePanelPainter(theme, seed: seed),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ShelfTheme theme) {
    if (emptyStateWidget != null) {
      return emptyStateWidget!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        height: 170,
        child: Row(
          children: [
            if (onAddTap != null) _buildAddButton(context, theme),
            if (onAddTap != null) const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No books yet',
                style: theme.bodyStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ShelfTheme theme) {
    final isMinimalist = theme.type == ShelfThemeType.minimalist;
    final isFantasy = theme.type == ShelfThemeType.fantasy;
    final isRomance = theme.type == ShelfThemeType.romance;

    final content = Container(
      width: 120,
      height: 170,
      decoration: BoxDecoration(
        color: isMinimalist
            ? theme.dividerMiddleColor.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: isFantasy
            ? null
            : Border.all(
                color: theme.textSecondaryColor.withValues(alpha: 0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isRomance
              ? ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    theme.textPrimaryColor,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/rose_image.png',
                    width: 72,
                    height: 72,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.textPrimaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: isFantasy
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            theme.textPrimaryColor,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/images/image.png',
                            width: 28,
                            height: 28,
                          ),
                        )
                      : Icon(
                          Icons.add,
                          size: 28,
                          color: theme.textPrimaryColor,
                        ),
                ),
          const SizedBox(height: 10),
          Text(
            'Add Books',
            style: theme.bodyStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onAddTap,
      child: isFantasy
          ? CustomPaint(
              painter: _VineBorderPainter(seed: title.hashCode),
              child: content,
            )
          : isRomance
              ? CustomPaint(
                  painter: _RoseBorderPainter(seed: title.hashCode),
                  child: content,
                )
              : content,
    );
  }
}

/// Custom painter for vine border (fantasy theme) with realistic botanical details
/// All leaves, tendrils, and branches grow FROM the main vine stem
class _VineBorderPainter extends CustomPainter {
  final int seed;

  _VineBorderPainter({this.seed = 42});

  // Deterministic random based on seed + index (stable across repaints)
  double _seededRandom(int index) {
    final hash = (seed * 31 + index * 17) & 0x7FFFFFFF;
    return (hash % 10000) / 10000.0;
  }

  // Counter for generating unique indices for each random call
  int _randomIndex = 0;

  double _nextRandom() {
    return _seededRandom(_randomIndex++);
  }

  double _vary(double base, double range) {
    return base + (_nextRandom() - 0.5) * range;
  }

  // Color palette
  static const _vineDark = Color(0xFF1A4028);
  static const _vineColor = Color(0xFF2D5A3E);
  static const _vineLight = Color(0xFF4A8A5E);
  static const _leafMid = Color(0xFF3D7A4A);
  static const _leafLight = Color(0xFF5AA868);
  static const _shadowColor = Color(0xFF0A2010);
  static const _leafHighlight = Color(0xFF7AC888);

  // Deterministic int based on seed (for point counts)
  int _seededInt(int index, int max) {
    final hash = (seed * 31 + index * 17) & 0x7FFFFFFF;
    return hash % max;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Reset random counter for consistent results
    _randomIndex = 0;

    // Build the vine path and sample points along it
    final vinePoints = _getVinePoints(size);

    // Layer 1: Shadow
    _drawShadowLayer(canvas, size);

    // Layer 2: Main vine stem
    _drawMainVine(canvas, size);

    // Layer 3: Draw leaves, tendrils, buds connected to vine points
    _drawConnectedElements(canvas, vinePoints);
  }

  /// Get points along the vine path where we can attach leaves/tendrils
  /// All positions are randomized based on seed for unique patterns per shelf
  List<_VinePoint> _getVinePoints(Size size) {
    final points = <_VinePoint>[];

    // Generate random points for each side based on seed
    // Left side (5-8 points)
    final leftCount = 5 + _seededInt(0, 4);
    for (int i = 0; i < leftCount; i++) {
      final progress = (i + 0.5) / leftCount; // Distribute along side
      final jitter = _vary(0.0, 0.08); // Random offset
      _addRandomPoint(points, size, _VineSide.left, progress + jitter, i);
    }

    // Top side (4-7 points)
    final topCount = 4 + _seededInt(1, 4);
    for (int i = 0; i < topCount; i++) {
      final progress = (i + 0.5) / topCount;
      final jitter = _vary(0.0, 0.08);
      _addRandomPoint(points, size, _VineSide.top, progress + jitter, i);
    }

    // Right side (5-8 points)
    final rightCount = 5 + _seededInt(2, 4);
    for (int i = 0; i < rightCount; i++) {
      final progress = (i + 0.5) / rightCount;
      final jitter = _vary(0.0, 0.08);
      _addRandomPoint(points, size, _VineSide.right, progress + jitter, i);
    }

    // Bottom side (4-7 points)
    final bottomCount = 4 + _seededInt(3, 4);
    for (int i = 0; i < bottomCount; i++) {
      final progress = (i + 0.5) / bottomCount;
      final jitter = _vary(0.0, 0.08);
      _addRandomPoint(points, size, _VineSide.bottom, progress + jitter, i);
    }

    return points;
  }

  /// Add a single point with randomized position and angle
  void _addRandomPoint(List<_VinePoint> points, Size size, _VineSide side, double progress, int index) {
    progress = progress.clamp(0.05, 0.95); // Keep away from corners
    final alternateSign = (index % 2 == 0) ? 1.0 : -1.0;
    final sizeVariation = _vary(1.0, 0.4); // More size variation
    final edgeOffset = _vary(5.0, 4.0); // Random distance from edge

    double x, y, baseAngle;

    switch (side) {
      case _VineSide.left:
        x = edgeOffset;
        y = size.height * progress;
        baseAngle = alternateSign > 0 ? _vary(0.5, 0.4) : _vary(math.pi - 0.5, 0.4);
        break;
      case _VineSide.right:
        x = size.width - edgeOffset;
        y = size.height * progress;
        baseAngle = alternateSign > 0 ? _vary(math.pi - 0.5, 0.4) : _vary(0.5, 0.4);
        break;
      case _VineSide.top:
        x = size.width * progress;
        y = edgeOffset;
        baseAngle = alternateSign > 0 ? _vary(math.pi / 2 + 0.3, 0.4) : _vary(-math.pi / 2 + 0.3, 0.4);
        break;
      case _VineSide.bottom:
        x = size.width * progress;
        y = size.height - edgeOffset;
        baseAngle = alternateSign > 0 ? _vary(-math.pi / 2 - 0.3, 0.4) : _vary(math.pi / 2 - 0.3, 0.4);
        break;
    }

    points.add(_VinePoint(x, y, baseAngle, side, sizeVariation));
  }

  void _drawShadowLayer(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = _shadowColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(1.5, 1.5);
    _drawVinePath(canvas, size, shadowPaint);
    canvas.restore();
  }

  void _drawMainVine(Canvas canvas, Size size) {
    final vinePaint = Paint()
      ..color = _vineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = _vineLight.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    _drawVinePath(canvas, size, vinePaint);
    _drawVinePath(canvas, size, highlightPaint);
  }

  void _drawVinePath(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Start at bottom-left, go up the left side
    path.moveTo(4, size.height - 8);
    path.cubicTo(
      8, size.height * 0.78,
      0, size.height * 0.65,
      6, size.height * 0.52,
    );
    path.cubicTo(
      10, size.height * 0.38,
      2, size.height * 0.25,
      7, size.height * 0.12,
    );
    path.cubicTo(
      10, size.height * 0.04,
      size.width * 0.08, 2,
      size.width * 0.18, 4,
    );

    // Go across the top
    path.cubicTo(
      size.width * 0.32, 8,
      size.width * 0.42, 2,
      size.width * 0.55, 6,
    );
    path.cubicTo(
      size.width * 0.72, 10,
      size.width * 0.85, 3,
      size.width - 6, size.height * 0.1,
    );

    // Go down the right side
    path.cubicTo(
      size.width - 2, size.height * 0.25,
      size.width - 10, size.height * 0.38,
      size.width - 5, size.height * 0.5,
    );
    path.cubicTo(
      size.width - 1, size.height * 0.65,
      size.width - 9, size.height * 0.78,
      size.width - 4, size.height * 0.88,
    );
    path.cubicTo(
      size.width - 2, size.height * 0.95,
      size.width * 0.9, size.height - 3,
      size.width * 0.82, size.height - 5,
    );

    // Go across the bottom back to start
    path.cubicTo(
      size.width * 0.68, size.height - 9,
      size.width * 0.55, size.height - 2,
      size.width * 0.42, size.height - 6,
    );
    path.cubicTo(
      size.width * 0.28, size.height - 10,
      size.width * 0.15, size.height - 3,
      4, size.height - 8,
    );

    canvas.drawPath(path, paint);
  }

  void _drawConnectedElements(Canvas canvas, List<_VinePoint> points) {
    int leafIndex = 0;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final elementType = i % 3; // Alternate between leaf, tendril, small leaf
      final sizeMult = point.sizeMultiplier;

      if (elementType == 0) {
        // Draw a leaf with petiole (stem)
        _drawLeafFromVine(canvas, point, _vary(10, 3) * sizeMult, leafIndex % 2 == 0);
        leafIndex++;
      } else if (elementType == 1) {
        // Draw a tendril
        _drawTendrilFromVine(canvas, point, _vary(12, 4) * sizeMult);
      } else {
        // Draw a smaller leaf or bud
        if (i % 5 == 0) {
          _drawBudFromVine(canvas, point, _vary(4, 1) * sizeMult);
        } else {
          _drawLeafFromVine(canvas, point, _vary(7, 2) * sizeMult, leafIndex % 2 == 0);
          leafIndex++;
        }
      }
    }
  }

  /// Draw a leaf that grows FROM the vine point with a visible petiole (leaf stem)
  void _drawLeafFromVine(Canvas canvas, _VinePoint point, double leafSize, bool isHeart) {
    final petioleLength = leafSize * 0.5;
    final petioleAngle = point.outwardAngle + _vary(0, 0.3);

    // Calculate where the leaf attaches (end of petiole)
    final leafX = point.x + math.cos(petioleAngle) * petioleLength;
    final leafY = point.y + math.sin(petioleAngle) * petioleLength;

    // Draw petiole (leaf stem) connecting vine to leaf
    final petiolePaint = Paint()
      ..color = _vineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final petiolePath = Path();
    petiolePath.moveTo(point.x, point.y);
    // Slight curve to the petiole
    final midX = point.x + math.cos(petioleAngle) * petioleLength * 0.5;
    final midY = point.y + math.sin(petioleAngle) * petioleLength * 0.5 - 2;
    petiolePath.quadraticBezierTo(midX, midY, leafX, leafY);
    canvas.drawPath(petiolePath, petiolePaint);

    // Draw the leaf at the end of the petiole
    if (isHeart) {
      _drawHeartLeaf(canvas, leafX, leafY, leafSize, petioleAngle + math.pi / 2);
    } else {
      _drawPointedLeaf(canvas, leafX, leafY, leafSize, petioleAngle + math.pi / 2);
    }
  }

  /// Draw a tendril that grows FROM the vine point
  void _drawTendrilFromVine(Canvas canvas, _VinePoint point, double length) {
    final tendrilPaint = Paint()
      ..color = _vineLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final angle = point.outwardAngle;
    final dir = point.side == _VineSide.left || point.side == _VineSide.top ? 1.0 : -1.0;

    final path = Path();
    path.moveTo(point.x, point.y);

    // First segment going outward from vine
    final seg1X = point.x + math.cos(angle) * length * 0.4;
    final seg1Y = point.y + math.sin(angle) * length * 0.4;
    path.quadraticBezierTo(
      point.x + math.cos(angle) * length * 0.2,
      point.y + math.sin(angle) * length * 0.2 - 3,
      seg1X, seg1Y,
    );

    // Curl back
    final seg2X = seg1X + dir * length * 0.3;
    final seg2Y = seg1Y + length * 0.3;
    path.quadraticBezierTo(
      seg1X + dir * length * 0.25,
      seg1Y - length * 0.1,
      seg2X, seg2Y,
    );

    // Tight spiral
    path.quadraticBezierTo(
      seg2X - dir * length * 0.15,
      seg2Y + length * 0.15,
      seg2X - dir * length * 0.05,
      seg2Y + length * 0.08,
    );

    canvas.drawPath(path, tendrilPaint);
  }

  /// Draw a small bud FROM the vine point
  void _drawBudFromVine(Canvas canvas, _VinePoint point, double budSize) {
    final angle = point.outwardAngle;

    // Short stem to bud
    final stemLength = budSize * 0.8;
    final budX = point.x + math.cos(angle) * stemLength;
    final budY = point.y + math.sin(angle) * stemLength;

    // Draw tiny stem
    final stemPaint = Paint()
      ..color = _vineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(point.x, point.y), Offset(budX, budY), stemPaint);

    // Draw bud
    canvas.save();
    canvas.translate(budX, budY);
    canvas.rotate(angle + math.pi / 2);

    final budPath = Path();
    budPath.moveTo(0, budSize * 0.3);
    budPath.quadraticBezierTo(-budSize * 0.35, 0, -budSize * 0.15, -budSize * 0.35);
    budPath.quadraticBezierTo(0, -budSize * 0.45, budSize * 0.12, -budSize * 0.25);
    budPath.quadraticBezierTo(budSize * 0.15, -budSize * 0.05, 0, budSize * 0.3);

    final budPaint = Paint()
      ..color = _leafLight
      ..style = PaintingStyle.fill;
    canvas.drawPath(budPath, budPaint);

    final outlinePaint = Paint()
      ..color = _vineColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(budPath, outlinePaint);

    canvas.restore();
  }

  void _drawHeartLeaf(Canvas canvas, double x, double y, double leafSize, double angle) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final lobeDepth = _vary(0.45, 0.08);

    final leafPath = Path();
    leafPath.moveTo(0, leafSize * 0.45);
    leafPath.cubicTo(
      -leafSize * lobeDepth, leafSize * 0.15,
      -leafSize * lobeDepth, -leafSize * 0.25,
      0, -leafSize * 0.12,
    );
    leafPath.cubicTo(
      leafSize * lobeDepth, -leafSize * 0.25,
      leafSize * lobeDepth, leafSize * 0.15,
      0, leafSize * 0.45,
    );

    // Shadow
    canvas.save();
    canvas.translate(1, 1);
    final shadowPaint = Paint()
      ..color = _shadowColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, shadowPaint);
    canvas.restore();

    // Leaf fill
    final leafPaint = Paint()
      ..color = _leafMid
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, leafPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = _vineDark.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawPath(leafPath, outlinePaint);

    // Central vein
    final veinPaint = Paint()
      ..color = _vineDark.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, leafSize * 0.4), Offset(0, -leafSize * 0.05), veinPaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = _leafHighlight.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final highlightPath = Path();
    highlightPath.addOval(Rect.fromCenter(
      center: Offset(-leafSize * 0.12, leafSize * 0.05),
      width: leafSize * 0.25,
      height: leafSize * 0.35,
    ));
    canvas.drawPath(highlightPath, highlightPaint);

    canvas.restore();
  }

  void _drawPointedLeaf(Canvas canvas, double x, double y, double leafSize, double angle) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final width = _vary(0.32, 0.06);

    final leafPath = Path();
    leafPath.moveTo(0, leafSize * 0.45);
    leafPath.quadraticBezierTo(-leafSize * width, leafSize * 0.08, -leafSize * 0.12, -leafSize * 0.35);
    leafPath.quadraticBezierTo(0, -leafSize * 0.55, leafSize * 0.12, -leafSize * 0.35);
    leafPath.quadraticBezierTo(leafSize * width, leafSize * 0.08, 0, leafSize * 0.45);

    // Shadow
    canvas.save();
    canvas.translate(0.8, 0.8);
    final shadowPaint = Paint()
      ..color = _shadowColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, shadowPaint);
    canvas.restore();

    // Leaf fill
    final leafPaint = Paint()
      ..color = _leafMid
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, leafPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = _vineDark.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(leafPath, outlinePaint);

    // Central vein
    final veinPaint = Paint()
      ..color = _vineDark.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, leafSize * 0.38), Offset(0, -leafSize * 0.3), veinPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VineBorderPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

/// Represents a point on the vine where elements can attach
class _VinePoint {
  final double x;
  final double y;
  final double outwardAngle; // Angle pointing away from the vine (for leaf/tendril direction)
  final _VineSide side;
  final double sizeMultiplier; // Random size variation (0.7-1.3)

  _VinePoint(this.x, this.y, this.outwardAngle, this.side, [this.sizeMultiplier = 1.0]);
}

enum _VineSide { left, top, right, bottom }

/// Custom painter for ornate rose border (romance theme)
/// Beauty and the Beast / Bridgerton aesthetic with baroque scrollwork and roses
class _RoseBorderPainter extends CustomPainter {
  final int seed;

  _RoseBorderPainter({this.seed = 42});

  // Romance color palette
  static const _roseGold = Color(0xFFB76E79);
  static const _enchantedRose = Color(0xFF8B2942);
  static const _velvetBurgundy = Color(0xFF5C1A2B);
  static const _antiqueGold = Color(0xFFC9A84C);
  static const _pearlWhite = Color(0xFFF8F4F0);
  static const _champagneRose = Color(0xFFF5DFD7);

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

    // Layer 1: Soft shadow
    _drawShadow(canvas, size);

    // Layer 2: Ornate scrollwork border
    _drawScrollworkBorder(canvas, size);

    // Layer 3: Corner roses
    _drawCornerRoses(canvas, size);

    // Layer 4: Pearl accents
    _drawPearlAccents(canvas, size);

    // Layer 5: Gold sparkles
    _drawSparkles(canvas, size);
  }

  void _drawShadow(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = _velvetBurgundy.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final path = _createBorderPath(size, 2);
    canvas.save();
    canvas.translate(1.5, 1.5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();
  }

  void _drawScrollworkBorder(Canvas canvas, Size size) {
    // Main border stroke
    final borderPaint = Paint()
      ..color = _roseGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = _createBorderPath(size, 0);
    canvas.drawPath(path, borderPaint);

    // Inner highlight
    final highlightPaint = Paint()
      ..color = _champagneRose.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(-0.5, -0.5);
    canvas.drawPath(path, highlightPaint);
    canvas.restore();

    // Draw baroque flourishes along edges
    _drawEdgeFlourishes(canvas, size);
  }

  Path _createBorderPath(Size size, double inset) {
    final path = Path();
    final cornerRadius = 8.0;

    // Start at top-left after corner curve
    path.moveTo(inset + cornerRadius + 4, inset + 4);

    // Top edge with gentle wave
    for (double x = cornerRadius + 8; x < size.width - cornerRadius - 8; x += 24) {
      final waveY = inset + 4 + math.sin(x * 0.15) * 1.5;
      path.lineTo(x, waveY);
    }
    path.lineTo(size.width - inset - cornerRadius - 4, inset + 4);

    // Top-right corner flourish
    path.quadraticBezierTo(
      size.width - inset - 2, inset + 2,
      size.width - inset - 4, inset + cornerRadius + 4,
    );

    // Right edge with gentle wave
    for (double y = cornerRadius + 8; y < size.height - cornerRadius - 8; y += 24) {
      final waveX = size.width - inset - 4 + math.sin(y * 0.15) * 1.5;
      path.lineTo(waveX, y);
    }
    path.lineTo(size.width - inset - 4, size.height - inset - cornerRadius - 4);

    // Bottom-right corner flourish
    path.quadraticBezierTo(
      size.width - inset - 2, size.height - inset - 2,
      size.width - inset - cornerRadius - 4, size.height - inset - 4,
    );

    // Bottom edge with gentle wave
    for (double x = size.width - cornerRadius - 8; x > cornerRadius + 8; x -= 24) {
      final waveY = size.height - inset - 4 + math.sin(x * 0.15) * 1.5;
      path.lineTo(x, waveY);
    }
    path.lineTo(inset + cornerRadius + 4, size.height - inset - 4);

    // Bottom-left corner flourish
    path.quadraticBezierTo(
      inset + 2, size.height - inset - 2,
      inset + 4, size.height - inset - cornerRadius - 4,
    );

    // Left edge with gentle wave
    for (double y = size.height - cornerRadius - 8; y > cornerRadius + 8; y -= 24) {
      final waveX = inset + 4 + math.sin(y * 0.15) * 1.5;
      path.lineTo(waveX, y);
    }
    path.lineTo(inset + 4, inset + cornerRadius + 4);

    // Top-left corner flourish
    path.quadraticBezierTo(
      inset + 2, inset + 2,
      inset + cornerRadius + 4, inset + 4,
    );

    path.close();
    return path;
  }

  void _drawEdgeFlourishes(Canvas canvas, Size size) {
    final flourishPaint = Paint()
      ..color = _roseGold.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Top edge flourishes
    for (double x = 30; x < size.width - 30; x += 40) {
      _drawSmallFlourish(canvas, Offset(x, 8), flourishPaint, true);
    }

    // Bottom edge flourishes
    for (double x = 30; x < size.width - 30; x += 40) {
      _drawSmallFlourish(canvas, Offset(x, size.height - 8), flourishPaint, false);
    }

    // Left edge flourishes
    for (double y = 40; y < size.height - 40; y += 35) {
      _drawSideFlourish(canvas, Offset(8, y), flourishPaint, true);
    }

    // Right edge flourishes
    for (double y = 40; y < size.height - 40; y += 35) {
      _drawSideFlourish(canvas, Offset(size.width - 8, y), flourishPaint, false);
    }
  }

  void _drawSmallFlourish(Canvas canvas, Offset center, Paint paint, bool isTop) {
    final dir = isTop ? 1.0 : -1.0;
    final path = Path();

    // S-curve flourish
    path.moveTo(center.dx - 8, center.dy);
    path.cubicTo(
      center.dx - 4, center.dy + dir * 4,
      center.dx + 4, center.dy - dir * 4,
      center.dx + 8, center.dy,
    );

    canvas.drawPath(path, paint);

    // Small curl at end
    final curlPath = Path();
    curlPath.moveTo(center.dx + 8, center.dy);
    curlPath.quadraticBezierTo(
      center.dx + 11, center.dy + dir * 2,
      center.dx + 9, center.dy + dir * 4,
    );
    canvas.drawPath(curlPath, paint);
  }

  void _drawSideFlourish(Canvas canvas, Offset center, Paint paint, bool isLeft) {
    final dir = isLeft ? 1.0 : -1.0;
    final path = Path();

    // Vertical S-curve
    path.moveTo(center.dx, center.dy - 6);
    path.cubicTo(
      center.dx + dir * 4, center.dy - 3,
      center.dx - dir * 4, center.dy + 3,
      center.dx, center.dy + 6,
    );

    canvas.drawPath(path, paint);
  }

  void _drawCornerRoses(Canvas canvas, Size size) {
    // Draw a stylized rose at each corner
    _drawRose(canvas, Offset(12, 12), 10); // Top-left
    _drawRose(canvas, Offset(size.width - 12, 12), 10); // Top-right
    _drawRose(canvas, Offset(12, size.height - 12), 10); // Bottom-left
    _drawRose(canvas, Offset(size.width - 12, size.height - 12), 10); // Bottom-right
  }

  void _drawRose(Canvas canvas, Offset center, double roseSize) {
    // Outer petals
    final petalPaint = Paint()
      ..color = _enchantedRose
      ..style = PaintingStyle.fill;

    final petalOutline = Paint()
      ..color = _velvetBurgundy.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw 5 overlapping petals in a spiral
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72) * math.pi / 180 + _nextRandom() * 0.3;
      final petalPath = Path();

      final petalLength = roseSize * (0.8 - i * 0.08);
      final petalWidth = roseSize * 0.5;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      petalPath.moveTo(0, 0);
      petalPath.cubicTo(
        -petalWidth * 0.5, -petalLength * 0.3,
        -petalWidth * 0.3, -petalLength * 0.8,
        0, -petalLength,
      );
      petalPath.cubicTo(
        petalWidth * 0.3, -petalLength * 0.8,
        petalWidth * 0.5, -petalLength * 0.3,
        0, 0,
      );

      canvas.drawPath(petalPath, petalPaint);
      canvas.drawPath(petalPath, petalOutline);
      canvas.restore();
    }

    // Rose center with gold accent
    final centerPaint = Paint()
      ..color = _antiqueGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, roseSize * 0.2, centerPaint);

    // Tiny highlight on center
    final highlightPaint = Paint()
      ..color = _pearlWhite.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - roseSize * 0.05, center.dy - roseSize * 0.05),
      roseSize * 0.08,
      highlightPaint,
    );
  }

  void _drawPearlAccents(Canvas canvas, Size size) {
    final pearlPaint = Paint()
      ..color = _pearlWhite
      ..style = PaintingStyle.fill;

    final pearlHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Pearl dots along edges
    // Top edge
    for (double x = 50; x < size.width - 50; x += 30) {
      final offset = Offset(x + _nextRandom() * 4 - 2, 4);
      _drawPearl(canvas, offset, 2.0, pearlPaint, pearlHighlight);
    }

    // Bottom edge
    for (double x = 50; x < size.width - 50; x += 30) {
      final offset = Offset(x + _nextRandom() * 4 - 2, size.height - 4);
      _drawPearl(canvas, offset, 2.0, pearlPaint, pearlHighlight);
    }
  }

  void _drawPearl(Canvas canvas, Offset center, double radius, Paint basePaint, Paint highlightPaint) {
    // Pearl base
    canvas.drawCircle(center, radius, basePaint);

    // Highlight
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.4,
      highlightPaint,
    );
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final sparklePaint = Paint()
      ..color = _antiqueGold.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Sparse sparkles near corners and roses
    final sparklePositions = [
      Offset(25, 20),
      Offset(size.width - 25, 22),
      Offset(22, size.height - 25),
      Offset(size.width - 22, size.height - 22),
      Offset(size.width / 2, 6),
      Offset(size.width / 2, size.height - 6),
    ];

    for (final pos in sparklePositions) {
      _drawSparkle(canvas, pos, 2.5 + _nextRandom() * 1.5, sparklePaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    // 4-point star sparkle
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

  @override
  bool shouldRepaint(covariant _RoseBorderPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
