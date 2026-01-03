import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class BookCategory {
  final String id;
  final String name;
  final String subject;

  const BookCategory({
    required this.id,
    required this.name,
    required this.subject,
  });
}

class BrowseProvider extends ChangeNotifier {
  static const List<BookCategory> categories = [
    BookCategory(id: 'fiction', name: 'Fiction', subject: 'fiction'),
    BookCategory(id: 'mystery', name: 'Mystery', subject: 'mystery'),
    BookCategory(id: 'scifi', name: 'Sci-Fi', subject: 'science fiction'),
    BookCategory(id: 'fantasy', name: 'Fantasy', subject: 'fantasy'),
    BookCategory(id: 'romance', name: 'Romance', subject: 'romance'),
    BookCategory(id: 'thriller', name: 'Thriller', subject: 'thriller'),
    BookCategory(id: 'biography', name: 'Biography', subject: 'biography'),
    BookCategory(id: 'history', name: 'History', subject: 'history'),
    BookCategory(id: 'selfhelp', name: 'Self-Help', subject: 'self help'),
    BookCategory(id: 'ya', name: 'Young Adult', subject: 'young adult fiction'),
  ];

  final BookService _bookService;

  String? _selectedCategoryId;
  final Map<String, List<Book>> _categoryBooks = {};
  final Map<String, int> _categoryOffsets = {};
  final Map<String, bool> _categoryHasMore = {};
  bool _isLoading = false;
  String? _error;

  BrowseProvider({BookService? bookService})
      : _bookService = bookService ?? BookService();

  String? get selectedCategoryId => _selectedCategoryId;
  BookCategory? get selectedCategory => _selectedCategoryId != null
      ? categories.firstWhere((c) => c.id == _selectedCategoryId)
      : null;
  List<Book> get currentBooks => _selectedCategoryId != null
      ? _categoryBooks[_selectedCategoryId] ?? []
      : [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _selectedCategoryId != null
      ? _categoryHasMore[_selectedCategoryId] ?? true
      : false;

  Future<void> selectCategory(String categoryId) async {
    if (_selectedCategoryId == categoryId) return;

    _selectedCategoryId = categoryId;
    _error = null;
    notifyListeners();

    // Load if not already loaded
    if (!_categoryBooks.containsKey(categoryId)) {
      await _loadCategory(categoryId);
    }
  }

  Future<void> _loadCategory(String categoryId) async {
    final category = categories.firstWhere((c) => c.id == categoryId);

    _isLoading = true;
    notifyListeners();

    try {
      final books = await _bookService.getBooksBySubject(
        category.subject,
        limit: 20,
        offset: 0,
      );

      _categoryBooks[categoryId] = books;
      _categoryOffsets[categoryId] = books.length;
      _categoryHasMore[categoryId] = books.length >= 20;
      _error = null;
    } catch (e) {
      _error = 'Failed to load books';
      debugPrint('Failed to load category $categoryId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_selectedCategoryId == null || _isLoading || !hasMore) return;

    final categoryId = _selectedCategoryId!;
    final category = categories.firstWhere((c) => c.id == categoryId);
    final offset = _categoryOffsets[categoryId] ?? 0;

    _isLoading = true;
    notifyListeners();

    try {
      final moreBooks = await _bookService.getBooksBySubject(
        category.subject,
        limit: 20,
        offset: offset,
      );

      if (moreBooks.isNotEmpty) {
        _categoryBooks[categoryId] = [...(_categoryBooks[categoryId] ?? []), ...moreBooks];
        _categoryOffsets[categoryId] = offset + moreBooks.length;
        _categoryHasMore[categoryId] = moreBooks.length >= 20;
      } else {
        _categoryHasMore[categoryId] = false;
      }
    } catch (e) {
      debugPrint('Failed to load more books: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_selectedCategoryId == null) return;

    _categoryBooks.remove(_selectedCategoryId);
    _categoryOffsets.remove(_selectedCategoryId);
    _categoryHasMore.remove(_selectedCategoryId);

    await _loadCategory(_selectedCategoryId!);
  }

  void clearSelection() {
    _selectedCategoryId = null;
    notifyListeners();
  }
}
