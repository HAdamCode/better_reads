import 'book.dart';

enum Shelf {
  wantToRead,
  currentlyReading,
  read,
}

extension ShelfExtension on Shelf {
  String get displayName {
    switch (this) {
      case Shelf.wantToRead:
        return 'Want to Read';
      case Shelf.currentlyReading:
        return 'Currently Reading';
      case Shelf.read:
        return 'Read';
    }
  }

  String get apiValue {
    switch (this) {
      case Shelf.wantToRead:
        return 'WANT_TO_READ';
      case Shelf.currentlyReading:
        return 'CURRENTLY_READING';
      case Shelf.read:
        return 'READ';
    }
  }

  static Shelf fromApiValue(String value) {
    switch (value) {
      case 'WANT_TO_READ':
        return Shelf.wantToRead;
      case 'CURRENTLY_READING':
        return Shelf.currentlyReading;
      case 'READ':
        return Shelf.read;
      default:
        return Shelf.wantToRead;
    }
  }
}

class UserBook {
  final String userId;
  final String bookId;
  final Shelf shelf;
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
    required this.shelf,
    this.rating,
    this.startedAt,
    this.finishedAt,
    this.pagesRead,
    required this.addedAt,
    required this.updatedAt,
    this.book,
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      shelf: ShelfExtension.fromApiValue(json['shelf'] as String),
      rating: json['rating'] as int?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      pagesRead: json['pagesRead'] as int?,
      addedAt: DateTime.parse(json['addedAt'] as String),
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
      'shelf': shelf.apiValue,
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
    Shelf? shelf,
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
      shelf: shelf ?? this.shelf,
      rating: rating ?? this.rating,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      pagesRead: pagesRead ?? this.pagesRead,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      book: book ?? this.book,
    );
  }
}
