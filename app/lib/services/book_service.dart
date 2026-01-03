import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BookService {
  static const String _googleBooksUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const String _openLibraryUrl = 'https://openlibrary.org';

  final http.Client _client;
  String? _apiKey;

  BookService({http.Client? client}) : _client = client ?? http.Client() {
    _apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'];
  }

  /// Search for books by query (title, author, or ISBN)
  Future<List<Book>> searchBooks(String query, {int limit = 20}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    // Google Books API works without a key (lower rate limits)
    // Add key if available for higher rate limits
    final uri = Uri.parse(_googleBooksUrl).replace(queryParameters: {
      'q': trimmedQuery,
      'maxResults': limit.toString(),
      if (_apiKey != null && _apiKey!.isNotEmpty) 'key': _apiKey!,
    });

    try {
      debugPrint('Search URL: $uri');
      final response = await _client.get(uri);

      debugPrint('Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        return items
            .map((item) => Book.fromGoogleBooks(item as Map<String, dynamic>))
            .where((book) => book.isbn.isNotEmpty)
            .toList();
      } else {
        throw BookServiceException(
          'Failed to search books: ${response.statusCode}',
        );
      }
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
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      queryParams['key'] = _apiKey!;
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

  /// Get trending/popular books
  Future<List<Book>> getTrendingBooks({int limit = 10}) async {
    // Open Library trending endpoint
    final uri = Uri.parse('$_openLibraryUrl/trending/daily.json').replace(
      queryParameters: {'limit': limit.toString()},
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'BetterReads/1.0 (contact@betterreads.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final works = data['works'] as List<dynamic>? ?? [];

        return works.map((work) {
          final workData = work as Map<String, dynamic>;
          return Book(
            isbn: workData['key']?.toString().split('/').last ?? '',
            title: workData['title'] as String? ?? 'Unknown',
            authors: (workData['author_name'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                ['Unknown'],
            coverUrl: workData['cover_i'] != null
                ? 'https://covers.openlibrary.org/b/id/${workData['cover_i']}-L.jpg'
                : null,
            publishedDate: workData['first_publish_year']?.toString(),
          );
        }).toList();
      } else {
        throw BookServiceException(
          'Failed to get trending books: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is BookServiceException) rethrow;
      throw BookServiceException('Network error: $e');
    }
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
