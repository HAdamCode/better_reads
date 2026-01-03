import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/shelves_provider.dart';
import '../providers/lending_provider.dart';
import '../utils/theme.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/create_shelf_dialog.dart';

class ShelvesScreen extends StatefulWidget {
  const ShelvesScreen({super.key});

  @override
  State<ShelvesScreen> createState() => _ShelvesScreenState();
}

class _ShelvesScreenState extends State<ShelvesScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _statusTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _statusTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _statusTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        bottom: TabBar(
          controller: _mainTabController,
          tabs: const [
            Tab(text: 'Reading Status'),
            Tab(text: 'Custom Shelves'),
            Tab(text: 'Lent Out'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildReadingStatusTab(),
          _buildCustomShelvesTab(),
          _buildLentOutTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _mainTabController,
        builder: (context, child) {
          // Only show FAB on Custom Shelves tab
          final showFab = _mainTabController.index == 1;
          return AnimatedScale(
            scale: showFab ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton(
              onPressed: () => CreateShelfDialog.show(context),
              tooltip: 'Create Shelf',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadingStatusTab() {
    return Column(
      children: [
        Material(
          color: AppTheme.surfaceColor,
          child: TabBar(
            controller: _statusTabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Want to Read'),
              Tab(text: 'Reading'),
              Tab(text: 'Read'),
            ],
          ),
        ),
        Expanded(
          child: Consumer2<BooksProvider, LendingProvider>(
            builder: (context, booksProvider, lendingProvider, _) {
              return TabBarView(
                controller: _statusTabController,
                children: [
                  _buildBookList(
                    context,
                    booksProvider.wantToReadBooks,
                    ReadingStatus.wantToRead,
                    'Books you want to read',
                    Icons.bookmark_outline,
                    lendingProvider,
                  ),
                  _buildBookList(
                    context,
                    booksProvider.currentlyReadingBooks,
                    ReadingStatus.currentlyReading,
                    'Books you\'re reading now',
                    Icons.menu_book,
                    lendingProvider,
                  ),
                  _buildBookList(
                    context,
                    booksProvider.readBooks,
                    ReadingStatus.read,
                    'Books you\'ve finished',
                    Icons.check_circle_outline,
                    lendingProvider,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomShelvesTab() {
    return Consumer<ShelvesProvider>(
      builder: (context, shelvesProvider, _) {
        final shelves = shelvesProvider.sortedShelves;

        if (shelves.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No custom shelves yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create shelves to organize your books\nhowever you like',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => CreateShelfDialog.show(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Shelf'),
                  ),
                ],
              ),
            ),
          );
        }

        return Consumer<BooksProvider>(
          builder: (context, booksProvider, _) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: shelves.length + 1, // +1 for the "Create" button
              itemBuilder: (context, index) {
                if (index == shelves.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: () => CreateShelfDialog.show(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Shelf'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                }

                final shelf = shelves[index];
                final bookCount = booksProvider.getBooksOnCustomShelf(shelf.id).length;

                return Dismissible(
                  key: Key(shelf.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Shelf'),
                        content: Text(
                          'Are you sure you want to delete "${shelf.name}"? Books on this shelf will not be deleted.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) {
                    shelvesProvider.deleteShelf(shelf.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${shelf.name} deleted')),
                    );
                  },
                  child: ListTile(
                    leading: Icon(
                      Icons.folder_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(shelf.name),
                    subtitle: Text(
                      '$bookCount ${bookCount == 1 ? 'book' : 'books'}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/shelf/${shelf.id}'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLentOutTab() {
    return Consumer2<LendingProvider, BooksProvider>(
      builder: (context, lendingProvider, booksProvider, _) {
        final activeLoans = lendingProvider.activeLoans;

        if (activeLoans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.share,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No books lent out',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you lend a book to someone,\nit will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: activeLoans.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final loan = activeLoans[index];
            final userBook = booksProvider.getUserBook(loan.bookId);

            if (userBook?.book == null) {
              return const SizedBox.shrink();
            }

            final book = userBook!.book!;
            final heroTag = 'book-lent-${book.isbn}';

            return ListTile(
              leading: _buildLentBookCover(book),
              title: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.authorsString,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          loan.borrowerName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          loan.borrowerName,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatLentDuration(loan.lentAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Mark as returned',
                onPressed: () => _markAsReturned(context, loan.id, book.title),
              ),
              onTap: () => context.push('/book/${book.isbn}', extra: heroTag),
            );
          },
        );
      },
    );
  }

  Widget _buildLentBookCover(book) {
    if (book.coverUrl == null) {
      return Container(
        width: 40,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.book,
          color: Colors.grey.shade500,
          size: 20,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        book.coverUrl!,
        width: 40,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 40,
          height: 60,
          color: Colors.grey.shade300,
          child: Icon(Icons.book, color: Colors.grey.shade500, size: 20),
        ),
      ),
    );
  }

  String _formatLentDuration(DateTime lentAt) {
    final days = DateTime.now().difference(lentAt).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    if (days < 30) {
      final weeks = (days / 7).floor();
      return '$weeks wk${weeks > 1 ? 's' : ''}';
    }
    final months = (days / 30).floor();
    return '$months mo${months > 1 ? 's' : ''}';
  }

  Future<void> _markAsReturned(BuildContext context, String loanId, String bookTitle) async {
    final lendingProvider = context.read<LendingProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await lendingProvider.returnBook(loanId);
      messenger.showSnackBar(
        SnackBar(content: Text('$bookTitle marked as returned')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to mark as returned: $e')),
      );
    }
  }

  Widget _buildBookList(
    BuildContext context,
    List<UserBook> books,
    ReadingStatus status,
    String emptyMessage,
    IconData emptyIcon,
    LendingProvider lendingProvider,
  ) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No books yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/search'),
                icon: const Icon(Icons.search),
                label: const Text('Find Books'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final userBook = books[index];
        return Dismissible(
          key: Key(userBook.bookId),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove Book'),
                content: Text(
                  'Remove "${userBook.book?.title ?? 'this book'}" from your shelf?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            context.read<BooksProvider>().removeBookFromShelf(userBook.bookId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${userBook.book?.title ?? 'Book'} removed'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    if (userBook.book != null) {
                      context
                          .read<BooksProvider>()
                          .addBookToShelf(userBook.book!, status);
                    }
                  },
                ),
              ),
            );
          },
          child: Builder(
            builder: (context) {
              final heroTag = 'book-shelves-${userBook.bookId}';
              return BookListTile(
                book: userBook.book!,
                heroTag: heroTag,
                onTap: () => context.push('/book/${userBook.bookId}', extra: heroTag),
                subtitle: _buildSubtitle(userBook),
                trailing: _buildTrailing(userBook, lendingProvider),
              );
            },
          ),
        );
      },
    );
  }

  Widget? _buildTrailing(UserBook userBook, LendingProvider lendingProvider) {
    final widgets = <Widget>[];
    final isLent = lendingProvider.isBookLentOut(userBook.bookId);

    // Lent indicator
    if (isLent) {
      final loan = lendingProvider.getActiveLoanForBook(userBook.bookId);
      widgets.add(
        Tooltip(
          message: 'Lent to ${loan?.borrowerName ?? 'someone'}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 2),
                Text(
                  'Lent',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Rating
    if (userBook.rating != null) {
      widgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: Colors.amber.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              userBook.rating.toString(),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Custom shelf indicator
    if (userBook.customShelfIds.isNotEmpty) {
      widgets.add(
        Tooltip(
          message: 'On ${userBook.customShelfIds.length} custom ${userBook.customShelfIds.length == 1 ? 'shelf' : 'shelves'}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_outlined, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 2),
                Text(
                  '${userBook.customShelfIds.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widgets.isEmpty) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widgets.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          widgets[i],
        ],
      ],
    );
  }

  String _buildSubtitle(UserBook userBook) {
    final parts = <String>[];

    if (userBook.book != null) {
      parts.add(userBook.book!.authorsString);
    }

    if (userBook.readingStatus == ReadingStatus.currentlyReading && userBook.startedAt != null) {
      final days = DateTime.now().difference(userBook.startedAt!).inDays;
      if (days == 0) {
        parts.add('Started today');
      } else if (days == 1) {
        parts.add('Started yesterday');
      } else {
        parts.add('Reading for $days days');
      }
    }

    if (userBook.readingStatus == ReadingStatus.read && userBook.finishedAt != null) {
      final month = _monthName(userBook.finishedAt!.month);
      parts.add('Finished $month ${userBook.finishedAt!.year}');
    }

    return parts.join(' · ');
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
