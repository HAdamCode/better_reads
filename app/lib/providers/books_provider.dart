import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../models/user_book.dart';
import '../services/book_service.dart';
import '../services/graphql_service.dart';
import '../services/recommendation_service.dart';

/// Holds "Because you read X" recommendation data
class BecauseYouReadRecommendation {
  final String sourceBookId;
  final String sourceBookTitle;
  final List<Book> recommendations;
  final DateTime fetchedAt;

  BecauseYouReadRecommendation({
    required this.sourceBookId,
    required this.sourceBookTitle,
    required this.recommendations,
    required this.fetchedAt,
  });
}

class BooksProvider extends ChangeNotifier {
  static const String _storageKey = 'user_books';
  static const String _bookCacheKey = 'book_cache';
  final BookService _bookService;
  final GraphQLService _graphQLService;
  final RecommendationService _recommendationService;

  List<Book> _searchResults = [];
  List<Book> _trendingBooks = [];
  List<Book> _forYouBooks = [];
  Map<String, UserBook> _userBooks = {}; // bookId -> UserBook
  Map<String, Book> _bookCache = {}; // bookId -> Book (for storing book metadata)
  bool _isSearching = false;
  bool _isLoadingTrending = false;
  bool _isLoadingForYou = false;
  bool _isLoadingUserBooks = false;
  String? _searchError;
  String? _trendingError;

  // "Because you read" recommendations
  final Map<String, BecauseYouReadRecommendation> _becauseYouReadCache = {};
  BecauseYouReadRecommendation? _featuredBecauseYouRead;
  bool _isLoadingBecauseYouRead = false;

  // Reading sessions (for tracking re-reads)
  final Map<String, List<ReadingSession>> _readingSessions = {}; // bookId -> sessions
  bool _isLoadingReadingSessions = false;

  BooksProvider({
    BookService? bookService,
    GraphQLService? graphQLService,
    RecommendationService? recommendationService,
  })  : _bookService = bookService ?? BookService(),
        _graphQLService = graphQLService ?? GraphQLService(),
        _recommendationService = recommendationService ?? RecommendationService() {
    _loadFromLocalCache();
  }

  bool get isLoadingUserBooks => _isLoadingUserBooks;

  /// Load from local cache first (for offline support), then sync with backend
  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load book cache
      final cacheData = prefs.getString(_bookCacheKey);
      if (cacheData != null) {
        final decoded = json.decode(cacheData) as Map<String, dynamic>;
        final booksList = decoded['books'] as List<dynamic>? ?? [];
        _bookCache = {
          for (var bookJson in booksList)
            (bookJson as Map<String, dynamic>)['isbn'] as String:
                Book.fromJson(bookJson)
        };
      }

      // Load user books
      final data = prefs.getString(_storageKey);
      if (data != null) {
        final decoded = json.decode(data) as Map<String, dynamic>;
        final booksList = decoded['books'] as List<dynamic>? ?? [];
        _userBooks = {
          for (var bookJson in booksList)
            (bookJson as Map<String, dynamic>)['bookId'] as String:
                UserBook.fromJson(bookJson)
        };
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load from local cache: $e');
    }
  }

  /// Sync user books from backend database
  Future<void> syncFromBackend() async {
    _isLoadingUserBooks = true;
    notifyListeners();

    try {
      final backendBooks = await _graphQLService.fetchMyBooks();

      // Merge backend data with local book cache
      for (final bookData in backendBooks) {
        final bookId = bookData['bookId'] as String;
        final cachedBook = _bookCache[bookId];
        final customShelfIdsList = (bookData['customShelfIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ?? [];

        final updatedAt = bookData['updatedAt'] != null
            ? DateTime.parse(bookData['updatedAt'] as String)
            : DateTime.now();
        final addedAt = bookData['addedAt'] != null
            ? DateTime.parse(bookData['addedAt'] as String)
            : updatedAt;

        _userBooks[bookId] = UserBook(
          userId: bookData['userId'] as String? ?? '',
          bookId: bookId,
          readingStatus: ReadingStatusExtension.fromApiValue(bookData['shelf'] as String? ?? 'WANT_TO_READ'),
          customShelfIds: customShelfIdsList,
          rating: bookData['rating'] as int?,
          startedAt: bookData['startedAt'] != null
              ? DateTime.parse(bookData['startedAt'] as String)
              : null,
          finishedAt: bookData['finishedAt'] != null
              ? DateTime.parse(bookData['finishedAt'] as String)
              : null,
          pagesRead: bookData['pagesRead'] as int?,
          addedAt: addedAt,
          updatedAt: updatedAt,
          book: cachedBook,
        );

        // If we don't have the book cached, fetch it
        if (cachedBook == null) {
          _fetchAndCacheBook(bookId);
        }
      }

      // Save to local cache
      await _saveToLocalCache();

    } catch (e) {
      debugPrint('Failed to sync from backend: $e');
      // Keep using local cache on failure
    } finally {
      _isLoadingUserBooks = false;
      notifyListeners();
    }
  }

  /// Fetch book details and add to cache
  Future<void> _fetchAndCacheBook(String bookId) async {
    try {
      final book = await _bookService.getBookByIsbn(bookId);
      if (book != null) {
        _bookCache[bookId] = book;

        // Update the user book with the fetched book data
        final userBook = _userBooks[bookId];
        if (userBook != null) {
          _userBooks[bookId] = userBook.copyWith(book: book);
        }

        await _saveBookCache();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch book $bookId: $e');
    }
  }

  /// Save user books to local cache
  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode({
        'books': _userBooks.values.map((ub) => ub.toJson()).toList(),
      });
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Failed to save user books to cache: $e');
    }
  }

  /// Save book metadata cache
  Future<void> _saveBookCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode({
        'books': _bookCache.values.map((b) => b.toJson()).toList(),
      });
      await prefs.setString(_bookCacheKey, data);
    } catch (e) {
      debugPrint('Failed to save book cache: $e');
    }
  }

  List<Book> get searchResults => _searchResults;
  List<Book> get trendingBooks => _trendingBooks;
  List<Book> get forYouBooks => _forYouBooks;
  Map<String, UserBook> get userBooks => _userBooks;
  bool get isSearching => _isSearching;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingForYou => _isLoadingForYou;
  String? get searchError => _searchError;
  String? get trendingError => _trendingError;
  BecauseYouReadRecommendation? get featuredBecauseYouRead => _featuredBecauseYouRead;
  bool get isLoadingBecauseYouRead => _isLoadingBecauseYouRead;
  bool get isLoadingReadingSessions => _isLoadingReadingSessions;

  /// Get reading sessions for a specific book
  List<ReadingSession> getReadingSessions(String bookId) {
    return _readingSessions[bookId] ?? [];
  }

  /// Get total read count for a book (number of completed sessions)
  int getReadCount(String bookId) {
    return getReadingSessions(bookId).where((s) => s.isComplete).length;
  }

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
      _isSearching = false;
      notifyListeners();

      // Fetch Open Library ratings for books without ratings (in background)
      _fetchMissingRatings();
    } on BookServiceException catch (e) {
      _searchError = e.message;
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _searchError = 'An unexpected error occurred';
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Fetch ratings from Open Library for books that don't have ratings
  Future<void> _fetchMissingRatings() async {
    final booksWithoutRatings = _searchResults
        .where((book) => book.averageRating == null)
        .toList();

    if (booksWithoutRatings.isEmpty) return;

    // Fetch ratings in parallel, but limit concurrency to avoid overwhelming the API
    const batchSize = 5;
    for (var i = 0; i < booksWithoutRatings.length; i += batchSize) {
      final batch = booksWithoutRatings.skip(i).take(batchSize);
      await Future.wait(
        batch.map((book) => _fetchAndUpdateRating(book.isbn)),
      );
    }
  }

  Future<void> _fetchAndUpdateRating(String isbn) async {
    try {
      final ratings = await _bookService.getRatingsFromOpenLibrary(isbn);
      if (ratings != null) {
        final index = _searchResults.indexWhere((b) => b.isbn == isbn);
        if (index != -1) {
          _searchResults[index] = _searchResults[index].copyWith(
            averageRating: ratings['averageRating'] as double,
            ratingsCount: ratings['ratingsCount'] as int,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      // Silently fail - ratings are optional
      debugPrint('Failed to fetch rating for $isbn: $e');
    }
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  Future<void> loadTrendingBooks({bool forceRefresh = false}) async {
    if (_trendingBooks.isNotEmpty && !forceRefresh) return;

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

  /// Load personalized book recommendations based on user's read books
  /// Clear For You cache to force refresh
  void clearForYouCache() {
    _forYouBooks = [];
    notifyListeners();
  }

  Future<void> loadForYouBooks({bool forceRefresh = false}) async {
    if (_forYouBooks.isNotEmpty && !forceRefresh) return;

    _isLoadingForYou = true;
    notifyListeners();

    try {
      // Collect subjects from user's read books
      // Weight by specificity: more specific subjects get higher scores
      final subjectScores = <String, double>{};
      for (final userBook in readBooks) {
        final book = userBook.book;
        debugPrint('ForYou: Analyzing book "${book?.title}" with subjects: ${book?.subjects}');
        if (book?.subjects != null) {
          // Track subjects already counted for this book to avoid duplicates
          final seenForBook = <String>{};
          for (final subject in book!.subjects!) {
            final (normalized, priority) = _normalizeSubjectWithPriority(subject);
            debugPrint('ForYou: Subject "$subject" -> normalized: "$normalized" (priority: $priority)');
            if (normalized.isNotEmpty && !seenForBook.contains(normalized)) {
              seenForBook.add(normalized);
              // Higher score for more specific subjects (lower priority number)
              final score = 5.0 - priority.clamp(1, 4);
              subjectScores[normalized] = (subjectScores[normalized] ?? 0) + score;
            }
          }
        }
      }

      debugPrint('ForYou: Subject scores: $subjectScores');

      List<String> topSubjects;
      if (subjectScores.isEmpty) {
        // Fallback genres if user has no read books with subjects
        debugPrint('ForYou: No subjects found, using fallback genres');
        topSubjects = ['business', 'technology', 'self_help', 'biography'];
      } else {
        // Get top 3 subjects by score (combines frequency and specificity)
        final sortedSubjects = subjectScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topSubjects = sortedSubjects.take(3).map((e) => e.key).toList();
      }

      debugPrint('ForYou: Using subjects: $topSubjects');

      // Fetch books for each subject in parallel
      final futures = topSubjects.map((subject) =>
          _bookService.getBooksBySubject(subject, limit: 8));
      final results = await Future.wait(futures);

      // Merge results and remove duplicates
      final seen = <String>{};
      final allBooks = <Book>[];

      // Also exclude books already on user's shelves
      final userBookIds = _userBooks.keys.toSet();

      for (final books in results) {
        for (final book in books) {
          if (!seen.contains(book.isbn) && !userBookIds.contains(book.isbn)) {
            seen.add(book.isbn);
            allBooks.add(book);
          }
        }
      }

      // Sort by rating (books with ratings first)
      allBooks.sort((a, b) {
        if (a.averageRating != null && b.averageRating == null) return -1;
        if (a.averageRating == null && b.averageRating != null) return 1;
        if (a.averageRating != null && b.averageRating != null) {
          return b.averageRating!.compareTo(a.averageRating!);
        }
        return 0;
      });

      _forYouBooks = allBooks.take(12).toList();
    } catch (e) {
      debugPrint('Failed to load For You books: $e');
      _forYouBooks = [];
    }

    _isLoadingForYou = false;
    notifyListeners();
  }

  /// Normalize subject names for better matching with Google Books categories
  /// Returns a tuple of (normalizedSubject, priority) where lower priority = more specific
  (String, int) _normalizeSubjectWithPriority(String subject) {
    final lower = subject.toLowerCase().trim();

    // Priority 1: Very specific topics (most valuable for recommendations)
    if (lower.contains('artificial intelligence') || lower.contains(' ai ') ||
        lower.contains('machine learning')) {
      return ('artificial+intelligence', 1);
    }
    if (lower.contains('science fiction') || lower.contains('sci-fi')) return ('science_fiction', 1);

    // Priority 2: Specific genres/topics
    if (lower.contains('mystery') || lower.contains('detective')) return ('mystery', 2);
    if (lower.contains('thriller') || lower.contains('suspense')) return ('thriller', 2);
    if (lower.contains('fantasy')) return ('fantasy', 2);
    if (lower.contains('romance')) return ('romance', 2);
    if (lower.contains('horror')) return ('horror', 2);
    if (lower.contains('psychology') || lower.contains('mental')) return ('psychology', 2);
    if (lower.contains('philosophy')) return ('philosophy', 2);

    // Priority 3: Moderately specific
    if (lower.contains('technology') || lower.contains('computers') ||
        lower.contains('programming') || lower.contains('software')) {
      return ('technology', 3);
    }
    if (lower.contains('economics') || lower.contains('finance') ||
        lower.contains('investing')) {
      return ('finance', 3);
    }
    if (lower.contains('self-help') || lower.contains('self help') ||
        lower.contains('personal development')) {
      return ('self_help', 3);
    }
    if (lower.contains('science') && !lower.contains('fiction')) return ('science', 3);
    if (lower.contains('health') || lower.contains('wellness') ||
        lower.contains('fitness')) {
      return ('health', 3);
    }
    if (lower.contains('history')) return ('history', 3);

    // Priority 4: Generic categories (less useful for specific recommendations)
    if (lower.contains('business') || lower.contains('management') ||
        lower.contains('leadership') || lower.contains('entrepreneur')) {
      return ('business', 4);
    }
    if (lower.contains('biography') || lower.contains('memoir') ||
        lower.contains('autobiography')) {
      return ('biography', 4);
    }
    if (lower.contains('fiction') && !lower.contains('non')) return ('fiction', 4);
    if (lower.contains('literary')) return ('literary_fiction', 4);

    // No match
    return ('', 99);
  }

  /// Load featured "Because you read X" recommendation for Discover screen
  Future<void> loadFeaturedBecauseYouRead({bool forceRefresh = false}) async {
    // Skip if already loaded and not forcing refresh
    if (_featuredBecauseYouRead != null && !forceRefresh) return;

    _isLoadingBecauseYouRead = true;
    notifyListeners();

    try {
      // Combine read + currently reading books, prioritizing recently finished
      final candidateBooks = <UserBook>[
        ...readBooks.where((ub) => ub.book != null).take(5),
        ...currentlyReadingBooks.where((ub) => ub.book != null).take(3),
      ];

      if (candidateBooks.isEmpty) {
        _featuredBecauseYouRead = null;
        _isLoadingBecauseYouRead = false;
        notifyListeners();
        return;
      }

      // Find the book with the best (most specific) normalizable subject
      UserBook? selectedBook;
      int bestPriority = 99;

      for (final userBook in candidateBooks) {
        if (userBook.book?.subjects?.isNotEmpty == true) {
          for (final subject in userBook.book!.subjects!) {
            final (_, priority) = _normalizeSubjectWithPriority(subject);
            if (priority < bestPriority) {
              selectedBook = userBook;
              bestPriority = priority;
            }
          }
        }
      }

      if (selectedBook == null) {
        _featuredBecauseYouRead = null;
        _isLoadingBecauseYouRead = false;
        notifyListeners();
        return;
      }

      // Check cache first (reuse if fresh - within 1 hour)
      final cached = _becauseYouReadCache[selectedBook.bookId];
      if (cached != null &&
          DateTime.now().difference(cached.fetchedAt).inHours < 1 &&
          !forceRefresh) {
        _featuredBecauseYouRead = cached;
        _isLoadingBecauseYouRead = false;
        notifyListeners();
        return;
      }

      // Use RecommendationService to get similar books
      final userBookIds = _userBooks.keys.toSet();
      final recommendationResult = await _recommendationService.getSimilarBooks(
        selectedBook.book!,
        limit: 10,
        excludeIsbns: userBookIds,
        forceRefresh: forceRefresh,
      );

      if (recommendationResult != null && recommendationResult.books.isNotEmpty) {
        final result = BecauseYouReadRecommendation(
          sourceBookId: selectedBook.bookId,
          sourceBookTitle: selectedBook.book!.title,
          recommendations: recommendationResult.books,
          fetchedAt: DateTime.now(),
        );

        _becauseYouReadCache[selectedBook.bookId] = result;
        _featuredBecauseYouRead = result;
        debugPrint('Because You Read: Got ${recommendationResult.books.length} recommendations from ${recommendationResult.source}');
      } else {
        _featuredBecauseYouRead = null;
      }
    } catch (e) {
      debugPrint('Failed to load Because You Read: $e');
      _featuredBecauseYouRead = null;
    } finally {
      _isLoadingBecauseYouRead = false;
      notifyListeners();
    }
  }

  /// Load related books for a specific book (used on Book Detail screen)
  Future<BecauseYouReadRecommendation?> loadBecauseYouReadForBook(String bookId) async {
    // Check cache first
    final cached = _becauseYouReadCache[bookId];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt).inHours < 1) {
      return cached;
    }

    // Get the book details
    final userBook = _userBooks[bookId];
    final book = userBook?.book ?? _bookCache[bookId];

    if (book == null) {
      return null;
    }

    try {
      // Use RecommendationService to get similar books
      final userBookIds = _userBooks.keys.toSet();
      final recommendationResult = await _recommendationService.getSimilarBooks(
        book,
        limit: 10,
        excludeIsbns: userBookIds,
      );

      if (recommendationResult == null || recommendationResult.books.isEmpty) {
        return null;
      }

      final result = BecauseYouReadRecommendation(
        sourceBookId: bookId,
        sourceBookTitle: book.title,
        recommendations: recommendationResult.books,
        fetchedAt: DateTime.now(),
      );

      _becauseYouReadCache[bookId] = result;
      debugPrint('Related books for $bookId: Got ${recommendationResult.books.length} from ${recommendationResult.source}');
      return result;
    } catch (e) {
      debugPrint('Failed to load related books for $bookId: $e');
      return null;
    }
  }

  Future<Book?> getBookByIsbn(String isbn) async {
    try {
      var book = await _bookService.getBookByIsbn(isbn);

      // If book has no rating, try to get it from Open Library
      if (book != null && book.averageRating == null) {
        final ratings = await _bookService.getRatingsFromOpenLibrary(isbn);
        if (ratings != null) {
          book = book.copyWith(
            averageRating: ratings['averageRating'] as double,
            ratingsCount: ratings['ratingsCount'] as int,
          );
        }
      }

      return book;
    } catch (e) {
      debugPrint('Error getting book by ISBN: $e');
      return null;
    }
  }

  Future<void> addBookToShelf(Book book, ReadingStatus readingStatus) async {
    final now = DateTime.now();

    // Cache the book metadata
    _bookCache[book.isbn] = book;
    _saveBookCache();

    final userBook = UserBook(
      userId: '',
      bookId: book.isbn,
      readingStatus: readingStatus,
      addedAt: now,
      updatedAt: now,
      book: book,
      startedAt: readingStatus == ReadingStatus.currentlyReading ? now : null,
      finishedAt: readingStatus == ReadingStatus.read ? now : null,
    );

    // Update local state immediately for responsiveness
    _userBooks[book.isbn] = userBook;
    notifyListeners();

    // Clear For You cache when adding to read shelf
    if (readingStatus == ReadingStatus.read) {
      _forYouBooks = [];
    }

    // Sync with backend
    try {
      await _graphQLService.addBookToShelf(
        bookId: book.isbn,
        shelf: readingStatus.apiValue,
        startedAt: readingStatus == ReadingStatus.currentlyReading ? now : null,
        finishedAt: readingStatus == ReadingStatus.read ? now : null,
      );

      // Create reading session if adding directly as READ
      if (readingStatus == ReadingStatus.read) {
        final session = await startReadingSession(book.isbn, startedAt: now);
        if (session != null) {
          await finishReadingSession(book.isbn, session.sessionId, finishedAt: now);
        }
      }

      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync addBookToShelf: $e');
      // Keep local state even if backend fails
      await _saveToLocalCache();
    }
  }

  /// Import or update a book with full data from CSV import
  /// Returns: 'added', 'updated', or 'failed'
  /// This is optimized for bulk imports - call notifyBatchComplete() after batch
  Future<String> importOrUpdateBook({
    required Book book,
    required ReadingStatus status,
    List<String> customShelfIds = const [],
    int? rating,
    DateTime? dateRead,
    DateTime? dateAdded,
    bool notify = true,
  }) async {
    final now = DateTime.now();
    final existing = _userBooks[book.isbn];
    final isUpdate = existing != null;

    // Cache the book metadata
    _bookCache[book.isbn] = book;

    // Determine dates - preserve existing if not provided in import
    DateTime? startedAt;
    DateTime? finishedAt;
    DateTime addedAtFinal;

    if (isUpdate) {
      // For updates, only override dates if CSV has them
      startedAt = status == ReadingStatus.currentlyReading
          ? (dateAdded ?? existing.startedAt ?? now)
          : existing.startedAt;
      finishedAt = status == ReadingStatus.read
          ? (dateRead ?? existing.finishedAt ?? now)
          : existing.finishedAt;
      addedAtFinal = existing.addedAt; // Preserve original added date
    } else {
      // For new books
      startedAt = status == ReadingStatus.currentlyReading ? (dateAdded ?? now) : null;
      finishedAt = status == ReadingStatus.read ? (dateRead ?? now) : null;
      addedAtFinal = dateAdded ?? now;
    }

    final userBook = UserBook(
      userId: existing?.userId ?? '',
      bookId: book.isbn,
      readingStatus: status,
      customShelfIds: customShelfIds,
      rating: rating ?? existing?.rating, // Preserve existing rating if not in CSV
      startedAt: startedAt,
      finishedAt: finishedAt,
      pagesRead: existing?.pagesRead, // Preserve reading progress
      addedAt: addedAtFinal,
      updatedAt: now,
      book: book,
    );

    // Update local state
    _userBooks[book.isbn] = userBook;

    if (notify) {
      notifyListeners();
    }

    // Clear For You cache when adding to read shelf
    if (status == ReadingStatus.read) {
      _forYouBooks = [];
    }

    // Sync with backend
    try {
      if (isUpdate) {
        await _graphQLService.updateBookShelf(
          bookId: book.isbn,
          shelf: status.apiValue,
          customShelfIds: customShelfIds.isEmpty ? null : customShelfIds,
          rating: userBook.rating,
          startedAt: userBook.startedAt,
          finishedAt: userBook.finishedAt,
          pagesRead: userBook.pagesRead,
        );
        return 'updated';
      } else {
        await _graphQLService.addBookToShelf(
          bookId: book.isbn,
          shelf: status.apiValue,
          customShelfIds: customShelfIds.isEmpty ? null : customShelfIds,
          rating: userBook.rating,
          startedAt: userBook.startedAt,
          finishedAt: userBook.finishedAt,
        );
        return 'added';
      }
    } catch (e) {
      debugPrint('Failed to sync importOrUpdateBook: $e');
      return 'failed';
    }
  }

  /// Call after importing a batch of books to update UI and save cache
  Future<void> notifyBatchComplete() async {
    notifyListeners();
    await _saveToLocalCache();
    await _saveBookCache();
  }

  /// Check if a book is already in the user's library
  bool isBookInLibrary(String bookId) => _userBooks.containsKey(bookId);

  Future<void> updateBookShelf(String bookId, ReadingStatus newStatus) async {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final now = DateTime.now();

    // Handle reading session when finishing a book
    if (newStatus == ReadingStatus.read && existing.readingStatus != ReadingStatus.read) {
      await _ensureReadingSessionOnFinish(bookId, existing.startedAt, now);
    }

    final updated = existing.copyWith(
      readingStatus: newStatus,
      updatedAt: now,
      startedAt:
          newStatus == ReadingStatus.currentlyReading ? now : existing.startedAt,
      finishedAt: newStatus == ReadingStatus.read ? now : existing.finishedAt,
      pagesRead: newStatus == ReadingStatus.currentlyReading ? 0 : existing.pagesRead,
    );

    // Update local state immediately
    _userBooks[bookId] = updated;
    notifyListeners();

    // Clear For You cache when reading status changes to refresh recommendations
    if (newStatus == ReadingStatus.read) {
      _forYouBooks = [];
    }

    // Sync with backend
    try {
      await _graphQLService.updateBookShelf(
        bookId: bookId,
        shelf: newStatus.apiValue,
        customShelfIds: updated.customShelfIds,
        rating: updated.rating,
        notes: updated.notes,
        totalPages: updated.totalPages,
        startedAt: updated.startedAt,
        finishedAt: updated.finishedAt,
        pagesRead: updated.pagesRead,
      );
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync updateBookShelf: $e');
      await _saveToLocalCache();
    }
  }

  /// Update notes for a book
  Future<void> updateNotes(String bookId, String? notes) async {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final now = DateTime.now();
    final updated = existing.copyWith(
      notes: notes,
      updatedAt: now,
    );

    // Update local state immediately
    _userBooks[bookId] = updated;
    notifyListeners();

    // Sync with backend
    try {
      await _graphQLService.updateBookShelf(
        bookId: bookId,
        shelf: updated.readingStatus.apiValue,
        customShelfIds: updated.customShelfIds,
        rating: updated.rating,
        notes: notes,
        totalPages: updated.totalPages,
        startedAt: updated.startedAt,
        finishedAt: updated.finishedAt,
        pagesRead: updated.pagesRead,
      );
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync notes: $e');
      await _saveToLocalCache();
    }
  }

  /// Update total pages for a book (user-provided override)
  Future<void> updateTotalPages(String bookId, int? totalPages) async {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final now = DateTime.now();
    final updated = existing.copyWith(
      totalPages: totalPages,
      updatedAt: now,
    );

    // Update local state immediately
    _userBooks[bookId] = updated;
    notifyListeners();

    // Sync with backend
    try {
      await _graphQLService.updateBookShelf(
        bookId: bookId,
        shelf: updated.readingStatus.apiValue,
        customShelfIds: updated.customShelfIds,
        rating: updated.rating,
        notes: updated.notes,
        totalPages: totalPages,
        startedAt: updated.startedAt,
        finishedAt: updated.finishedAt,
        pagesRead: updated.pagesRead,
      );
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync totalPages: $e');
      await _saveToLocalCache();
    }
  }

  /// Ensures a reading session exists and is finished when completing a book
  Future<void> _ensureReadingSessionOnFinish(String bookId, DateTime? startedAt, DateTime finishedAt) async {
    // Load sessions if not already loaded
    if (!_readingSessions.containsKey(bookId)) {
      try {
        final sessionsData = await _graphQLService.fetchReadingSessions(bookId);
        final sessions = sessionsData
            .map((s) => ReadingSession.fromJson(s))
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        _readingSessions[bookId] = sessions;
      } catch (e) {
        debugPrint('Failed to load reading sessions: $e');
        _readingSessions[bookId] = [];
      }
    }

    final sessions = _readingSessions[bookId] ?? [];
    final openSession = sessions.where((s) => !s.isComplete).firstOrNull;

    if (openSession != null) {
      // Finish the open session (re-read case)
      await finishReadingSession(bookId, openSession.sessionId, finishedAt: finishedAt);
    } else if (sessions.isEmpty) {
      // First read - create a completed session
      final session = await startReadingSession(bookId, startedAt: startedAt ?? finishedAt);
      if (session != null) {
        await finishReadingSession(bookId, session.sessionId, finishedAt: finishedAt);
      }
    }
    // If sessions exist but none are open, user already has complete sessions - don't create duplicate
  }

  /// Add a book to a custom shelf
  Future<void> addToCustomShelf(String bookId, String shelfId) async {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    if (existing.customShelfIds.contains(shelfId)) return;

    final updatedShelfIds = [...existing.customShelfIds, shelfId];
    _userBooks[bookId] = existing.copyWith(
      customShelfIds: updatedShelfIds,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Sync with backend
    try {
      await _graphQLService.updateBookShelf(
        bookId: bookId,
        shelf: existing.readingStatus.apiValue,
        customShelfIds: updatedShelfIds,
        rating: existing.rating,
        startedAt: existing.startedAt,
        finishedAt: existing.finishedAt,
        pagesRead: existing.pagesRead,
      );
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync addToCustomShelf: $e');
      await _saveToLocalCache();
    }
  }

  /// Remove a book from a custom shelf
  Future<void> removeFromCustomShelf(String bookId, String shelfId) async {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final updatedShelfIds = existing.customShelfIds.where((id) => id != shelfId).toList();
    _userBooks[bookId] = existing.copyWith(
      customShelfIds: updatedShelfIds,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Sync with backend
    try {
      await _graphQLService.updateBookShelf(
        bookId: bookId,
        shelf: existing.readingStatus.apiValue,
        customShelfIds: updatedShelfIds,
        rating: existing.rating,
        startedAt: existing.startedAt,
        finishedAt: existing.finishedAt,
        pagesRead: existing.pagesRead,
      );
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync removeFromCustomShelf: $e');
      await _saveToLocalCache();
    }
  }

  /// Update both reading status and custom shelves at once
  Future<void> updateBookShelves(String bookId, ReadingStatus status, List<String> customShelfIds) async {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final now = DateTime.now();
    final updated = existing.copyWith(
      readingStatus: status,
      customShelfIds: customShelfIds,
      updatedAt: now,
      startedAt: status == ReadingStatus.currentlyReading ? now : existing.startedAt,
      finishedAt: status == ReadingStatus.read ? now : existing.finishedAt,
    );

    // Update local state immediately
    _userBooks[bookId] = updated;
    notifyListeners();

    // Sync with backend
    try {
      await _graphQLService.updateBookShelf(
        bookId: bookId,
        shelf: status.apiValue,
        customShelfIds: customShelfIds,
        rating: updated.rating,
        startedAt: updated.startedAt,
        finishedAt: updated.finishedAt,
        pagesRead: updated.pagesRead,
      );
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync updateBookShelves: $e');
      await _saveToLocalCache();
    }
  }

  Future<void> updateBookRating(String bookId, int rating) async {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final updated = existing.copyWith(
      rating: rating,
      updatedAt: DateTime.now(),
    );

    // Update local state immediately
    _userBooks[bookId] = updated;
    notifyListeners();

    // Sync with backend
    try {
      await _graphQLService.updateBookShelf(
        bookId: bookId,
        shelf: updated.readingStatus.apiValue,
        customShelfIds: updated.customShelfIds,
        rating: rating,
        startedAt: updated.startedAt,
        finishedAt: updated.finishedAt,
        pagesRead: updated.pagesRead,
      );
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync updateBookRating: $e');
      await _saveToLocalCache();
    }
  }

  /// Update reading progress (current page) for a book
  Future<void> updateReadingProgress(String bookId, int pagesRead) async {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final updated = existing.copyWith(
      pagesRead: pagesRead,
      updatedAt: DateTime.now(),
    );

    // Update local state immediately
    _userBooks[bookId] = updated;
    notifyListeners();

    // Sync with backend
    try {
      await _graphQLService.updateBookShelf(
        bookId: bookId,
        shelf: updated.readingStatus.apiValue,
        customShelfIds: updated.customShelfIds,
        rating: updated.rating,
        startedAt: updated.startedAt,
        finishedAt: updated.finishedAt,
        pagesRead: pagesRead,
      );
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync updateReadingProgress: $e');
      await _saveToLocalCache();
    }
  }

  /// Update reading dates (startedAt and finishedAt) for a book
  Future<void> updateReadingDates(
    String bookId, {
    DateTime? startedAt,
    DateTime? finishedAt,
  }) async {
    final existing = _userBooks[bookId];
    if (existing == null) return;

    final updated = existing.copyWith(
      startedAt: startedAt,
      finishedAt: finishedAt,
      updatedAt: DateTime.now(),
    );

    // Update local state immediately
    _userBooks[bookId] = updated;
    notifyListeners();

    // Sync with backend
    try {
      await _graphQLService.updateBookShelf(
        bookId: bookId,
        shelf: updated.readingStatus.apiValue,
        customShelfIds: updated.customShelfIds,
        rating: updated.rating,
        startedAt: startedAt,
        finishedAt: finishedAt,
        pagesRead: updated.pagesRead,
      );
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync updateReadingDates: $e');
      await _saveToLocalCache();
    }
  }

  Future<void> removeBookFromShelf(String bookId) async {
    // Update local state immediately
    _userBooks.remove(bookId);
    notifyListeners();

    // Sync with backend
    try {
      await _graphQLService.removeBookFromShelf(bookId);
      await _saveToLocalCache();
    } catch (e) {
      debugPrint('Failed to sync removeBookFromShelf: $e');
      await _saveToLocalCache();
    }
  }

  // ========================================
  // READING SESSIONS
  // ========================================

  /// Load reading sessions for a specific book
  Future<void> loadReadingSessions(String bookId) async {
    _isLoadingReadingSessions = true;
    notifyListeners();

    try {
      final sessionsData = await _graphQLService.fetchReadingSessions(bookId);
      final sessions = sessionsData
          .map((s) => ReadingSession.fromJson(s))
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

      _readingSessions[bookId] = sessions;
    } catch (e) {
      debugPrint('Failed to load reading sessions: $e');
    } finally {
      _isLoadingReadingSessions = false;
      notifyListeners();
    }
  }

  /// Load all reading sessions for the user
  Future<void> loadAllReadingSessions() async {
    _isLoadingReadingSessions = true;
    notifyListeners();

    try {
      final sessionsData = await _graphQLService.fetchAllReadingSessions();
      final allSessions = sessionsData.map((s) => ReadingSession.fromJson(s)).toList();

      // Group by bookId
      _readingSessions.clear();
      for (final session in allSessions) {
        _readingSessions.putIfAbsent(session.bookId, () => []).add(session);
      }

      // Sort each book's sessions by start date (newest first)
      for (final bookId in _readingSessions.keys) {
        _readingSessions[bookId]!.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      }
    } catch (e) {
      debugPrint('Failed to load all reading sessions: $e');
    } finally {
      _isLoadingReadingSessions = false;
      notifyListeners();
    }
  }

  /// Start a new reading session (for re-reads)
  Future<ReadingSession?> startReadingSession(String bookId, {DateTime? startedAt}) async {
    try {
      final result = await _graphQLService.createReadingSession(
        bookId: bookId,
        startedAt: startedAt ?? DateTime.now(),
      );

      if (result != null) {
        final session = ReadingSession.fromJson(result);
        _readingSessions.putIfAbsent(bookId, () => []).insert(0, session);
        notifyListeners();
        return session;
      }
    } catch (e) {
      debugPrint('Failed to start reading session: $e');
      rethrow;
    }
    return null;
  }

  /// Finish a reading session
  Future<void> finishReadingSession(
    String bookId,
    String sessionId, {
    DateTime? finishedAt,
  }) async {
    try {
      await _graphQLService.updateReadingSession(
        sessionId: sessionId,
        bookId: bookId,
        finishedAt: finishedAt ?? DateTime.now(),
      );

      // Update local state
      final sessions = _readingSessions[bookId];
      if (sessions != null) {
        final index = sessions.indexWhere((s) => s.sessionId == sessionId);
        if (index != -1) {
          sessions[index] = sessions[index].copyWith(
            finishedAt: finishedAt ?? DateTime.now(),
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to finish reading session: $e');
      rethrow;
    }
  }

  /// Update a reading session's dates
  Future<void> updateReadingSession(
    String bookId,
    String sessionId, {
    DateTime? startedAt,
    DateTime? finishedAt,
  }) async {
    try {
      await _graphQLService.updateReadingSession(
        sessionId: sessionId,
        bookId: bookId,
        startedAt: startedAt,
        finishedAt: finishedAt,
      );

      // Update local reading session state
      final sessions = _readingSessions[bookId];
      if (sessions != null) {
        final index = sessions.indexWhere((s) => s.sessionId == sessionId);
        if (index != -1) {
          sessions[index] = sessions[index].copyWith(
            startedAt: startedAt ?? sessions[index].startedAt,
            finishedAt: finishedAt ?? sessions[index].finishedAt,
          );
        }
      }

      // Also update the UserBook's dates to match the most recent session
      // This ensures stats filtering by year works correctly
      final userBook = _userBooks[bookId];
      if (userBook != null) {
        // Find the most recent finished session to set as UserBook's finishedAt
        DateTime? latestFinished;
        DateTime? earliestStarted;

        final allSessions = _readingSessions[bookId] ?? [];
        for (final session in allSessions) {
          if (session.finishedAt != null) {
            if (latestFinished == null || session.finishedAt!.isAfter(latestFinished)) {
              latestFinished = session.finishedAt;
            }
          }
          if (earliestStarted == null || session.startedAt.isBefore(earliestStarted)) {
            earliestStarted = session.startedAt;
          }
        }

        // Update UserBook with the dates from sessions
        final updated = userBook.copyWith(
          startedAt: earliestStarted ?? userBook.startedAt,
          finishedAt: latestFinished ?? userBook.finishedAt,
          updatedAt: DateTime.now(),
        );
        _userBooks[bookId] = updated;

        // Also sync the updated dates to the backend
        await _graphQLService.updateBookShelf(
          bookId: bookId,
          shelf: updated.readingStatus.apiValue,
          customShelfIds: updated.customShelfIds,
          rating: updated.rating,
          startedAt: updated.startedAt,
          finishedAt: updated.finishedAt,
          pagesRead: updated.pagesRead,
        );
        await _saveToLocalCache();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update reading session: $e');
      rethrow;
    }
  }

  /// Delete a reading session
  Future<void> deleteReadingSession(String bookId, String sessionId) async {
    try {
      await _graphQLService.deleteReadingSession(
        sessionId: sessionId,
        bookId: bookId,
      );

      // Update local state
      _readingSessions[bookId]?.removeWhere((s) => s.sessionId == sessionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete reading session: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _bookService.dispose();
    _recommendationService.dispose();
    super.dispose();
  }
}
