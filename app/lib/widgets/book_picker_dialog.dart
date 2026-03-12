import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';

class BookPickerDialog extends StatefulWidget {
  const BookPickerDialog({super.key});

  @override
  State<BookPickerDialog> createState() => _BookPickerDialogState();
}

class _BookPickerDialogState extends State<BookPickerDialog> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Link a Book',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: Icon(_showSearch ? Icons.close : Icons.search),
                    onPressed: () => setState(() => _showSearch = !_showSearch),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_showSearch) ...[
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search your books...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
              ],

              // No book option
              ListTile(
                leading: const Icon(Icons.not_interested),
                title: const Text('No book'),
                dense: true,
                onTap: () => Navigator.pop(context, null),
              ),
              const Divider(),

              // User's books from shelves
              Expanded(
                child: Consumer<BooksProvider>(
                  builder: (context, provider, _) {
                    var books = provider.userBooks.values.toList();

                    // Filter by search
                    final query = _searchController.text.toLowerCase();
                    if (query.isNotEmpty) {
                      books = books.where((b) {
                        final title =
                            b.book?.title.toLowerCase() ?? b.bookId.toLowerCase();
                        return title.contains(query);
                      }).toList();
                    }

                    if (books.isEmpty) {
                      return const Center(
                        child: Text('No books found'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final userBook = books[index];
                        final title = userBook.book?.title ?? userBook.bookId;

                        return ListTile(
                          leading: userBook.book?.coverUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    userBook.book!.coverUrl!,
                                    width: 32,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.book),
                                  ),
                                )
                              : const Icon(Icons.book),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: userBook.book?.authors.isNotEmpty == true
                              ? Text(
                                  userBook.book!.authors.join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          dense: true,
                          onTap: () {
                            Navigator.pop(context, {
                              'bookId': userBook.bookId,
                              'title': title,
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
