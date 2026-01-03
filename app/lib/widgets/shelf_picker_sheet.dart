import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/shelves_provider.dart';
import '../utils/theme.dart';
import 'create_shelf_dialog.dart';

class ShelfPickerSheet extends StatefulWidget {
  final String bookId;

  const ShelfPickerSheet({super.key, required this.bookId});

  static Future<void> show(BuildContext context, String bookId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShelfPickerSheet(bookId: bookId),
    );
  }

  @override
  State<ShelfPickerSheet> createState() => _ShelfPickerSheetState();
}

class _ShelfPickerSheetState extends State<ShelfPickerSheet> {
  late ReadingStatus _selectedStatus;
  late Set<String> _selectedShelfIds;

  @override
  void initState() {
    super.initState();
    final booksProvider = context.read<BooksProvider>();
    final userBook = booksProvider.getUserBook(widget.bookId);
    _selectedStatus = userBook?.readingStatus ?? ReadingStatus.none;
    _selectedShelfIds = Set.from(userBook?.customShelfIds ?? []);
  }

  void _saveChanges() {
    final booksProvider = context.read<BooksProvider>();
    final userBook = booksProvider.getUserBook(widget.bookId);

    if (userBook != null) {
      booksProvider.updateBookShelves(
        widget.bookId,
        _selectedStatus,
        _selectedShelfIds.toList(),
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _createNewShelf() async {
    final newShelfId = await CreateShelfDialog.show(context);
    if (newShelfId != null && mounted) {
      setState(() {
        _selectedShelfIds.add(newShelfId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Add to Shelves',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saveChanges,
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Reading Status Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'READING STATUS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Consumer<BooksProvider>(
                    builder: (context, booksProvider, _) {
                      return Column(
                        children: [
                          _buildStatusOption(
                            ReadingStatus.wantToRead,
                            Icons.bookmark_outline,
                            Colors.blue,
                            booksProvider.wantToReadBooks.length,
                          ),
                          _buildStatusOption(
                            ReadingStatus.currentlyReading,
                            Icons.menu_book,
                            Colors.orange,
                            booksProvider.currentlyReadingBooks.length,
                          ),
                          _buildStatusOption(
                            ReadingStatus.read,
                            Icons.check_circle_outline,
                            Colors.green,
                            booksProvider.readBooks.length,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  // Custom Shelves Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          'CUSTOM SHELVES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _createNewShelf,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer2<ShelvesProvider, BooksProvider>(
                    builder: (context, shelvesProvider, booksProvider, _) {
                      final shelves = shelvesProvider.sortedShelves;
                      if (shelves.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No custom shelves yet',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _createNewShelf,
                                  child: const Text('Create your first shelf'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: shelves.map((shelf) {
                          final isSelected = _selectedShelfIds.contains(shelf.id);
                          final bookCount = booksProvider.getBooksOnCustomShelf(shelf.id).length;
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedShelfIds.add(shelf.id);
                                } else {
                                  _selectedShelfIds.remove(shelf.id);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                Text(shelf.name),
                                const SizedBox(width: 8),
                                Text(
                                  '($bookCount)',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            secondary: Icon(
                              Icons.folder_outlined,
                              color: isSelected ? AppTheme.primaryColor : Colors.grey,
                            ),
                            activeColor: AppTheme.primaryColor,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusOption(ReadingStatus status, IconData icon, Color color, int count) {
    final isSelected = _selectedStatus == status;
    return RadioListTile<ReadingStatus>(
      value: status,
      groupValue: _selectedStatus,
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedStatus = value);
        }
      },
      title: Row(
        children: [
          Text(status.displayName),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
      secondary: Icon(icon, color: isSelected ? color : Colors.grey),
      activeColor: color,
    );
  }
}
