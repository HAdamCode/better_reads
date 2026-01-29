import 'dart:convert';

class CustomShelf {
  final String shelfId;
  final String userId;
  final String name;
  final String? description;
  final Map<String, int> bookRatings;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomShelf({
    required this.shelfId,
    required this.userId,
    required this.name,
    this.description,
    this.bookRatings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Alias for shelfId for backward compatibility
  String get id => shelfId;

  factory CustomShelf.fromGraphQL(Map<String, dynamic> json) {
    // Parse bookRatings - can be a JSON string or a Map
    Map<String, int> ratings = {};
    if (json['bookRatings'] != null) {
      final ratingsData = json['bookRatings'];
      if (ratingsData is String) {
        final parsed = jsonDecode(ratingsData) as Map<String, dynamic>;
        ratings = parsed.map((k, v) => MapEntry(k, v as int));
      } else if (ratingsData is Map) {
        ratings = Map<String, int>.from(ratingsData.map((k, v) => MapEntry(k.toString(), v as int)));
      }
    }

    return CustomShelf(
      shelfId: json['shelfId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      bookRatings: ratings,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  CustomShelf copyWith({
    String? shelfId,
    String? userId,
    String? name,
    String? description,
    Map<String, int>? bookRatings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomShelf(
      shelfId: shelfId ?? this.shelfId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      bookRatings: bookRatings ?? this.bookRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the rating for a specific book on this shelf
  int? getBookRating(String bookId) => bookRatings[bookId];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomShelf &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
