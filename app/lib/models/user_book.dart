import 'book.dart';

enum ReadingStatus {
  wantToRead,
  currentlyReading,
  read,
  none, // For books only on custom shelves
}

extension ReadingStatusExtension on ReadingStatus {
  String get displayName {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.currentlyReading:
        return 'Currently Reading';
      case ReadingStatus.read:
        return 'Read';
      case ReadingStatus.none:
        return 'No Status';
    }
  }

  String get apiValue {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'WANT_TO_READ';
      case ReadingStatus.currentlyReading:
        return 'CURRENTLY_READING';
      case ReadingStatus.read:
        return 'READ';
      case ReadingStatus.none:
        return 'NONE';
    }
  }

  static ReadingStatus fromApiValue(String value) {
    switch (value) {
      case 'WANT_TO_READ':
        return ReadingStatus.wantToRead;
      case 'CURRENTLY_READING':
        return ReadingStatus.currentlyReading;
      case 'READ':
        return ReadingStatus.read;
      case 'NONE':
        return ReadingStatus.none;
      default:
        return ReadingStatus.wantToRead;
    }
  }
}

// Keep old Shelf enum as alias for backward compatibility during migration
typedef Shelf = ReadingStatus;

class UserBook {
  final String userId;
  final String bookId;
  final ReadingStatus readingStatus;
  final List<String> customShelfIds;
  final int? rating;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? pagesRead;
  final DateTime addedAt;
  final DateTime updatedAt;
  final Book? book;

  UserBook({
    required this.userId,
    required this.bookId,
    required this.readingStatus,
    this.customShelfIds = const [],
    this.rating,
    this.startedAt,
    this.finishedAt,
    this.pagesRead,
    required this.addedAt,
    required this.updatedAt,
    this.book,
  });

  // Legacy getter for backward compatibility
  ReadingStatus get shelf => readingStatus;

  factory UserBook.fromJson(Map<String, dynamic> json) {
    // Handle migration from old 'shelf' field to new 'readingStatus'
    final statusValue = json['readingStatus'] as String? ??
                        json['shelf'] as String? ??
                        'WANT_TO_READ';

    // Parse customShelfIds, defaulting to empty list
    final shelfIds = (json['customShelfIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [];

    return UserBook(
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      readingStatus: ReadingStatusExtension.fromApiValue(statusValue),
      customShelfIds: shelfIds,
      rating: json['rating'] as int?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      pagesRead: json['pagesRead'] as int?,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : (json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now()),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      book: json['book'] != null
          ? Book.fromJson(json['book'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'bookId': bookId,
      'readingStatus': readingStatus.apiValue,
      'customShelfIds': customShelfIds,
      'rating': rating,
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'pagesRead': pagesRead,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'book': book?.toJson(),
    };
  }

  UserBook copyWith({
    String? userId,
    String? bookId,
    ReadingStatus? readingStatus,
    List<String>? customShelfIds,
    int? rating,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? pagesRead,
    DateTime? addedAt,
    DateTime? updatedAt,
    Book? book,
  }) {
    return UserBook(
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      readingStatus: readingStatus ?? this.readingStatus,
      customShelfIds: customShelfIds ?? this.customShelfIds,
      rating: rating ?? this.rating,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      pagesRead: pagesRead ?? this.pagesRead,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      book: book ?? this.book,
    );
  }

  /// Check if book is on a specific custom shelf
  bool isOnCustomShelf(String shelfId) => customShelfIds.contains(shelfId);

  /// Check if book has any reading status set
  bool get hasReadingStatus => readingStatus != ReadingStatus.none;
}
