import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/shelves_provider.dart';
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
    _mainTabController = TabController(length: 2, vsync: this);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Shelf',
            onPressed: () => CreateShelfDialog.show(context),
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          tabs: const [
            Tab(text: 'Reading Status'),
            Tab(text: 'Custom Shelves'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildReadingStatusTab(),
          _buildCustomShelvesTab(),
        ],
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
          child: Consumer<BooksProvider>(
            builder: (context, provider, _) {
              return TabBarView(
                controller: _statusTabController,
                children: [
                  _buildBookList(
                    context,
                    provider.wantToReadBooks,
                    ReadingStatus.wantToRead,
                    'Books you want to read',
                    Icons.bookmark_outline,
                  ),
                  _buildBookList(
                    context,
                    provider.currentlyReadingBooks,
                    ReadingStatus.currentlyReading,
                    'Books you\'re reading now',
                    Icons.menu_book,
                  ),
                  _buildBookList(
                    context,
                    provider.readBooks,
                    ReadingStatus.read,
                    'Books you\'ve finished',
                    Icons.check_circle_outline,
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

  Widget _buildBookList(
    BuildContext context,
    List<UserBook> books,
    ReadingStatus status,
    String emptyMessage,
    IconData emptyIcon,
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
                trailing: _buildTrailing(userBook),
              );
            },
          ),
        );
      },
    );
  }

  Widget? _buildTrailing(UserBook userBook) {
    final widgets = <Widget>[];

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
