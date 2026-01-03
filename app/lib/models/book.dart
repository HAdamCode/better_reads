class Book {
  final String isbn;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final String? description;
  final int? pageCount;
  final String? publishedDate;
  final List<String>? subjects;
  final double? averageRating;
  final int? ratingsCount;

  Book({
    required this.isbn,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.description,
    this.pageCount,
    this.publishedDate,
    this.subjects,
    this.averageRating,
    this.ratingsCount,
  });

  factory Book.fromOpenLibrarySearch(Map<String, dynamic> json) {
    final isbn = (json['isbn'] as List?)?.isNotEmpty == true
        ? json['isbn'][0] as String
        : json['key']?.toString().split('/').last ?? '';

    return Book(
      isbn: isbn,
      title: json['title'] as String? ?? 'Unknown Title',
      authors: (json['author_name'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Unknown Author'],
      coverUrl: json['cover_i'] != null
          ? 'https://covers.openlibrary.org/b/id/${json['cover_i']}-L.jpg'
          : null,
      description: null, // Not available in search results
      pageCount: json['number_of_pages_median'] as int?,
      publishedDate: json['first_publish_year']?.toString(),
      subjects: (json['subject'] as List<dynamic>?)
          ?.take(5)
          .map((e) => e.toString())
          .toList(),
      averageRating: (json['ratings_average'] as num?)?.toDouble(),
      ratingsCount: json['ratings_count'] as int?,
    );
  }

  factory Book.fromGoogleBooks(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;

    // Try to get ISBN-13, then ISBN-10
    String isbn = '';
    final identifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;
    if (identifiers != null) {
      for (final id in identifiers) {
        final idMap = id as Map<String, dynamic>;
        if (idMap['type'] == 'ISBN_13') {
          isbn = idMap['identifier'] as String? ?? '';
          break;
        } else if (idMap['type'] == 'ISBN_10' && isbn.isEmpty) {
          isbn = idMap['identifier'] as String? ?? '';
        }
      }
    }
    // Fallback to Google's ID if no ISBN
    if (isbn.isEmpty) {
      isbn = json['id'] as String? ?? '';
    }

    return Book(
      isbn: isbn,
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      authors: (volumeInfo['authors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Unknown Author'],
      coverUrl: imageLinks?['thumbnail'] as String?,
      description: volumeInfo['description'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      subjects: (volumeInfo['categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      averageRating: (volumeInfo['averageRating'] as num?)?.toDouble(),
      ratingsCount: volumeInfo['ratingsCount'] as int?,
    );
  }

  factory Book.fromOpenLibraryWork(Map<String, dynamic> json, String isbn) {
    String? description;
    if (json['description'] != null) {
      if (json['description'] is String) {
        description = json['description'] as String;
      } else if (json['description'] is Map) {
        description = json['description']['value'] as String?;
      }
    }

    return Book(
      isbn: isbn,
      title: json['title'] as String? ?? 'Unknown Title',
      authors: [], // Needs separate author fetch
      coverUrl: json['covers'] != null && (json['covers'] as List).isNotEmpty
          ? 'https://covers.openlibrary.org/b/id/${json['covers'][0]}-L.jpg'
          : null,
      description: description,
      pageCount: null,
      publishedDate: null,
      subjects: (json['subjects'] as List<dynamic>?)
          ?.take(5)
          .map((e) => e.toString())
          .toList(),
      averageRating: null,
      ratingsCount: null,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      isbn: json['isbn'] as String,
      title: json['title'] as String,
      authors: List<String>.from(json['authors'] ?? []),
      coverUrl: json['coverUrl'] as String?,
      description: json['description'] as String?,
      pageCount: json['pageCount'] as int?,
      publishedDate: json['publishedDate'] as String?,
      subjects: json['subjects'] != null
          ? List<String>.from(json['subjects'])
          : null,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      ratingsCount: json['ratingsCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isbn': isbn,
      'title': title,
      'authors': authors,
      'coverUrl': coverUrl,
      'description': description,
      'pageCount': pageCount,
      'publishedDate': publishedDate,
      'subjects': subjects,
      'averageRating': averageRating,
      'ratingsCount': ratingsCount,
    };
  }

  String get authorsString => authors.join(', ');

  String get coverUrlMedium =>
      coverUrl?.replaceAll('-L.jpg', '-M.jpg') ?? coverUrl ?? '';

  String get coverUrlSmall =>
      coverUrl?.replaceAll('-L.jpg', '-S.jpg') ?? coverUrl ?? '';
}
