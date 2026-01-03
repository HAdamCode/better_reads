import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../services/book_service.dart';

class BooksProvider extends ChangeNotifier {
  final BookService _bookService;

  List<Book> _searchResults = [];
  List<Book> _trendingBooks = [];
  Map<String, UserBook> _userBooks = {}; // bookId -> UserBook
  bool _isSearching = false;
  bool _isLoadingTrending = false;
  String? _searchError;
  String? _trendingError;

  BooksProvider({BookService? bookService})
      : _bookService = bookService ?? BookService();

  List<Book> get searchResults => _searchResults;
  List<Book> get trendingBooks => _trendingBooks;
  Map<String, UserBook> get userBooks => _userBooks;
  bool get isSearching => _isSearching;
  bool get isLoadingTrending => _isLoadingTrending;
  String? get searchError => _searchError;
  String? get trendingError => _trendingError;

  List<UserBook> get wantToReadBooks => _userBooks.values
      .where((ub) => ub.readingStatus == ReadingStatus.wantToRead)
      .toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  List<UserBook> get currentlyReadingBooks => _userBooks.values
      .where((ub) => ub.readingStatus == ReadingStatus.currentlyReading)
      .toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  List<UserBook> get readBooks =>
      _userBooks.values.where((ub) => ub.readingStatus == ReadingStatus.read).toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  int get totalBooksRead => readBooks.length;

  UserBook? getUserBook(String bookId) => _userBooks[bookId];

  bool isBookOnShelf(String bookId) => _userBooks.containsKey(bookId);

  ReadingStatus? getBookShelf(String bookId) => _userBooks[bookId]?.readingStatus;

  /// Get all books on a specific custom shelf
  List<UserBook> getBooksOnCustomShelf(String shelfId) => _userBooks.values
      .where((ub) => ub.customShelfIds.contains(shelfId))
      .toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  Future<void> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      _searchResults = await _bookService.searchBooks(query);
    } on BookServiceException catch (e) {
      _searchError = e.message;
      _searchResults = [];
    } catch (e) {
      _searchError = 'An unexpected error occurred';
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  Future<void> loadTrendingBooks() async {
    if (_trendingBooks.isNotEmpty) return;

    _isLoadingTrending = true;
    _trendingError = null;
    notifyListeners();

    try {
      _trendingBooks = await _bookService.getTrendingBooks(limit: 10);
    } on BookServiceException catch (e) {
      _trendingError = e.message;
    } catch (e) {
      _trendingError = 'Failed to load trending books';
    }

    _isLoadingTrending = false;
    notifyListeners();
  }

  Future<Book?> getBookByIsbn(String isbn) async {
    try {
      return await _bookService.getBookByIsbn(isbn);
    } catch (e) {
      debugPrint('Error getting book by ISBN: $e');
      return null;
    }
  }

  void addBookToShelf(Book book, ReadingStatus readingStatus) {
    final now = DateTime.now();
    final userBook = UserBook(
      userId: '', // Will be set from auth
      bookId: book.isbn,
      readingStatus: readingStatus,
      addedAt: now,
      updatedAt: now,
      book: book,
      startedAt: readingStatus == ReadingStatus.currentlyReading ? now : null,
      finishedAt: readingStatus == ReadingStatus.read ? now : null,
    );

    _userBooks[book.isbn] = userBook;
    notifyListeners();

    // TODO: Sync with backend via GraphQL
  }

  void updateBookShelf(String bookId, ReadingStatus newStatus) {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final now = DateTime.now();
    _userBooks[bookId] = existing.copyWith(
      readingStatus: newStatus,
      updatedAt: now,
      startedAt:
          newStatus == ReadingStatus.currentlyReading ? now : existing.startedAt,
      finishedAt: newStatus == ReadingStatus.read ? now : existing.finishedAt,
    );
    notifyListeners();

    // TODO: Sync with backend via GraphQL
  }

  /// Add a book to a custom shelf
  void addToCustomShelf(String bookId, String shelfId) {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    if (existing.customShelfIds.contains(shelfId)) return;

    final updatedShelfIds = [...existing.customShelfIds, shelfId];
    _userBooks[bookId] = existing.copyWith(
      customShelfIds: updatedShelfIds,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // TODO: Sync with backend via GraphQL
  }

  /// Remove a book from a custom shelf
  void removeFromCustomShelf(String bookId, String shelfId) {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final updatedShelfIds = existing.customShelfIds.where((id) => id != shelfId).toList();
    _userBooks[bookId] = existing.copyWith(
      customShelfIds: updatedShelfIds,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // TODO: Sync with backend via GraphQL
  }

  /// Update both reading status and custom shelves at once
  void updateBookShelves(String bookId, ReadingStatus status, List<String> customShelfIds) {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final now = DateTime.now();
    _userBooks[bookId] = existing.copyWith(
      readingStatus: status,
      customShelfIds: customShelfIds,
      updatedAt: now,
      startedAt: status == ReadingStatus.currentlyReading ? now : existing.startedAt,
      finishedAt: status == ReadingStatus.read ? now : existing.finishedAt,
    );
    notifyListeners();

    // TODO: Sync with backend via GraphQL
  }

  void updateBookRating(String bookId, int rating) {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    _userBooks[bookId] = existing.copyWith(
      rating: rating,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // TODO: Sync with backend via GraphQL
  }

  void removeBookFromShelf(String bookId) {
    _userBooks.remove(bookId);
    notifyListeners();

    // TODO: Sync with backend via GraphQL
  }

  @override
  void dispose() {
    _bookService.dispose();
    super.dispose();
  }
}
