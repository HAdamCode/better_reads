import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_book.dart';
import 'book_card.dart';
import 'update_progress_dialog.dart';

class BookCarousel extends StatefulWidget {
  final List<UserBook> books;
  final String heroTagPrefix;
  final double itemWidth;
  final double itemHeight;
  final Widget? trailingWidget;
  final bool showProgressBadges;
  final Color? progressBadgeColor;

  const BookCarousel({
    super.key,
    required this.books,
    required this.heroTagPrefix,
    this.itemWidth = 120,
    this.itemHeight = 200,
    this.trailingWidget,
    this.showProgressBadges = false,
    this.progressBadgeColor,
  });

  @override
  State<BookCarousel> createState() => _BookCarouselState();
}

class _BookCarouselState extends State<BookCarousel> {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.32, // Show ~3 books at once
    );
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.books.isEmpty) {
      return SizedBox(
        height: widget.itemHeight + 20,
        child: widget.trailingWidget != null
            ? Center(child: widget.trailingWidget!)
            : const SizedBox.shrink(),
      );
    }

    final itemCount = widget.books.length + (widget.trailingWidget != null ? 1 : 0);

    return SizedBox(
      height: widget.itemHeight + 50,
      child: PageView.builder(
        controller: _pageController,
        padEnds: false, // Start first book at left edge
        pageSnapping: true, // Snap to nearest book
        clipBehavior: Clip.none, // Allow overflow for shadows
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Trailing widget (Add button)
          if (index == widget.books.length && widget.trailingWidget != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: widget.trailingWidget!,
              ),
            );
          }

          return _buildBookItem(context, index);
        },
      ),
    );
  }

  void _showProgressDialog(BuildContext context, UserBook userBook) {
    UpdateProgressDialog.show(
      context,
      bookId: userBook.bookId,
      bookTitle: userBook.book?.title ?? 'Unknown',
      currentPage: userBook.pagesRead,
      totalPages: userBook.book?.pageCount,
    );
  }

  Widget _buildBookItem(BuildContext context, int index) {
    final userBook = widget.books[index];
    if (userBook.book == null) return const SizedBox.shrink();

    // Distance from this item to current page center
    final distanceFromCenter = (index - _currentPage).abs();
    final normalizedDistance = (distanceFromCenter / 1.5).clamp(0.0, 1.0);

    // Scale: 1.0 at center, 0.82 at edges
    final scale = 1.0 - normalizedDistance * 0.18;

    // Vertical offset: centered items are higher (more prominent)
    final yOffset = normalizedDistance * 12;

    final heroTag = '${widget.heroTagPrefix}-${userBook.bookId}';

    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: yOffset + 10),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => context.push('/book/${userBook.bookId}', extra: heroTag),
            child: Container(
              width: widget.itemWidth,
              height: widget.itemHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25 + (1 - normalizedDistance) * 0.15),
                    blurRadius: 6 + (1 - normalizedDistance) * 6,
                    offset: Offset(0, 2 + (1 - normalizedDistance) * 4),
                  ),
                ],
              ),
              child: BookCard(
                book: userBook.book!,
                heroTag: heroTag,
                width: widget.itemWidth,
                height: widget.itemHeight,
                showProgressBadge: widget.showProgressBadges,
                pagesRead: userBook.pagesRead,
                totalPages: userBook.book?.pageCount,
                onProgressTap: widget.showProgressBadges
                    ? () => _showProgressDialog(context, userBook)
                    : null,
                progressBadgeColor: widget.progressBadgeColor,
                userRating: userBook.rating,
                isInLibrary: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
