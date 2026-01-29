import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BookService {
  static const String _googleBooksUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const String _openLibraryUrl = 'https://openlibrary.org';
  static const String _nytBooksUrl = 'https://api.nytimes.com/svc/books/v3';

  final http.Client _client;
  String? _googleApiKey;
  String? _nytApiKey;

  BookService({http.Client? client}) : _client = client ?? http.Client() {
    _googleApiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'];
    _nytApiKey = dotenv.env['NYT_BOOKS_API_KEY'];
  }

  /// Search for books by query (title, author, or ISBN)
  Future<List<Book>> searchBooks(String query, {int limit = 20}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    try {
      // For short queries, search both by title AND general to get better results
      final words = trimmedQuery.split(' ').where((w) => w.isNotEmpty).length;
      final isShortQuery = words <= 3;

      List<Book> allBooks = [];

      // If short query, first search by title to find exact title matches
      if (isShortQuery) {
        final titleBooks = await _searchGoogle('intitle:$trimmedQuery', limit: limit ~/ 2);
        allBooks.addAll(titleBooks);
      }

      // Then do a general search
      final generalBooks = await _searchGoogle(trimmedQuery, limit: limit);
      allBooks.addAll(generalBooks);

      // Remove duplicates, keeping first occurrence (title matches first)
      final seen = <String>{};
      final uniqueBooks = allBooks.where((book) => seen.add(book.isbn)).toList();

      return uniqueBooks.take(limit).toList();
    } catch (e) {
      if (e is BookServiceException) rethrow;
      throw BookServiceException('Network error: $e');
    }
  }

  /// Internal Google Books search helper
  Future<List<Book>> _searchGoogle(String query, {int limit = 20}) async {
    final uri = Uri.parse(_googleBooksUrl).replace(queryParameters: {
      'q': query,
      'maxResults': limit.toString(),
      if (_googleApiKey != null && _googleApiKey!.isNotEmpty) 'key': _googleApiKey!,
    });

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      return items
          .map((item) => Book.fromGoogleBooks(item as Map<String, dynamic>))
          .where((book) => book.isbn.isNotEmpty)
          .toList();
    } else {
      throw BookServiceException('Failed to search books: ${response.statusCode}');
    }
  }

  /// Search by title and author combination for better accuracy (used for import fallback)
  Future<List<Book>> searchByTitleAuthor(String title, String author, {int limit = 5}) async {
    if (title.isEmpty) return [];

    try {
      // Use intitle and inauthor operators for Google Books
      final query = author.isNotEmpty
          ? 'intitle:$title inauthor:$author'
          : 'intitle:$title';
      return _searchGoogle(query, limit: limit);
    } catch (e) {
      if (e is BookServiceException) rethrow;
      throw BookServiceException('Network error: $e');
    }
  }

  /// Search for books by ISBN
  Future<Book?> getBookByIsbn(String isbn) async {
    final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9X]'), '');

    final queryParams = {
      'q': 'isbn:$cleanIsbn',
    };
    if (_googleApiKey != null && _googleApiKey!.isNotEmpty) {
      queryParams['key'] = _googleApiKey!;
    }

    final uri = Uri.parse(_googleBooksUrl).replace(queryParameters: queryParams);

    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;

        if (items == null || items.isEmpty) {
          return null;
        }

        return Book.fromGoogleBooks(items[0] as Map<String, dynamic>);
      } else {
        throw BookServiceException(
          'Failed to get book: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is BookServiceException) rethrow;
      throw BookServiceException('Network error: $e');
    }
  }

  /// Get book details by Open Library work key
  Future<Book?> getBookByWorkKey(String workKey) async {
    final uri = Uri.parse('$_openLibraryUrl/works/$workKey.json');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'BetterReads/1.0 (contact@betterreads.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Book.fromOpenLibraryWork(data, workKey);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw BookServiceException(
          'Failed to get book details: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is BookServiceException) rethrow;
      throw BookServiceException('Network error: $e');
    }
  }

  /// Fetch ratings from Open Library for a book by ISBN
  /// Returns a map with 'averageRating' and 'ratingsCount' or null if not found
  Future<Map<String, dynamic>?> getRatingsFromOpenLibrary(String isbn) async {
    final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9X]'), '');
    if (cleanIsbn.isEmpty) return null;

    try {
      // First, get the work key from ISBN
      final editionUri = Uri.parse('$_openLibraryUrl/isbn/$cleanIsbn.json');
      final editionResponse = await _client.get(
        editionUri,
        headers: {
          'User-Agent': 'BetterReads/1.0 (contact@betterreads.app)',
        },
      );

      if (editionResponse.statusCode != 200) return null;

      final editionData = json.decode(editionResponse.body) as Map<String, dynamic>;
      final works = editionData['works'] as List<dynamic>?;
      if (works == null || works.isEmpty) return null;

      final workKey = (works[0] as Map<String, dynamic>)['key'] as String?;
      if (workKey == null) return null;

      // Now fetch ratings for this work
      final ratingsUri = Uri.parse('$_openLibraryUrl$workKey/ratings.json');
      final ratingsResponse = await _client.get(
        ratingsUri,
        headers: {
          'User-Agent': 'BetterReads/1.0 (contact@betterreads.app)',
        },
      );

      if (ratingsResponse.statusCode != 200) return null;

      final ratingsData = json.decode(ratingsResponse.body) as Map<String, dynamic>;
      final summary = ratingsData['summary'] as Map<String, dynamic>?;

      if (summary == null) return null;

      final average = summary['average'] as num?;
      final count = summary['count'] as int?;

      if (average == null || count == null || count == 0) return null;

      return {
        'averageRating': average.toDouble(),
        'ratingsCount': count,
      };
    } catch (e) {
      debugPrint('Failed to fetch Open Library ratings: $e');
      return null;
    }
  }

  /// Get books by subject/category from Google Books
  Future<List<Book>> getBooksBySubject(String subject, {int limit = 20, int offset = 0}) async {
    final queryParams = {
      'q': 'subject:$subject',
      'maxResults': limit.toString(),
      'startIndex': offset.toString(),
      'orderBy': 'relevance',
      'printType': 'books',
      'langRestrict': 'en',
    };
    if (_googleApiKey != null && _googleApiKey!.isNotEmpty) {
      queryParams['key'] = _googleApiKey!;
    }

    final uri = Uri.parse(_googleBooksUrl).replace(queryParameters: queryParams);

    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        final books = items
            .map((item) => Book.fromGoogleBooks(item as Map<String, dynamic>))
            .where((book) => book.isbn.isNotEmpty)
            .toList();

        // Sort books with ratings first, then by rating value
        books.sort((a, b) {
          if (a.averageRating != null && b.averageRating == null) return -1;
          if (a.averageRating == null && b.averageRating != null) return 1;
          if (a.averageRating != null && b.averageRating != null) {
            return b.averageRating!.compareTo(a.averageRating!);
          }
          return 0;
        });

        return books;
      } else {
        throw BookServiceException(
          'Failed to get books by subject: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is BookServiceException) rethrow;
      throw BookServiceException('Network error: $e');
    }
  }

  /// Get trending books from NYT Bestsellers, enriched with Google Books data
  Future<List<Book>> getTrendingBooks({int limit = 15}) async {
    if (_nytApiKey == null || _nytApiKey!.isEmpty) {
      debugPrint('NYT API key not configured, falling back to Google Books');
      return _getTrendingFromGoogle(limit: limit);
    }

    try {
      // Fetch from both fiction and nonfiction lists in parallel
      final lists = ['combined-print-and-e-book-fiction', 'combined-print-and-e-book-nonfiction'];

      final futures = lists.map((listName) async {
        final uri = Uri.parse('$_nytBooksUrl/lists/current/$listName.json').replace(
          queryParameters: {'api-key': _nytApiKey!},
        );

        final response = await _client.get(uri);

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final results = data['results'] as Map<String, dynamic>?;
          final books = results?['books'] as List<dynamic>? ?? [];

          return books.map((book) {
            final bookData = book as Map<String, dynamic>;
            return Book(
              isbn: bookData['primary_isbn13'] as String? ?? '',
              title: _titleCase(bookData['title'] as String? ?? 'Unknown'),
              authors: [(bookData['author'] as String? ?? 'Unknown')],
              coverUrl: bookData['book_image'] as String?,
              description: bookData['description'] as String?,
              publishedDate: null,
              // Store rank in ratingsCount temporarily for sorting
              ratingsCount: bookData['rank'] as int?,
            );
          }).where((book) => book.isbn.isNotEmpty).toList();
        }
        return <Book>[];
      });

      final results = await Future.wait(futures);
      final allBooks = results.expand((books) => books).toList();

      // Remove duplicates, keeping the one with better rank
      final seen = <String, Book>{};
      for (final book in allBooks) {
        if (!seen.containsKey(book.isbn) ||
            (book.ratingsCount ?? 99) < (seen[book.isbn]!.ratingsCount ?? 99)) {
          seen[book.isbn] = book;
        }
      }

      // Sort by rank (lower is better)
      final uniqueBooks = seen.values.toList()
        ..sort((a, b) => (a.ratingsCount ?? 99).compareTo(b.ratingsCount ?? 99));

      // Enrich top books with Open Library ratings
      final enrichedBooks = await _enrichWithRatings(uniqueBooks.take(limit).toList());

      return enrichedBooks;
    } catch (e) {
      debugPrint('Failed to fetch NYT bestsellers: $e');
      return _getTrendingFromGoogle(limit: limit);
    }
  }

  /// Enrich NYT books with Open Library ratings (better coverage than Google Books)
  Future<List<Book>> _enrichWithRatings(List<Book> books) async {
    // Fetch ratings in parallel for speed
    final futures = books.map((book) async {
      try {
        final ratings = await getRatingsFromOpenLibrary(book.isbn);
        if (ratings != null) {
          return book.copyWith(
            averageRating: ratings['averageRating'] as double?,
            ratingsCount: ratings['ratingsCount'] as int?,
          );
        }
      } catch (e) {
        debugPrint('Failed to get ratings for ${book.isbn}: $e');
      }
      return book.copyWith(ratingsCount: null);
    });

    return Future.wait(futures);
  }

  /// Fallback to Google Books for trending
  Future<List<Book>> _getTrendingFromGoogle({int limit = 12}) async {
    const genres = ['thriller', 'mystery', 'romance', 'fantasy', 'biography'];

    final futures = genres.map((genre) async {
      try {
        final queryParams = {
          'q': 'subject:$genre',
          'maxResults': '8',
          'orderBy': 'relevance',
          'printType': 'books',
          'langRestrict': 'en',
        };
        if (_googleApiKey != null && _googleApiKey!.isNotEmpty) {
          queryParams['key'] = _googleApiKey!;
        }

        final uri = Uri.parse(_googleBooksUrl).replace(queryParameters: queryParams);
        final response = await _client.get(uri);

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? [];

          return items
              .map((item) => Book.fromGoogleBooks(item as Map<String, dynamic>))
              .where((book) => book.isbn.isNotEmpty && book.averageRating != null)
              .toList();
        }
      } catch (e) {
        debugPrint('Failed to fetch $genre for trending: $e');
      }
      return <Book>[];
    });

    final results = await Future.wait(futures);
    final allBooks = results.expand((books) => books).toList();

    final seen = <String>{};
    final uniqueBooks = allBooks.where((book) => seen.add(book.isbn)).toList();
    uniqueBooks.sort((a, b) => b.averageRating!.compareTo(a.averageRating!));

    return uniqueBooks.take(limit).toList();
  }

  /// Convert ALL CAPS title to Title Case
  String _titleCase(String text) {
    if (text == text.toUpperCase()) {
      return text.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    return text;
  }

  void dispose() {
    _client.close();
  }
}


class BookServiceException implements Exception {
  final String message;

  BookServiceException(this.message);

  @override
  String toString() => 'BookServiceException: $message';
}
