import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BookService {
  static const String _baseUrl = 'https://openlibrary.org';
  static const String _searchUrl = '$_baseUrl/search.json';
  static const String _worksUrl = '$_baseUrl/works';

  final http.Client _client;

  BookService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for books by query (title, author, or ISBN)
  Future<List<Book>> searchBooks(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final uri = Uri.parse('$_searchUrl').replace(queryParameters: {
      'q': query,
      'limit': limit.toString(),
      'fields':
          'key,title,author_name,cover_i,isbn,first_publish_year,number_of_pages_median,subject,ratings_average,ratings_count',
    });

    try {
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'BetterReads/1.0 (contact@betterreads.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docs = data['docs'] as List<dynamic>? ?? [];

        return docs
            .map((doc) =>
                Book.fromOpenLibrarySearch(doc as Map<String, dynamic>))
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

    final uri = Uri.parse('$_baseUrl/api/books').replace(queryParameters: {
      'bibkeys': 'ISBN:$cleanIsbn',
      'format': 'json',
      'jscmd': 'data',
    });

    try {
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'BetterReads/1.0 (contact@betterreads.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data.isEmpty) {
          return null;
        }

        final bookData = data['ISBN:$cleanIsbn'] as Map<String, dynamic>?;
        if (bookData == null) {
          return null;
        }

        return _parseBookFromApiData(bookData, cleanIsbn);
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
    final uri = Uri.parse('$_worksUrl/$workKey.json');

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

  /// Get trending/popular books
  Future<List<Book>> getTrendingBooks({int limit = 10}) async {
    // Open Library trending endpoint
    final uri = Uri.parse('$_baseUrl/trending/daily.json').replace(
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

  /// Get book cover URL
  static String? getCoverUrl(String? isbn, {String size = 'L'}) {
    if (isbn == null || isbn.isEmpty) return null;
    return 'https://covers.openlibrary.org/b/isbn/$isbn-$size.jpg';
  }

  Book _parseBookFromApiData(Map<String, dynamic> data, String isbn) {
    final authors = (data['authors'] as List<dynamic>?)
            ?.map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        ['Unknown Author'];

    final subjects = (data['subjects'] as List<dynamic>?)
        ?.take(5)
        .map((s) => (s as Map<String, dynamic>)['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    String? coverUrl;
    if (data['cover'] != null) {
      coverUrl = data['cover']['large'] as String? ??
          data['cover']['medium'] as String? ??
          data['cover']['small'] as String?;
    }

    return Book(
      isbn: isbn,
      title: data['title'] as String? ?? 'Unknown Title',
      authors: authors,
      coverUrl: coverUrl,
      description: null,
      pageCount: data['number_of_pages'] as int?,
      publishedDate: data['publish_date'] as String?,
      subjects: subjects,
      averageRating: null,
      ratingsCount: null,
    );
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
