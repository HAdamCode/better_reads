import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/shelves_provider.dart';
import '../widgets/book_list_tile.dart';

enum ShelfSortOption { title, rating, dateAdded }
enum ShelfFilterOption { all, rated, unrated }

class ShelfContentsScreen extends StatefulWidget {
  final String shelfId;

  const ShelfContentsScreen({super.key, required this.shelfId});

  @override
  State<ShelfContentsScreen> createState() => _ShelfContentsScreenState();
}

class _ShelfContentsScreenState extends State<ShelfContentsScreen> {
  ShelfSortOption _sortOption = ShelfSortOption.title;
  ShelfFilterOption _filterOption = ShelfFilterOption.all;
  bool _sortAscending = true;

  String get shelfId => widget.shelfId;

  List<UserBook> _sortAndFilterBooks(List<UserBook> books, Map<String, int> bookRatings) {
    // Filter first
    var filtered = books.where((userBook) {
      if (_filterOption == ShelfFilterOption.all) return true;
      final hasRating = bookRatings.containsKey(userBook.bookId);
      return _filterOption == ShelfFilterOption.rated ? hasRating : !hasRating;
    }).toList();

    // Then sort
    filtered.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case ShelfSortOption.title:
          comparison = (a.book?.title ?? '').toLowerCase().compareTo(
            (b.book?.title ?? '').toLowerCase(),
          );
          break;
        case ShelfSortOption.rating:
          final ratingA = bookRatings[a.bookId] ?? 0;
          final ratingB = bookRatings[b.bookId] ?? 0;
          comparison = ratingB.compareTo(ratingA); // Higher ratings first by default
          break;
        case ShelfSortOption.dateAdded:
          comparison = (b.addedAt ?? DateTime(1970)).compareTo(
            a.addedAt ?? DateTime(1970),
          ); // Newest first by default
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

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

        final sortedBooks = _sortAndFilterBooks(books, shelf.bookRatings);

        return Scaffold(
          appBar: AppBar(
            title: Text(shelf.name),
            actions: [
              // Sort button
              PopupMenuButton<ShelfSortOption>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort',
                onSelected: (option) {
                  setState(() {
                    if (_sortOption == option) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = option;
                      _sortAscending = true;
                    }
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: ShelfSortOption.title,
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_by_alpha,
                          size: 20,
                          color: _sortOption == ShelfSortOption.title ? Theme.of(context).primaryColor : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Title${_sortOption == ShelfSortOption.title ? (_sortAscending ? ' ↑' : ' ↓') : ''}',
                          style: TextStyle(
                            fontWeight: _sortOption == ShelfSortOption.title ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShelfSortOption.rating,
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 20,
                          color: _sortOption == ShelfSortOption.rating ? Theme.of(context).primaryColor : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rating${_sortOption == ShelfSortOption.rating ? (_sortAscending ? ' ↑' : ' ↓') : ''}',
                          style: TextStyle(
                            fontWeight: _sortOption == ShelfSortOption.rating ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShelfSortOption.dateAdded,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: _sortOption == ShelfSortOption.dateAdded ? Theme.of(context).primaryColor : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Date Added${_sortOption == ShelfSortOption.dateAdded ? (_sortAscending ? ' ↑' : ' ↓') : ''}',
                          style: TextStyle(
                            fontWeight: _sortOption == ShelfSortOption.dateAdded ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Filter button
              PopupMenuButton<ShelfFilterOption>(
                icon: Icon(
                  _filterOption == ShelfFilterOption.all ? Icons.filter_list : Icons.filter_list_off,
                  color: _filterOption == ShelfFilterOption.all ? null : Theme.of(context).primaryColor,
                ),
                tooltip: 'Filter',
                onSelected: (option) {
                  setState(() {
                    _filterOption = option;
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: ShelfFilterOption.all,
                    child: Row(
                      children: [
                        Icon(
                          Icons.list,
                          size: 20,
                          color: _filterOption == ShelfFilterOption.all ? Theme.of(context).primaryColor : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'All Books',
                          style: TextStyle(
                            fontWeight: _filterOption == ShelfFilterOption.all ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShelfFilterOption.rated,
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 20,
                          color: _filterOption == ShelfFilterOption.rated ? Theme.of(context).primaryColor : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rated Only',
                          style: TextStyle(
                            fontWeight: _filterOption == ShelfFilterOption.rated ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ShelfFilterOption.unrated,
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 20,
                          color: _filterOption == ShelfFilterOption.unrated ? Theme.of(context).primaryColor : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Unrated Only',
                          style: TextStyle(
                            fontWeight: _filterOption == ShelfFilterOption.unrated ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Menu button (rename/delete)
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
              : sortedBooks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No books match filter',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _filterOption == ShelfFilterOption.rated
                              ? 'No books have been rated on this shelf yet'
                              : 'All books on this shelf have been rated',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => setState(() => _filterOption = ShelfFilterOption.all),
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Filter'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedBooks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final userBook = sortedBooks[index];
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
                          final shelfRating = shelf.getBookRating(userBook.bookId);
                          return BookListTile(
                            book: userBook.book!,
                            heroTag: heroTag,
                            onTap: () => context.push('/book/${userBook.bookId}', extra: heroTag),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildShelfRating(context, shelvesProvider, userBook.bookId, shelfRating),
                                const SizedBox(width: 8),
                                if (_buildStatusIcon(userBook.readingStatus) != null)
                                  _buildStatusIcon(userBook.readingStatus)!,
                              ],
                            ),
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

  Widget _buildShelfRating(
    BuildContext context,
    ShelvesProvider shelvesProvider,
    String bookId,
    int? currentRating,
  ) {
    return GestureDetector(
      onTap: () => _showRatingPicker(context, shelvesProvider, bookId, currentRating),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            currentRating != null ? Icons.star : Icons.star_outline,
            size: 18,
            color: currentRating != null ? Colors.amber : Colors.grey.shade400,
          ),
          const SizedBox(width: 2),
          Text(
            currentRating?.toString() ?? '-',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: currentRating != null ? Colors.amber.shade700 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingPicker(
    BuildContext context,
    ShelvesProvider shelvesProvider,
    String bookId,
    int? currentRating,
  ) async {
    int? selectedRating = currentRating;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate for this shelf'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                icon: Icon(
                  starValue <= (selectedRating ?? 0)
                      ? Icons.star
                      : Icons.star_outline,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    // Tap same star to clear rating
                    if (selectedRating == starValue) {
                      selectedRating = null;
                    } else {
                      selectedRating = starValue;
                    }
                  });
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await shelvesProvider.updateBookRatingOnShelf(
                    shelfId,
                    bookId,
                    selectedRating,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update rating: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
