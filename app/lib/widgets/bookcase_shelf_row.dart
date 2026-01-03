import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_book.dart';
import '../utils/theme.dart';
import 'book_card.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    // Don't render if empty and showEmptyState is false
    if (books.isEmpty && !showEmptyState) {
      return const SizedBox.shrink();
    }

    return Container(
      color: const Color(0xFF5D3A1A), // Wood background for entire shelf
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shelf Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? AppTheme.secondaryColor, size: 22),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryColor,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.secondaryColor.withValues(alpha: 0.7),
                              ),
                        ),
                    ],
                  ),
                ),
              ),
              if (onTitleTap != null)
                Icon(Icons.chevron_right, color: AppTheme.secondaryColor.withValues(alpha: 0.7), size: 20),
            ],
          ),
        ),

        // Bookshelf with side panels and back
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left side panel
              _buildSidePanel(isLeft: true),

              // Back panel with books
              Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // Dark wood panel background
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF3D2817), // Dark wood top
                      const Color(0xFF4A3222), // Slightly lighter middle
                      const Color(0xFF3D2817), // Dark wood bottom
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Column(
                  children: [
                    // Top edge shadow line
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
                      _buildEmptyState(context)
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: books.length + (onAddTap != null ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              // Add button at the end
                              if (index == books.length && onAddTap != null) {
                                return _buildAddButton(context);
                              }

                              final userBook = books[index];
                              if (userBook.book == null) return const SizedBox.shrink();

                              final heroTag = '$heroTagPrefix-${userBook.bookId}';
                              return BookCard(
                                book: userBook.book!,
                                heroTag: heroTag,
                                onTap: () => context.push('/book/${userBook.bookId}', extra: heroTag),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Right side panel
            _buildSidePanel(isLeft: false),
          ],
        ),
        ),

        // Wooden Shelf
        const WoodenShelfDivider(margin: EdgeInsets.zero),
      ],
      ),
    );
  }

  Widget _buildSidePanel({required bool isLeft}) {
    return Container(
      width: 14,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            const Color(0xFF5D3A1A), // Inner edge (darker)
            AppTheme.primaryColor,   // Middle
            AppTheme.secondaryColor, // Outer edge (lighter, catches light)
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        boxShadow: [
          // Inner shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: Offset(isLeft ? 2 : -2, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (emptyStateWidget != null) {
      return emptyStateWidget!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        height: 170,
        child: Row(
          children: [
            if (onAddTap != null) _buildAddButton(context),
            if (onAddTap != null) const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No books yet',
                style: TextStyle(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddTap,
      child: Container(
        width: 120,
        height: 170,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppTheme.secondaryColor.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 28,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Books',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
