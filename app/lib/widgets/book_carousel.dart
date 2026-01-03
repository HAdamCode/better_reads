import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_book.dart';
import 'book_card.dart';

class BookCarousel extends StatefulWidget {
  final List<UserBook> books;
  final String heroTagPrefix;
  final double itemWidth;
  final double itemHeight;
  final Widget? trailingWidget;

  const BookCarousel({
    super.key,
    required this.books,
    required this.heroTagPrefix,
    this.itemWidth = 120,
    this.itemHeight = 180,
    this.trailingWidget,
  });

  @override
  State<BookCarousel> createState() => _BookCarouselState();
}

class _BookCarouselState extends State<BookCarousel> {
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  // Overlap: each book overlaps the previous by this fraction of width
  static const double _overlapFraction = 0.35;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
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

    final effectiveItemWidth = widget.itemWidth * (1 - _overlapFraction);
    final screenWidth = MediaQuery.of(context).size.width;
    final sidePanelWidth = 14.0;
    final viewableWidth = screenWidth - (sidePanelWidth * 2);

    return SizedBox(
      height: widget.itemHeight + 30,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: widget.books.length * effectiveItemWidth +
              widget.itemWidth * _overlapFraction +
              (widget.trailingWidget != null ? widget.itemWidth + 20 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Books
              for (int index = 0; index < widget.books.length; index++)
                _buildBookItem(context, index, effectiveItemWidth, viewableWidth),

              // Trailing widget (add button)
              if (widget.trailingWidget != null)
                Positioned(
                  left: widget.books.length * effectiveItemWidth + widget.itemWidth * _overlapFraction + 10,
                  top: 15,
                  child: widget.trailingWidget!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookItem(BuildContext context, int index, double effectiveItemWidth, double viewableWidth) {
    final userBook = widget.books[index];
    if (userBook.book == null) return const SizedBox.shrink();

    // Calculate item's position in scroll space
    final itemLeftPosition = index * effectiveItemWidth;
    final itemCenter = itemLeftPosition + widget.itemWidth / 2;

    // Viewport center relative to scroll (accounting for padding)
    final viewportCenter = _scrollOffset + viewableWidth / 2 - 12; // 12 is the horizontal padding

    // Distance from center (normalized)
    final distanceFromCenter = (itemCenter - viewportCenter).abs();
    final maxDistance = widget.itemWidth * 1.5;
    final normalizedDistance = (distanceFromCenter / maxDistance).clamp(0.0, 1.0);

    // Scale: 1.0 at center, 0.82 at edges
    final scale = 1.0 - normalizedDistance * 0.18;

    // Vertical offset: centered items are higher (more prominent)
    final yOffset = normalizedDistance * 12;

    // Z-order: items closer to center should be on top
    // We achieve this by rendering order - center items rendered last
    // For Stack, we use the index but adjust zIndex conceptually through scale/shadow

    final heroTag = '${widget.heroTagPrefix}-${userBook.bookId}';

    return Positioned(
      left: itemLeftPosition,
      top: yOffset + 10,
      width: widget.itemWidth,
      height: widget.itemHeight,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () => context.push('/book/${userBook.bookId}', extra: heroTag),
          child: Container(
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
            ),
          ),
        ),
      ),
    );
  }
}
