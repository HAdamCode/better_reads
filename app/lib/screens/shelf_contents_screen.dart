import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/shelves_provider.dart';
import '../widgets/book_list_tile.dart';

class ShelfContentsScreen extends StatelessWidget {
  final String shelfId;

  const ShelfContentsScreen({super.key, required this.shelfId});

  Future<void> _confirmDelete(BuildContext context, String shelfName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shelf'),
        content: Text(
          'Are you sure you want to delete "$shelfName"? Books on this shelf will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ShelvesProvider>().deleteShelf(shelfId);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  Future<void> _renameShelf(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Shelf'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Shelf Name',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty && context.mounted) {
      try {
        await context.read<ShelvesProvider>().renameShelf(shelfId, newName);
      } on ArgumentError catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ShelvesProvider, BooksProvider>(
      builder: (context, shelvesProvider, booksProvider, _) {
        final shelf = shelvesProvider.getShelf(shelfId);
        if (shelf == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Shelf Not Found')),
            body: const Center(
              child: Text('This shelf no longer exists'),
            ),
          );
        }

        final books = booksProvider.getBooksOnCustomShelf(shelfId);

        return Scaffold(
          appBar: AppBar(
            title: Text(shelf.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'rename':
                      _renameShelf(context, shelf.name);
                      break;
                    case 'delete':
                      _confirmDelete(context, shelf.name);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.add),
            label: const Text('Find Books'),
          ),
          body: books.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No books on this shelf',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search for books and add them to "${shelf.name}"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.push('/search'),
                          icon: const Icon(Icons.search),
                          label: const Text('Find Books'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final userBook = books[index];
                    if (userBook.book == null) return const SizedBox.shrink();
                    return Dismissible(
                      key: Key(userBook.bookId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red,
                        child: const Icon(Icons.remove_circle, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove from shelf?'),
                            content: Text(
                              'Remove "${userBook.book!.title}" from "${shelf.name}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) {
                        booksProvider.removeFromCustomShelf(userBook.bookId, shelfId);
                      },
                      child: Builder(
                        builder: (context) {
                          final heroTag = 'book-shelf-$shelfId-${userBook.bookId}';
                          return BookListTile(
                            book: userBook.book!,
                            heroTag: heroTag,
                            onTap: () => context.push('/book/${userBook.bookId}', extra: heroTag),
                            trailing: _buildStatusIcon(userBook.readingStatus),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget? _buildStatusIcon(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return const Icon(Icons.bookmark_outline, color: Colors.blue, size: 20);
      case ReadingStatus.currentlyReading:
        return const Icon(Icons.menu_book, color: Colors.orange, size: 20);
      case ReadingStatus.read:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case ReadingStatus.none:
        return null;
    }
  }
}
