import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../utils/theme.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.width = 120,
    this.height = 200,
  });

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
              child: Hero(
                tag: 'book-${book.isbn}',
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
      fit: BoxFit.cover,
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
}
