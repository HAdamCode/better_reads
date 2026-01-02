import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../widgets/book_list_tile.dart';

class ShelvesScreen extends StatefulWidget {
  const ShelvesScreen({super.key});

  @override
  State<ShelvesScreen> createState() => _ShelvesScreenState();
}

class _ShelvesScreenState extends State<ShelvesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shelves'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Want to Read'),
            Tab(text: 'Reading'),
            Tab(text: 'Read'),
          ],
        ),
      ),
      body: Consumer<BooksProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookList(
                context,
                provider.wantToReadBooks,
                Shelf.wantToRead,
                'Books you want to read',
                Icons.bookmark_outline,
              ),
              _buildBookList(
                context,
                provider.currentlyReadingBooks,
                Shelf.currentlyReading,
                'Books you\'re reading now',
                Icons.menu_book,
              ),
              _buildBookList(
                context,
                provider.readBooks,
                Shelf.read,
                'Books you\'ve finished',
                Icons.check_circle_outline,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookList(
    BuildContext context,
    List<UserBook> books,
    Shelf shelf,
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
                          .addBookToShelf(userBook.book!, shelf);
                    }
                  },
                ),
              ),
            );
          },
          child: BookListTile(
            book: userBook.book!,
            onTap: () => context.push('/book/${userBook.bookId}'),
            subtitle: _buildSubtitle(userBook),
            trailing: userBook.rating != null
                ? Row(
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
                  )
                : null,
          ),
        );
      },
    );
  }

  String _buildSubtitle(UserBook userBook) {
    final parts = <String>[];

    if (userBook.book != null) {
      parts.add(userBook.book!.authorsString);
    }

    if (userBook.shelf == Shelf.currentlyReading && userBook.startedAt != null) {
      final days = DateTime.now().difference(userBook.startedAt!).inDays;
      if (days == 0) {
        parts.add('Started today');
      } else if (days == 1) {
        parts.add('Started yesterday');
      } else {
        parts.add('Reading for $days days');
      }
    }

    if (userBook.shelf == Shelf.read && userBook.finishedAt != null) {
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
