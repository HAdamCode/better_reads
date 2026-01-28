import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/shelves_provider.dart';
import '../providers/lending_provider.dart';
import '../services/book_service.dart';
import '../utils/theme.dart';
import '../widgets/shelf_picker_sheet.dart';
import '../widgets/lend_book_dialog.dart';
import '../widgets/update_progress_dialog.dart';

class BookDetailScreen extends StatefulWidget {
  final String isbn;
  final String? heroTag;

  const BookDetailScreen({super.key, required this.isbn, this.heroTag});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;
  bool _isLoading = true;
  String? _error;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final provider = context.read<BooksProvider>();

    // Check search results
    final fromSearch = provider.searchResults.where((b) => b.isbn == widget.isbn).firstOrNull;
    if (fromSearch != null) {
      setState(() {
        _book = fromSearch;
        _isLoading = false;
      });
      return;
    }

    // Check user books
    final userBook = provider.getUserBook(widget.isbn);
    if (userBook?.book != null) {
      setState(() {
        _book = userBook!.book;
        _isLoading = false;
      });
      return;
    }

    // Check trending - use as placeholder while fetching full details
    final fromTrending = provider.trendingBooks.where((b) => b.isbn == widget.isbn).firstOrNull;
    if (fromTrending != null) {
      setState(() => _book = fromTrending);
      _fetchFullDetailsForTrending(fromTrending);
      return;
    }

    // Fetch from API
    try {
      final book = await provider.getBookByIsbn(widget.isbn);
      setState(() {
        _book = book;
        _isLoading = false;
        if (book == null) _error = 'Book not found';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load book details';
      });
    }
  }

  Future<void> _fetchFullDetailsForTrending(Book trendingBook) async {
    final bookService = BookService();
    try {
      final query = '${trendingBook.title} ${trendingBook.authors.first}';
      final results = await bookService.searchBooks(query, limit: 5);

      if (results.isNotEmpty) {
        final match = results.firstWhere(
          (b) => b.title.toLowerCase() == trendingBook.title.toLowerCase(),
          orElse: () => results.first,
        );
        if (mounted) setState(() { _book = match; _isLoading = false; });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch full details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _book == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_error ?? 'Book not found'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeroSection(context),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(context),
                      const SizedBox(height: 20),
                      _buildQuickStats(context),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 24),
                      _buildUserSection(context),
                      if (_book!.description != null) ...[
                        const SizedBox(height: 24),
                        _buildDescription(context),
                      ],
                      if (_book!.subjects?.isNotEmpty == true) ...[
                        const SizedBox(height: 24),
                        _buildGenres(context),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
                AppTheme.secondaryColor.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.network(
                    _book!.coverUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
              // Book cover
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60, bottom: 50),
                  child: widget.heroTag != null
                      ? Hero(tag: widget.heroTag!, child: _buildCover())
                      : _buildCover(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _book!.coverUrl != null
            ? CachedNetworkImage(
                imageUrl: _book!.coverUrl!,
                width: 160,
                height: 240,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildCoverPlaceholder(),
                errorWidget: (_, __, ___) => _buildCoverPlaceholder(),
              )
            : _buildCoverPlaceholder(),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      width: 160,
      height: 240,
      color: Colors.grey.shade300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _book!.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      children: [
        Text(
          _book!.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'by ${_book!.authorsString}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
        if (_book!.averageRating != null) ...[
          const SizedBox(height: 16),
          _buildRatingDisplay(),
        ],
      ],
    );
  }

  Widget _buildRatingDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (index) {
            final rating = _book!.averageRating!;
            IconData icon;
            if (index < rating.floor()) {
              icon = Icons.star_rounded;
            } else if (index < rating) {
              icon = Icons.star_half_rounded;
            } else {
              icon = Icons.star_outline_rounded;
            }
            return Icon(icon, color: Colors.amber.shade700, size: 22);
          }),
          const SizedBox(width: 10),
          Text(
            _book!.averageRating!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
            ),
          ),
          if (_book!.ratingsCount != null) ...[
            const SizedBox(width: 6),
            Text(
              '(${_formatCount(_book!.ratingsCount!)})',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_book!.pageCount != null)
            _buildStatItem(Icons.auto_stories_outlined, '${_book!.pageCount}', 'Pages'),
          if (_book!.publishedDate != null)
            _buildStatItem(Icons.calendar_today_outlined, _book!.publishedDate!, 'Published'),
          if (_book!.averageRating != null)
            _buildStatItem(Icons.star_outline_rounded, _book!.averageRating!.toStringAsFixed(1), 'Rating'),
          _buildStatItem(Icons.qr_code, _book!.isbn.length > 10 ? 'ISBN-13' : 'ISBN-10', 'Format'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, provider, _) {
        final userBook = provider.getUserBook(_book!.isbn);
        final isOnShelf = userBook != null;
        final status = userBook?.readingStatus;

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  if (!isOnShelf) {
                    provider.addBookToShelf(_book!, ReadingStatus.wantToRead);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to Want to Read')),
                    );
                  } else {
                    ShelfPickerSheet.show(context, _book!.isbn);
                  }
                },
                icon: Icon(isOnShelf ? _getShelfIcon(status!) : Icons.add_rounded),
                label: Text(isOnShelf ? status!.displayName : 'Want to Read'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => ShelfPickerSheet.show(context, _book!.isbn),
                icon: Icon(Icons.bookmark_add_outlined, color: AppTheme.primaryColor),
                padding: const EdgeInsets.all(14),
              ),
            ),
            if (isOnShelf) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    provider.removeBookFromShelf(_book!.isbn);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from shelves')),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUserSection(BuildContext context) {
    return Consumer3<BooksProvider, ShelvesProvider, LendingProvider>(
      builder: (context, booksProvider, shelvesProvider, lendingProvider, _) {
        final userBook = booksProvider.getUserBook(_book!.isbn);
        if (userBook == null) return const SizedBox.shrink();

        final activeLoan = lendingProvider.getActiveLoanForBook(_book!.isbn);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your Rating
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Your Rating',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final rating = userBook.rating ?? 0;
                      return GestureDetector(
                        onTap: () => booksProvider.updateBookRating(_book!.isbn, index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: index < rating ? Colors.amber.shade600 : Colors.grey.shade400,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (userBook.rating != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'You rated this ${userBook.rating} star${userBook.rating! > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Reading Progress (only for currently reading books)
            if (userBook.readingStatus == ReadingStatus.currentlyReading) ...[
              const SizedBox(height: 12),
              _buildReadingProgressCard(context, userBook, booksProvider),
            ],

            // Custom Shelves
            if (userBook.customShelfIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_outlined, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'On Your Shelves',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: userBook.customShelfIds.map((shelfId) {
                        final shelf = shelvesProvider.getShelf(shelfId);
                        if (shelf == null) return const SizedBox.shrink();
                        return Chip(
                          label: Text(shelf.name),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => booksProvider.removeFromCustomShelf(_book!.isbn, shelfId),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Lending
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        activeLoan != null ? Icons.person : Icons.share_outlined,
                        color: activeLoan != null ? AppTheme.secondaryColor : AppTheme.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lending',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      if (activeLoan != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Lent Out',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (activeLoan != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.secondaryColor,
                          child: Text(
                            activeLoan.borrowerName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeLoan.borrowerName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _formatLentDate(activeLoan.lentAt),
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => _markReturned(context, activeLoan.id),
                          child: const Text('Returned'),
                        ),
                      ],
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => _showLendDialog(context),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Lend to someone'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDescription(BuildContext context) {
    final description = _book!.description!;
    final isLong = description.length > 300;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'About this book',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
            secondChild: Text(
              description,
              style: TextStyle(
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
            crossFadeState: _descriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Text(
                _descriptionExpanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenres(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Genres',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _book!.subjects!.take(8).map((subject) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.tertiaryColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                subject,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.tertiaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReadingProgressCard(BuildContext context, UserBook userBook, BooksProvider provider) {
    final pagesRead = userBook.pagesRead ?? 0;
    final totalPages = _book?.pageCount;
    final progress = (totalPages != null && totalPages > 0)
        ? (pagesRead / totalPages).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).round();

    return GestureDetector(
      onTap: () => UpdateProgressDialog.show(
        context,
        bookId: _book!.isbn,
        bookTitle: _book!.title,
        currentPage: pagesRead,
        totalPages: totalPages,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bookmark, color: AppTheme.currentlyReadingColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reading Progress',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.currentlyReadingColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppTheme.currentlyReadingColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(AppTheme.currentlyReadingColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  totalPages != null
                      ? 'Page $pagesRead of $totalPages'
                      : 'Page $pagesRead',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                Row(
                  children: [
                    Icon(Icons.edit, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to update',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getShelfIcon(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return Icons.bookmark_outline;
      case ReadingStatus.currentlyReading:
        return Icons.menu_book;
      case ReadingStatus.read:
        return Icons.check_circle_outline;
      case ReadingStatus.none:
        return Icons.add_rounded;
    }
  }

  Future<void> _showLendDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await LendBookDialog.show(context, _book!.isbn, bookTitle: _book!.title);
    if (result == true && mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Book marked as lent')));
    }
  }

  Future<void> _markReturned(BuildContext context, String loanId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<LendingProvider>().returnBook(loanId);
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Book marked as returned')));
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatLentDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Lent today';
    if (days == 1) return 'Lent yesterday';
    if (days < 7) return 'Lent $days days ago';
    if (days < 30) return 'Lent ${(days / 7).floor()} week${days >= 14 ? 's' : ''} ago';
    return 'Lent ${(days / 30).floor()} month${days >= 60 ? 's' : ''} ago';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
