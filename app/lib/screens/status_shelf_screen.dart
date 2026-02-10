import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../utils/theme.dart';
import '../widgets/book_list_tile.dart';

enum StatusSortOption { title, rating, dateAdded, dateFinished }

class StatusShelfScreen extends StatefulWidget {
  final String status; // 'read', 'currently-reading', 'want-to-read'

  const StatusShelfScreen({super.key, required this.status});

  @override
  State<StatusShelfScreen> createState() => _StatusShelfScreenState();
}

class _StatusShelfScreenState extends State<StatusShelfScreen> {
  StatusSortOption _sortOption = StatusSortOption.dateAdded;
  bool _sortAscending = false; // Newest first by default

  ReadingStatus get _readingStatus {
    switch (widget.status) {
      case 'read':
        return ReadingStatus.read;
      case 'currently-reading':
        return ReadingStatus.currentlyReading;
      case 'want-to-read':
        return ReadingStatus.wantToRead;
      default:
        return ReadingStatus.wantToRead;
    }
  }

  String get _title {
    switch (_readingStatus) {
      case ReadingStatus.read:
        return 'Read';
      case ReadingStatus.currentlyReading:
        return 'Currently Reading';
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.none:
        return 'Books';
    }
  }

  IconData get _icon {
    switch (_readingStatus) {
      case ReadingStatus.read:
        return Icons.check_circle_outline;
      case ReadingStatus.currentlyReading:
        return Icons.menu_book;
      case ReadingStatus.wantToRead:
        return Icons.bookmark_outline;
      case ReadingStatus.none:
        return Icons.book;
    }
  }

  Color get _color {
    switch (_readingStatus) {
      case ReadingStatus.read:
        return AppTheme.readColor;
      case ReadingStatus.currentlyReading:
        return AppTheme.currentlyReadingColor;
      case ReadingStatus.wantToRead:
        return AppTheme.wantToReadColor;
      case ReadingStatus.none:
        return AppTheme.primaryColor;
    }
  }

  List<UserBook> _getBooks(BooksProvider provider) {
    switch (_readingStatus) {
      case ReadingStatus.read:
        return provider.readBooks;
      case ReadingStatus.currentlyReading:
        return provider.currentlyReadingBooks;
      case ReadingStatus.wantToRead:
        return provider.wantToReadBooks;
      case ReadingStatus.none:
        return [];
    }
  }

  List<UserBook> _sortBooks(List<UserBook> books) {
    final sorted = List<UserBook>.from(books);

    sorted.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case StatusSortOption.title:
          comparison = (a.book?.title ?? '').toLowerCase().compareTo(
            (b.book?.title ?? '').toLowerCase(),
          );
          break;
        case StatusSortOption.rating:
          final ratingA = a.rating ?? 0;
          final ratingB = b.rating ?? 0;
          comparison = ratingB.compareTo(ratingA);
          break;
        case StatusSortOption.dateAdded:
          comparison = (b.addedAt).compareTo(a.addedAt);
          break;
        case StatusSortOption.dateFinished:
          final finishedA = a.finishedAt ?? DateTime(1970);
          final finishedB = b.finishedAt ?? DateTime(1970);
          comparison = finishedB.compareTo(finishedA);
          break;
      }
      return _sortAscending ? -comparison : comparison;
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, booksProvider, _) {
        final books = _getBooks(booksProvider);
        final sortedBooks = _sortBooks(books);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, color: _color, size: 24),
                const SizedBox(width: 8),
                Text(_title),
              ],
            ),
            actions: [
              // Sort button
              PopupMenuButton<StatusSortOption>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort',
                onSelected: (option) {
                  setState(() {
                    if (_sortOption == option) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = option;
                      _sortAscending = false;
                    }
                  });
                },
                itemBuilder: (context) => [
                  _buildSortMenuItem(StatusSortOption.title, Icons.sort_by_alpha, 'Title'),
                  _buildSortMenuItem(StatusSortOption.rating, Icons.star, 'Rating'),
                  _buildSortMenuItem(StatusSortOption.dateAdded, Icons.calendar_today, 'Date Added'),
                  if (_readingStatus == ReadingStatus.read)
                    _buildSortMenuItem(StatusSortOption.dateFinished, Icons.event_available, 'Date Finished'),
                ],
              ),
            ],
          ),
          body: books.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedBooks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final userBook = sortedBooks[index];
                    if (userBook.book == null) return const SizedBox.shrink();

                    final heroTag = 'book-status-${widget.status}-${userBook.bookId}';
                    return BookListTile(
                      book: userBook.book!,
                      heroTag: heroTag,
                      onTap: () => context.push('/book/${userBook.bookId}', extra: heroTag),
                      trailing: _buildTrailing(userBook),
                    );
                  },
                ),
        );
      },
    );
  }

  PopupMenuItem<StatusSortOption> _buildSortMenuItem(
    StatusSortOption option,
    IconData icon,
    String label,
  ) {
    final isSelected = _sortOption == option;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? _color : null,
          ),
          const SizedBox(width: 12),
          Text(
            '$label${isSelected ? (_sortAscending ? ' ↑' : ' ↓') : ''}',
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailing(UserBook userBook) {
    switch (_readingStatus) {
      case ReadingStatus.read:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (userBook.rating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                  const SizedBox(width: 2),
                  Text(
                    '${userBook.rating}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            if (userBook.finishedAt != null)
              Text(
                DateFormat.yMMMd().format(userBook.finishedAt!),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
          ],
        );

      case ReadingStatus.currentlyReading:
        final pagesRead = userBook.pagesRead ?? 0;
        final totalPages = userBook.effectivePageCount;
        final progress = (totalPages != null && totalPages > 0)
            ? (pagesRead / totalPages * 100).round()
            : null;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (progress != null)
              Text(
                '$progress%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _color,
                ),
              ),
            Text(
              (totalPages != null && totalPages > 0) ? 'p.$pagesRead/$totalPages' : 'p.$pagesRead',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        );

      case ReadingStatus.wantToRead:
        return Text(
          DateFormat.yMMMd().format(userBook.addedAt),
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icon,
              size: 64,
              color: _color.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No books here yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/search'),
              style: FilledButton.styleFrom(backgroundColor: _color),
              icon: const Icon(Icons.search),
              label: const Text('Find Books'),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_readingStatus) {
      case ReadingStatus.read:
        return 'Books you\'ve finished will appear here';
      case ReadingStatus.currentlyReading:
        return 'Books you\'re reading will appear here';
      case ReadingStatus.wantToRead:
        return 'Search for books and add them to your list';
      default:
        return 'No books found';
    }
  }
}
