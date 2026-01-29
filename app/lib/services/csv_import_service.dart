import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/goodreads_book.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/shelves_provider.dart';
import 'book_service.dart';

enum ImportStatus { pending, lookingUp, importing, added, updated, failed, skipped }

class ImportBookResult {
  final GoodreadsBook goodreadsBook;
  final Book? resolvedBook;
  final ImportStatus status;
  final String? errorMessage;

  ImportBookResult({
    required this.goodreadsBook,
    this.resolvedBook,
    required this.status,
    this.errorMessage,
  });
}

class ImportProgress {
  final int total;
  final int processed;
  final int added;
  final int updated;
  final int failed;
  final int skipped;
  final String currentBookTitle;
  final List<ImportBookResult> results;
  final bool isComplete;
  final bool isCancelled;

  ImportProgress({
    required this.total,
    required this.processed,
    required this.added,
    required this.updated,
    required this.failed,
    required this.skipped,
    required this.currentBookTitle,
    required this.results,
    this.isComplete = false,
    this.isCancelled = false,
  });

  /// Total successful (added + updated)
  int get successful => added + updated;

  double get progressPercent => total > 0 ? processed / total : 0;

  ImportProgress copyWith({
    int? total,
    int? processed,
    int? added,
    int? updated,
    int? failed,
    int? skipped,
    String? currentBookTitle,
    List<ImportBookResult>? results,
    bool? isComplete,
    bool? isCancelled,
  }) {
    return ImportProgress(
      total: total ?? this.total,
      processed: processed ?? this.processed,
      added: added ?? this.added,
      updated: updated ?? this.updated,
      failed: failed ?? this.failed,
      skipped: skipped ?? this.skipped,
      currentBookTitle: currentBookTitle ?? this.currentBookTitle,
      results: results ?? this.results,
      isComplete: isComplete ?? this.isComplete,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}

class ImportPreview {
  final int totalBooks;
  final int readCount;
  final int currentlyReadingCount;
  final int wantToReadCount;
  final int booksWithIsbn;
  final int booksWithoutIsbn;
  final Set<String> customShelvesToCreate;
  final List<GoodreadsBook> books;

  ImportPreview({
    required this.totalBooks,
    required this.readCount,
    required this.currentlyReadingCount,
    required this.wantToReadCount,
    required this.booksWithIsbn,
    required this.booksWithoutIsbn,
    required this.customShelvesToCreate,
    required this.books,
  });
}

class CsvImportService {
  final BookService _bookService;
  final BooksProvider _booksProvider;
  final ShelvesProvider _shelvesProvider;

  final _progressController = StreamController<ImportProgress>.broadcast();
  bool _isCancelled = false;

  Stream<ImportProgress> get progressStream => _progressController.stream;

  CsvImportService({
    required BookService bookService,
    required BooksProvider booksProvider,
    required ShelvesProvider shelvesProvider,
  })  : _bookService = bookService,
        _booksProvider = booksProvider,
        _shelvesProvider = shelvesProvider;

  /// Parse CSV file and return preview information
  Future<ImportPreview> parseCsvFile(String filePath) async {
    final file = File(filePath);
    final contents = await file.readAsString();

    final rows = const CsvToListConverter(eol: '\n').convert(contents);

    if (rows.isEmpty) {
      throw ImportException('CSV file is empty');
    }

    // First row is headers
    final headers = rows.first.map((e) => e.toString()).toList();
    final requiredHeaders = ['Title', 'Author'];

    for (final header in requiredHeaders) {
      if (!headers.contains(header)) {
        throw ImportException('Missing required column: $header');
      }
    }

    // Parse remaining rows
    final books = <GoodreadsBook>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || (row.length == 1 && row[0].toString().trim().isEmpty)) {
        continue; // Skip empty rows
      }

      // Create a map from headers to values
      final rowMap = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        rowMap[headers[j]] = row[j];
      }

      try {
        final book = GoodreadsBook.fromCsvRow(rowMap);
        if (book.title.isNotEmpty) {
          books.add(book);
        }
      } catch (e) {
        debugPrint('Failed to parse row $i: $e');
      }
    }

    if (books.isEmpty) {
      throw ImportException('No valid books found in CSV');
    }

    // Collect statistics
    int readCount = 0;
    int currentlyReadingCount = 0;
    int wantToReadCount = 0;
    int withIsbn = 0;
    int withoutIsbn = 0;
    final customShelves = <String>{};

    for (final book in books) {
      switch (book.readingStatus) {
        case ReadingStatus.read:
          readCount++;
          break;
        case ReadingStatus.currentlyReading:
          currentlyReadingCount++;
          break;
        case ReadingStatus.wantToRead:
          wantToReadCount++;
          break;
        case ReadingStatus.none:
          break;
      }

      if (book.hasValidIsbn) {
        withIsbn++;
      } else {
        withoutIsbn++;
      }

      customShelves.addAll(book.customShelfNames);
    }

    // Filter out shelves that already exist
    final newShelves = customShelves
        .where((name) => !_shelvesProvider.shelfNameExists(name))
        .toSet();

    return ImportPreview(
      totalBooks: books.length,
      readCount: readCount,
      currentlyReadingCount: currentlyReadingCount,
      wantToReadCount: wantToReadCount,
      booksWithIsbn: withIsbn,
      booksWithoutIsbn: withoutIsbn,
      customShelvesToCreate: newShelves,
      books: books,
    );
  }

  /// Main import method - processes books with rate limiting
  /// Updates existing books if they're already in the library
  Future<ImportProgress> importBooks(
    List<GoodreadsBook> books, {
    bool importRatings = true,
    bool importDates = true,
    int batchSize = 5,
    Duration delayBetweenBatches = const Duration(milliseconds: 500),
  }) async {
    _isCancelled = false;

    final results = <ImportBookResult>[];
    int added = 0;
    int updated = 0;
    int failed = 0;
    int skipped = 0;

    // First, create all custom shelves
    final shelfNameToId = await _ensureCustomShelvesExist(books);

    // Process books in batches
    for (var i = 0; i < books.length && !_isCancelled; i += batchSize) {
      final batch = books.skip(i).take(batchSize).toList();

      for (final grBook in batch) {
        if (_isCancelled) break;

        // Update progress - looking up
        _progressController.add(ImportProgress(
          total: books.length,
          processed: i + batch.indexOf(grBook),
          added: added,
          updated: updated,
          failed: failed,
          skipped: skipped,
          currentBookTitle: grBook.title,
          results: List.from(results),
        ));

        // Try to resolve book
        final book = await _resolveBook(grBook);

        if (book == null) {
          failed++;
          results.add(ImportBookResult(
            goodreadsBook: grBook,
            status: ImportStatus.failed,
            errorMessage: 'Book not found',
          ));
          continue;
        }

        // Map custom shelf names to IDs
        final customShelfIds = grBook.customShelfNames
            .map((name) => shelfNameToId[name.toLowerCase()])
            .where((id) => id != null)
            .cast<String>()
            .toList();

        // Import or update the book
        final result = await _booksProvider.importOrUpdateBook(
          book: book,
          status: grBook.readingStatus,
          customShelfIds: customShelfIds,
          rating: importRatings ? grBook.ratingForImport : null,
          dateRead: importDates ? grBook.dateRead : null,
          dateAdded: importDates ? grBook.dateAdded : null,
          notify: false, // We'll batch notify
        );

        switch (result) {
          case 'added':
            added++;
            results.add(ImportBookResult(
              goodreadsBook: grBook,
              resolvedBook: book,
              status: ImportStatus.added,
            ));
            break;
          case 'updated':
            updated++;
            results.add(ImportBookResult(
              goodreadsBook: grBook,
              resolvedBook: book,
              status: ImportStatus.updated,
            ));
            break;
          default:
            failed++;
            results.add(ImportBookResult(
              goodreadsBook: grBook,
              resolvedBook: book,
              status: ImportStatus.failed,
              errorMessage: 'Failed to save',
            ));
        }
      }

      // Notify UI and save cache after each batch
      await _booksProvider.notifyBatchComplete();

      // Delay between batches to respect API rate limits
      if (i + batchSize < books.length && !_isCancelled) {
        await Future.delayed(delayBetweenBatches);
      }
    }

    final finalProgress = ImportProgress(
      total: books.length,
      processed: books.length,
      added: added,
      updated: updated,
      failed: failed,
      skipped: skipped,
      currentBookTitle: '',
      results: results,
      isComplete: true,
      isCancelled: _isCancelled,
    );

    _progressController.add(finalProgress);
    return finalProgress;
  }

  /// Look up book by ISBN, fallback to title+author search
  Future<Book?> _resolveBook(GoodreadsBook grBook) async {
    try {
      // Try ISBN13 first
      if (grBook.isbn13 != null && grBook.isbn13!.isNotEmpty) {
        final book = await _bookService.getBookByIsbn(grBook.isbn13!);
        if (book != null) return book;
      }

      // Try ISBN10
      if (grBook.isbn != null && grBook.isbn!.isNotEmpty) {
        final book = await _bookService.getBookByIsbn(grBook.isbn!);
        if (book != null) return book;
      }

      // Fallback: Search by title + author
      final results = await _bookService.searchByTitleAuthor(
        grBook.title,
        grBook.author,
        limit: 5,
      );

      if (results.isEmpty) return null;

      // Find best match
      return _findBestMatch(results, grBook);
    } catch (e) {
      debugPrint('Error resolving book "${grBook.title}": $e');
      return null;
    }
  }

  /// Find the best matching book from search results
  Book? _findBestMatch(List<Book> results, GoodreadsBook grBook) {
    if (results.isEmpty) return null;

    final normalizedTitle = grBook.title.toLowerCase().trim();
    final normalizedAuthor = grBook.author.toLowerCase().trim();

    // Score each result
    Book? bestMatch;
    int bestScore = -1;

    for (final book in results) {
      int score = 0;

      // Title similarity
      final bookTitle = book.title.toLowerCase().trim();
      if (bookTitle == normalizedTitle) {
        score += 10;
      } else if (bookTitle.contains(normalizedTitle) || normalizedTitle.contains(bookTitle)) {
        score += 5;
      }

      // Author similarity
      for (final author in book.authors) {
        final bookAuthor = author.toLowerCase().trim();
        if (bookAuthor == normalizedAuthor || normalizedAuthor.contains(bookAuthor)) {
          score += 10;
          break;
        } else if (bookAuthor.split(' ').last == normalizedAuthor.split(' ').last) {
          // Last name match
          score += 5;
          break;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = book;
      }
    }

    // Require minimum score to accept match
    return bestScore >= 5 ? bestMatch : results.first;
  }

  /// Create custom shelves that don't exist
  Future<Map<String, String>> _ensureCustomShelvesExist(List<GoodreadsBook> books) async {
    // Collect all unique custom shelf names
    final allShelfNames = <String>{};
    for (final book in books) {
      allShelfNames.addAll(book.customShelfNames);
    }

    // Create mapping of shelf name (lowercase) to ID
    final shelfNameToId = <String, String>{};

    for (final name in allShelfNames) {
      final shelfId = await _shelvesProvider.getOrCreateShelf(name);
      if (shelfId != null) {
        shelfNameToId[name.toLowerCase()] = shelfId;
      }
    }

    return shelfNameToId;
  }

  /// Cancel ongoing import
  void cancelImport() {
    _isCancelled = true;
  }

  void dispose() {
    _progressController.close();
  }
}

class ImportException implements Exception {
  final String message;
  ImportException(this.message);

  @override
  String toString() => message;
}
