import 'package:intl/intl.dart';
import 'user_book.dart';

class GoodreadsBook {
  final String? isbn;
  final String? isbn13;
  final String title;
  final String author;
  final String? additionalAuthors;
  final int myRating; // 0-5, 0 means not rated
  final String exclusiveShelf; // read, currently-reading, to-read
  final List<String> bookshelves; // Custom shelf names
  final DateTime? dateRead;
  final DateTime? dateAdded;
  final int? numberOfPages;
  final String? goodreadsBookId;

  GoodreadsBook({
    this.isbn,
    this.isbn13,
    required this.title,
    required this.author,
    this.additionalAuthors,
    required this.myRating,
    required this.exclusiveShelf,
    required this.bookshelves,
    this.dateRead,
    this.dateAdded,
    this.numberOfPages,
    this.goodreadsBookId,
  });

  factory GoodreadsBook.fromCsvRow(Map<String, dynamic> row) {
    // Clean ISBN values (remove quotes and equals signs that Goodreads adds)
    String? cleanIsbn(String? value) {
      if (value == null || value.isEmpty) return null;
      // Remove ="..." wrapper that Goodreads uses
      final cleaned = value.replaceAll(RegExp(r'^="?|"$'), '').trim();
      return cleaned.isEmpty ? null : cleaned;
    }

    // Parse date from various Goodreads formats
    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) return null;
      try {
        // Try yyyy/MM/dd format first
        if (value.contains('/')) {
          return DateFormat('yyyy/MM/dd').parse(value);
        }
        // Try other common formats
        final formats = [
          'yyyy-MM-dd',
          'MMM dd, yyyy',
          'MMMM dd, yyyy',
        ];
        for (final format in formats) {
          try {
            return DateFormat(format).parse(value);
          } catch (_) {}
        }
      } catch (_) {}
      return null;
    }

    // Parse bookshelves (comma-separated, may be empty)
    List<String> parseShelves(String? value) {
      if (value == null || value.isEmpty) return [];
      return value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Parse integer safely
    int? parseInt(String? value) {
      if (value == null || value.isEmpty) return null;
      return int.tryParse(value);
    }

    return GoodreadsBook(
      isbn: cleanIsbn(row['ISBN']?.toString()),
      isbn13: cleanIsbn(row['ISBN13']?.toString()),
      title: row['Title']?.toString().trim() ?? '',
      author: row['Author']?.toString().trim() ?? '',
      additionalAuthors: row['Additional Authors']?.toString().trim(),
      myRating: parseInt(row['My Rating']?.toString()) ?? 0,
      exclusiveShelf: row['Exclusive Shelf']?.toString().trim() ?? 'to-read',
      bookshelves: parseShelves(row['Bookshelves']?.toString()),
      dateRead: parseDate(row['Date Read']?.toString()),
      dateAdded: parseDate(row['Date Added']?.toString()),
      numberOfPages: parseInt(row['Number of Pages']?.toString()),
      goodreadsBookId: row['Book Id']?.toString(),
    );
  }

  /// Maps Goodreads exclusive shelf to ReadingStatus
  ReadingStatus get readingStatus {
    switch (exclusiveShelf.toLowerCase()) {
      case 'read':
        return ReadingStatus.read;
      case 'currently-reading':
        return ReadingStatus.currentlyReading;
      case 'to-read':
        return ReadingStatus.wantToRead;
      default:
        // Unknown shelf - default to want to read
        return ReadingStatus.wantToRead;
    }
  }

  /// Gets best available ISBN (prefers ISBN13)
  String? get bestIsbn {
    if (isbn13 != null && isbn13!.isNotEmpty) return isbn13;
    if (isbn != null && isbn!.isNotEmpty) return isbn;
    return null;
  }

  /// Check if this book has a valid ISBN for lookup
  bool get hasValidIsbn => bestIsbn != null;

  /// Rating for import (null if not rated)
  int? get ratingForImport => myRating > 0 ? myRating : null;

  /// Get all custom shelf names (excluding the exclusive shelf categories)
  List<String> get customShelfNames {
    final excluded = {'read', 'currently-reading', 'to-read'};
    return bookshelves
        .where((s) => !excluded.contains(s.toLowerCase()))
        .toList();
  }

  @override
  String toString() => 'GoodreadsBook(title: $title, author: $author, isbn: $bestIsbn)';
}
