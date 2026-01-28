import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../utils/theme.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final String? heroTag;
  final int? pagesRead;
  final int? totalPages;
  final bool showProgressBadge;
  final VoidCallback? onProgressTap;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.width = 120,
    this.height = 200,
    this.heroTag,
    this.pagesRead,
    this.totalPages,
    this.showProgressBadge = false,
    this.onProgressTap,
  });

  double? get _progress {
    if (pagesRead == null || totalPages == null || totalPages == 0) return null;
    return (pagesRead! / totalPages!).clamp(0.0, 1.0);
  }

  int? get _percentage => _progress != null ? (_progress! * 100).round() : null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover with shadow
            Expanded(
              flex: 3,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: heroTag ?? 'book-card-${book.isbn}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _buildCover(context),
                        ),
                      ),
                    ),
                  ),
                  // Rating badge (only show if not showing progress badge)
                  if (book.averageRating != null && !showProgressBadge)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.amber.shade400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              book.averageRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Bookmark progress badge for currently reading books
                  if (showProgressBadge)
                    Positioned(
                      top: -4,
                      right: 8,
                      child: GestureDetector(
                        onTap: onProgressTap,
                        child: _buildBookmarkBadge(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 2),
            // Author
            Text(
              book.authorsString,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    if (book.coverUrl == null) {
      return Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.secondaryColor.withValues(alpha: 0.4),
              AppTheme.primaryColor.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 28,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                book.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: book.coverUrlMedium,
      width: width,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: width,
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
        ),
        child: Icon(
          Icons.auto_stories_rounded,
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildBookmarkBadge() {
    final displayText = _percentage != null ? '$_percentage%' : '...';

    return CustomPaint(
      painter: _BookmarkPainter(color: AppTheme.currentlyReadingColor),
      child: Container(
        width: 32,
        height: 44,
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          children: [
            Text(
              displayText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
            if (_progress != null) ...[
              const SizedBox(height: 3),
              SizedBox(
                width: 20,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _progress!,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookmarkPainter extends CustomPainter {
  final Color color;

  _BookmarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    // Draw bookmark shape
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 8);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height - 8);
    path.close();

    // Draw shadow first
    canvas.save();
    canvas.translate(1, 1);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw bookmark
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
