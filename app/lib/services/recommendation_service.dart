import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'book_service.dart';

/// Result from a recommendation provider
class RecommendationResult {
  final List<Book> books;
  final String source;
  final String? sourceBookTitle;

  RecommendationResult({
    required this.books,
    required this.source,
    this.sourceBookTitle,
  });
}

/// Abstract interface for recommendation providers
/// This allows us to swap between TasteDive, our own collaborative filtering, etc.
abstract class RecommendationProvider {
  /// Get similar books for a given book
  /// Returns null if this provider can't handle the request
  Future<RecommendationResult?> getSimilarBooks(
    Book book, {
    int limit = 10,
    Set<String>? excludeIsbns,
  });

  /// Provider name for logging/debugging
  String get name;

  /// Priority (lower = tried first)
  int get priority;
}

/// TasteDive API provider - uses collaborative filtering from their community
class TasteDiveProvider implements RecommendationProvider {
  static const String _baseUrl = 'https://tastedive.com/api/similar';

  final http.Client _client;
  final BookService _bookService;
  final String? _apiKey;

  TasteDiveProvider({
    http.Client? client,
    BookService? bookService,
  })  : _client = client ?? http.Client(),
        _bookService = bookService ?? BookService(),
        _apiKey = dotenv.env['TASTEDIVE_API_KEY'];

  @override
  String get name => 'TasteDive';

  @override
  int get priority => 1;

  @override
  Future<RecommendationResult?> getSimilarBooks(
    Book book, {
    int limit = 10,
    Set<String>? excludeIsbns,
  }) async {
    try {
      // Build query - use "book:Title" format for clarity
      final query = 'book:${book.title}';

      final queryParams = {
        'q': query,
        'type': 'book',
        'limit': (limit + 5).toString(), // Request extra to account for filtering
        'info': '1', // Include descriptions
      };

      if (_apiKey != null && _apiKey.isNotEmpty) {
        queryParams['k'] = _apiKey;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        debugPrint('TasteDive API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final similar = data['similar'] as Map<String, dynamic>?;

      if (similar == null) {
        debugPrint('TasteDive: No similar data in response');
        return null;
      }

      final results = similar['results'] as List<dynamic>? ?? [];

      if (results.isEmpty) {
        debugPrint('TasteDive: No results for "${book.title}"');
        return null;
      }

      // Convert TasteDive results to our Book model by searching Google Books
      final books = <Book>[];
      final exclude = excludeIsbns ?? {};

      for (final result in results) {
        if (books.length >= limit) break;

        final resultData = result as Map<String, dynamic>;
        final title = resultData['name'] as String?;
        final description = resultData['description'] as String?;

        if (title == null || title.isEmpty) continue;

        // Skip if it's the same book
        if (title.toLowerCase() == book.title.toLowerCase()) continue;

        // Skip book sets, collections, bundles from TasteDive results
        final lowerTitle = title.toLowerCase();
        if (lowerTitle.contains('collection') ||
            lowerTitle.contains('box set') ||
            lowerTitle.contains('boxset') ||
            lowerTitle.contains('books in 1') ||
            lowerTitle.contains('book bundle') ||
            lowerTitle.contains('esampler') ||
            lowerTitle.contains('coloring book') ||
            lowerTitle.contains('#1-')) {
          continue;
        }

        // Search Google Books for this title to get full book data
        try {
          final searchResults = await _bookService.searchBooks(title, limit: 3);

          for (final searchBook in searchResults) {
            // Skip excluded books
            if (exclude.contains(searchBook.isbn)) continue;

            // Find a reasonable match (title should be similar)
            if (_titlesMatch(title, searchBook.title)) {
              // Use TasteDive description if Google Books doesn't have one
              final enrichedBook = searchBook.description == null && description != null
                  ? searchBook.copyWith(description: description)
                  : searchBook;

              books.add(enrichedBook);
              exclude.add(searchBook.isbn); // Don't add duplicates
              break;
            }
          }
        } catch (e) {
          debugPrint('Failed to search for "$title": $e');
        }
      }

      if (books.isEmpty) {
        return null;
      }

      return RecommendationResult(
        books: books,
        source: 'TasteDive',
        sourceBookTitle: book.title,
      );
    } catch (e) {
      debugPrint('TasteDive provider error: $e');
      return null;
    }
  }

  /// Check if two titles are similar enough to be considered a match
  bool _titlesMatch(String tasteDiveTitle, String googleTitle) {
    final td = tasteDiveTitle.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final gt = googleTitle.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // Exact match
    if (td == gt) return true;

    // One contains the other
    if (td.contains(gt) || gt.contains(td)) return true;

    // First few words match (handles subtitles)
    final tdWords = td.split(' ').take(3).join(' ');
    final gtWords = gt.split(' ').take(3).join(' ');
    if (tdWords == gtWords && tdWords.length > 5) return true;

    return false;
  }

  void dispose() {
    _client.close();
  }
}

/// Content-based provider using author and subject matching
/// This is our fallback when external APIs don't have data
class ContentBasedProvider implements RecommendationProvider {
  final BookService _bookService;

  ContentBasedProvider({BookService? bookService})
      : _bookService = bookService ?? BookService();

  @override
  String get name => 'ContentBased';

  @override
  int get priority => 10; // Lower priority than TasteDive

  @override
  Future<RecommendationResult?> getSimilarBooks(
    Book book, {
    int limit = 10,
    Set<String>? excludeIsbns,
  }) async {
    try {
      final books = <Book>[];
      final exclude = Set<String>.from(excludeIsbns ?? {});
      exclude.add(book.isbn); // Always exclude the source book

      // First, try to get books by the same author
      if (book.authors.isNotEmpty) {
        final authorBooks = await _getBooksByAuthor(
          book.authors.first,
          exclude: exclude,
          limit: limit,
        );

        for (final authorBook in authorBooks) {
          if (books.length >= limit) break;
          if (!exclude.contains(authorBook.isbn) &&
              !_isJunkBook(authorBook) &&
              _authorMatches(authorBook, book.authors.first)) {
            books.add(authorBook);
            exclude.add(authorBook.isbn);
          }
        }
      }

      // Fill remaining slots with genre-based recommendations
      final subjects = book.subjects;
      if (books.length < limit && subjects != null && subjects.isNotEmpty) {
        final subject = _getBestSubject(subjects);
        if (subject != null) {
          final genreBooks = await _bookService.getBooksBySubject(
            subject,
            limit: limit * 2,
          );

          for (final genreBook in genreBooks) {
            if (books.length >= limit) break;
            if (!exclude.contains(genreBook.isbn) && !_isJunkBook(genreBook)) {
              books.add(genreBook);
              exclude.add(genreBook.isbn);
            }
          }
        }
      }

      if (books.isEmpty) {
        return null;
      }

      return RecommendationResult(
        books: books,
        source: 'ContentBased',
        sourceBookTitle: book.title,
      );
    } catch (e) {
      debugPrint('ContentBased provider error: $e');
      return null;
    }
  }

  Future<List<Book>> _getBooksByAuthor(
    String author, {
    required Set<String> exclude,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'q': 'inauthor:$author',
        'maxResults': (limit * 2).toString(),
        'orderBy': 'relevance',
        'printType': 'books',
        'langRestrict': 'en',
      };

      final uri = Uri.parse('https://www.googleapis.com/books/v1/volumes')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        return items
            .map((item) => Book.fromGoogleBooks(item as Map<String, dynamic>))
            .where((book) => book.isbn.isNotEmpty && !exclude.contains(book.isbn))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to get books by author: $e');
    }
    return [];
  }

  /// Get the best subject for querying
  String? _getBestSubject(List<String> subjects) {
    // Priority map - lower number = more specific/better
    const priorityKeywords = {
      // Most specific genres (priority 1)
      'romantasy': 1, 'litrpg': 1, 'cozy mystery': 1, 'dark romance': 1,
      'urban fantasy': 1, 'space opera': 1, 'epic fantasy': 1,

      // Specific genres (priority 2)
      'fantasy': 2, 'science fiction': 2, 'mystery': 2, 'thriller': 2,
      'romance': 2, 'horror': 2, 'historical fiction': 2, 'dystopian': 2,
      'young adult': 2, 'memoir': 2, 'true crime': 2,

      // Broader categories (priority 3)
      'fiction': 3, 'nonfiction': 3, 'literature': 3,

      // Generic (priority 4) - avoid these
      'general': 4, 'books': 4,
    };

    String? bestSubject;
    int bestPriority = 999;

    for (final subject in subjects) {
      final lower = subject.toLowerCase();

      for (final entry in priorityKeywords.entries) {
        if (lower.contains(entry.key) && entry.value < bestPriority) {
          bestPriority = entry.value;
          bestSubject = entry.key;
        }
      }
    }

    return bestSubject;
  }

  /// Check if a book looks like junk/spam data
  bool _isJunkBook(Book book) {
    final lowerTitle = book.title.toLowerCase();

    // Filter out book sets, bundles, collections
    if (lowerTitle.contains('book set') ||
        lowerTitle.contains('box set') ||
        lowerTitle.contains('bundle') ||
        lowerTitle.contains('collection of') ||
        lowerTitle.contains('2-in-1') ||
        lowerTitle.contains('3-in-1')) {
      return true;
    }

    // Filter out gibberish titles
    final alphanumericCount = book.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').length;
    if (alphanumericCount < 3) return true;

    // Filter out books with no authors
    if (book.authors.isEmpty) return true;

    return false;
  }

  /// Check if author actually matches
  bool _authorMatches(Book book, String targetAuthor) {
    final targetLower = targetAuthor.toLowerCase();
    return book.authors.any((author) =>
        author.toLowerCase().contains(targetLower) ||
        targetLower.contains(author.toLowerCase()));
  }
}

/// Placeholder for future collaborative filtering based on user behavior
/// This will be implemented once we have enough user data
class CollaborativeFilteringProvider implements RecommendationProvider {
  @override
  String get name => 'CollaborativeFiltering';

  @override
  int get priority => 0; // Highest priority when implemented

  @override
  Future<RecommendationResult?> getSimilarBooks(
    Book book, {
    int limit = 10,
    Set<String>? excludeIsbns,
  }) async {
    // TODO: Implement when we have enough user data
    // This would query our backend for:
    // - Users who rated this book highly
    // - Other books those users rated highly
    // - Filter and rank by similarity scores

    // For now, return null to fall through to other providers
    return null;
  }
}

/// Main recommendation service that orchestrates multiple providers
class RecommendationService {
  final List<RecommendationProvider> _providers;
  final Map<String, _CachedRecommendation> _cache = {};

  static const Duration _cacheDuration = Duration(hours: 1);

  RecommendationService({List<RecommendationProvider>? providers})
      : _providers = providers ?? _defaultProviders() {
    // Sort providers by priority
    _providers.sort((a, b) => a.priority.compareTo(b.priority));
  }

  static List<RecommendationProvider> _defaultProviders() {
    return [
      // CollaborativeFilteringProvider(), // Enable when ready
      TasteDiveProvider(),
      ContentBasedProvider(),
    ];
  }

  /// Get similar books for a given book
  /// Combines results from multiple providers to fill the requested limit
  Future<RecommendationResult?> getSimilarBooks(
    Book book, {
    int limit = 10,
    Set<String>? excludeIsbns,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${book.isbn}_$limit';

    // Check cache
    if (!forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        debugPrint('RecommendationService: Cache hit for "${book.title}"');
        return cached.result;
      }
    }

    // Collect books from providers, filling up to the limit
    final allBooks = <Book>[];
    final seenIsbns = Set<String>.from(excludeIsbns ?? {});
    final sources = <String>[];

    for (final provider in _providers) {
      if (allBooks.length >= limit) break;

      final remaining = limit - allBooks.length;
      debugPrint('RecommendationService: Trying ${provider.name} for "${book.title}" (need $remaining more)');

      final result = await provider.getSimilarBooks(
        book,
        limit: remaining,
        excludeIsbns: seenIsbns,
      );

      if (result != null && result.books.isNotEmpty) {
        // Add books we haven't seen yet
        for (final resultBook in result.books) {
          if (allBooks.length >= limit) break;
          if (!seenIsbns.contains(resultBook.isbn)) {
            seenIsbns.add(resultBook.isbn);
            allBooks.add(resultBook);
          }
        }

        sources.add('${provider.name}(${result.books.length})');
        debugPrint('RecommendationService: ${provider.name} returned ${result.books.length} books, total now ${allBooks.length}');
      } else {
        debugPrint('RecommendationService: ${provider.name} returned no results');
      }
    }

    if (allBooks.isEmpty) {
      debugPrint('RecommendationService: All providers failed for "${book.title}"');
      return null;
    }

    final combinedResult = RecommendationResult(
      books: allBooks,
      source: sources.join(' + '),
      sourceBookTitle: book.title,
    );

    // Cache the combined result
    _cache[cacheKey] = _CachedRecommendation(combinedResult);

    debugPrint('RecommendationService: Combined result: ${allBooks.length} books from ${sources.join(" + ")}');
    return combinedResult;
  }

  /// Clear the cache (e.g., on pull-to-refresh)
  void clearCache() {
    _cache.clear();
  }

  /// Add a custom provider (e.g., for testing or future collaborative filtering)
  void addProvider(RecommendationProvider provider) {
    _providers.add(provider);
    _providers.sort((a, b) => a.priority.compareTo(b.priority));
  }

  void dispose() {
    for (final provider in _providers) {
      if (provider is TasteDiveProvider) {
        provider.dispose();
      }
    }
  }
}

class _CachedRecommendation {
  final RecommendationResult result;
  final DateTime timestamp;

  _CachedRecommendation(this.result) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > RecommendationService._cacheDuration;
}
