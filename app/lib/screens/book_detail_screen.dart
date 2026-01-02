import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';

class BookDetailScreen extends StatefulWidget {
  final String isbn;

  const BookDetailScreen({super.key, required this.isbn});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    // First check if we have the book in search results or user books
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

    // Check trending
    final fromTrending = provider.trendingBooks.where((b) => b.isbn == widget.isbn).firstOrNull;
    if (fromTrending != null) {
      setState(() {
        _book = fromTrending;
        _isLoading = false;
      });
      return;
    }

    // Fetch from API
    try {
      final book = await provider.getBookByIsbn(widget.isbn);
      setState(() {
        _book = book;
        _isLoading = false;
        if (book == null) {
          _error = 'Book not found';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load book details';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
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
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBookInfo(context),
                  const SizedBox(height: 24),
                  _buildShelfActions(context),
                  const SizedBox(height: 24),
                  if (_book!.description != null) ...[
                    _buildDescription(context),
                    const SizedBox(height: 24),
                  ],
                  if (_book!.subjects?.isNotEmpty == true) ...[
                    _buildSubjects(context),
                    const SizedBox(height: 24),
                  ],
                  _buildDetails(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Hero(
                tag: 'book-${_book!.isbn}',
                child: _buildCover(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    if (_book!.coverUrl == null) {
      return Container(
        width: 140,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.book,
          size: 64,
          color: Colors.grey.shade500,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: _book!.coverUrl!,
        width: 140,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Colors.grey.shade300,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey.shade300,
          child: Icon(Icons.book, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildBookInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _book!.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _book!.authorsString,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
          textAlign: TextAlign.center,
        ),
        if (_book!.averageRating != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (index) {
                final rating = _book!.averageRating!;
                if (index < rating.floor()) {
                  return Icon(Icons.star, color: Colors.amber.shade600, size: 20);
                } else if (index < rating) {
                  return Icon(Icons.star_half, color: Colors.amber.shade600, size: 20);
                }
                return Icon(Icons.star_outline, color: Colors.grey.shade400, size: 20);
              }),
              const SizedBox(width: 8),
              Text(
                _book!.averageRating!.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_book!.ratingsCount != null) ...[
                const SizedBox(width: 4),
                Text(
                  '(${_formatCount(_book!.ratingsCount!)})',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildShelfActions(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, provider, _) {
        final currentShelf = provider.getBookShelf(_book!.isbn);
        final userBook = provider.getUserBook(_book!.isbn);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (currentShelf == null) ...[
                  FilledButton.icon(
                    onPressed: () => _showShelfPicker(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Shelf'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showShelfPicker(context),
                          icon: Icon(_getShelfIcon(currentShelf)),
                          label: Text(currentShelf.displayName),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          provider.removeBookFromShelf(_book!.isbn);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Removed from shelf')),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Rating',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final rating = userBook?.rating ?? 0;
                      return IconButton(
                        onPressed: () {
                          provider.updateBookRating(_book!.isbn, index + 1);
                        },
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_outline,
                          color: index < rating
                              ? Colors.amber.shade600
                              : Colors.grey.shade400,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShelfPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.bookmark_outline, color: Colors.blue),
                  title: const Text('Want to Read'),
                  onTap: () {
                    context.read<BooksProvider>().addBookToShelf(_book!, Shelf.wantToRead);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book, color: Colors.orange),
                  title: const Text('Currently Reading'),
                  onTap: () {
                    context.read<BooksProvider>().addBookToShelf(_book!, Shelf.currentlyReading);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Read'),
                  onTap: () {
                    context.read<BooksProvider>().addBookToShelf(_book!, Shelf.read);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getShelfIcon(Shelf shelf) {
    switch (shelf) {
      case Shelf.wantToRead:
        return Icons.bookmark_outline;
      case Shelf.currentlyReading:
        return Icons.menu_book;
      case Shelf.read:
        return Icons.check_circle;
    }
  }

  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _book!.description!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
        ),
      ],
    );
  }

  Widget _buildSubjects(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genres',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _book!.subjects!.map((subject) {
            return Chip(
              label: Text(subject),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_book!.pageCount != null)
              _buildDetailRow('Pages', _book!.pageCount.toString()),
            if (_book!.publishedDate != null)
              _buildDetailRow('First Published', _book!.publishedDate!),
            _buildDetailRow('ISBN', _book!.isbn),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
