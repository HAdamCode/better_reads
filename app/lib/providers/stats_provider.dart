import 'package:flutter/material.dart';
import '../models/user_book.dart';
import '../services/graphql_service.dart';
import 'books_provider.dart';

/// Reading goal for a specific year
class ReadingGoal {
  final int year;
  final int? bookGoal;
  final int? pageGoal;

  ReadingGoal({required this.year, this.bookGoal, this.pageGoal});

  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      year: json['year'] as int,
      bookGoal: json['bookGoal'] as int?,
      pageGoal: json['pageGoal'] as int?,
    );
  }
}

/// Reading personality based on reading habits
class ReadingPersonality {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;

  ReadingPersonality({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

/// Achievement category for grouping
enum AchievementCategory {
  bookCount('📚', 'Book Collector', 'Milestones for books read'),
  pageCount('📄', 'Page Turner', 'Milestones for pages read'),
  ratings('⭐', 'Critic\'s Corner', 'Rating achievements'),
  speed('⚡', 'Speed Reader', 'Reading pace achievements'),
  bookLength('📏', 'Size Matters', 'Book length achievements'),
  authors('✍️', 'Author Love', 'Author loyalty achievements'),
  genres('🌍', 'Explorer', 'Genre diversity achievements'),
  rereads('🔄', 'Comfort Zone', 'Re-reading achievements'),
  yearly('📅', 'Annual Goals', 'Yearly reading achievements'),
  special('🎭', 'Special', 'Unique achievements');

  final String icon;
  final String title;
  final String subtitle;

  const AchievementCategory(this.icon, this.title, this.subtitle);
}

/// Achievement/badge for reading milestones
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime? unlockedAt;
  final double? progress; // 0-1 for locked achievements
  final bool? _isUnlocked; // Explicit unlock status
  final AchievementCategory category;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
    this.progress,
    bool? isUnlocked,
    this.category = AchievementCategory.special,
  }) : _isUnlocked = isUnlocked;

  bool get isUnlocked => _isUnlocked ?? unlockedAt != null || progress == null;
}

class StatsProvider extends ChangeNotifier {
  final BooksProvider _booksProvider;
  final GraphQLService _graphQLService = GraphQLService();
  int? _selectedYear; // null = All Time
  Map<int, ReadingGoal> _goals = {};
  bool _goalsLoaded = false;

  StatsProvider(this._booksProvider) {
    _booksProvider.addListener(_onBooksChanged);
    _loadGoals();
  }

  void _onBooksChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _booksProvider.removeListener(_onBooksChanged);
    super.dispose();
  }

  // ============ Reading Goals ============

  Future<void> _loadGoals() async {
    if (_goalsLoaded) return;
    try {
      final goalsData = await _graphQLService.fetchReadingGoals();
      _goals = {};
      for (final data in goalsData) {
        final goal = ReadingGoal.fromJson(data);
        _goals[goal.year] = goal;
      }
      _goalsLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load reading goals: $e');
    }
  }

  Future<void> refreshGoals() async {
    _goalsLoaded = false;
    await _loadGoals();
  }

  ReadingGoal? getGoalForYear(int year) => _goals[year];

  /// Get the current year's goal (or create a default)
  ReadingGoal? get currentYearGoal {
    final year = _selectedYear ?? DateTime.now().year;
    return _goals[year];
  }

  /// Book goal progress (0.0 to 1.0)
  double get bookGoalProgress {
    final goal = currentYearGoal;
    if (goal == null || goal.bookGoal == null || goal.bookGoal == 0) return 0;
    return (booksRead / goal.bookGoal!).clamp(0.0, 1.0);
  }

  /// Page goal progress (0.0 to 1.0)
  double get pageGoalProgress {
    final goal = currentYearGoal;
    if (goal == null || goal.pageGoal == null || goal.pageGoal == 0) return 0;
    return (pagesRead / goal.pageGoal!).clamp(0.0, 1.0);
  }

  /// Set a reading goal for a year
  Future<void> setGoal({
    required int year,
    int? bookGoal,
    int? pageGoal,
  }) async {
    try {
      await _graphQLService.setReadingGoal(
        year: year,
        bookGoal: bookGoal,
        pageGoal: pageGoal,
      );
      _goals[year] = ReadingGoal(
        year: year,
        bookGoal: bookGoal,
        pageGoal: pageGoal,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set reading goal: $e');
      rethrow;
    }
  }

  // Year selection
  int? get selectedYear => _selectedYear;

  void setYear(int? year) {
    _selectedYear = year;
    notifyListeners();
  }

  String get selectedYearLabel => _selectedYear?.toString() ?? 'All Time';

  /// Get list of years that have finished books
  List<int> get availableYears {
    final years = <int>{};
    for (final book in _booksProvider.readBooks) {
      if (book.finishedAt != null) {
        years.add(book.finishedAt!.year);
      }
    }
    final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
    return sortedYears;
  }

  /// Filter books by selected year
  List<UserBook> get _filteredBooks {
    final books = _booksProvider.readBooks;
    if (_selectedYear == null) return books;
    return books.where((b) => b.finishedAt?.year == _selectedYear).toList();
  }

  // ============ Overview Stats ============

  int get booksRead => _filteredBooks.length;

  int get pagesRead {
    int total = 0;
    for (final book in _filteredBooks) {
      total += book.effectivePageCount ?? 0;
    }
    return total;
  }

  int get avgBookLength {
    if (booksRead == 0) return 0;
    return (pagesRead / booksRead).round();
  }

  double get avgRating {
    final ratedBooks = _filteredBooks.where((b) => b.rating != null).toList();
    if (ratedBooks.isEmpty) return 0;
    final sum = ratedBooks.fold<int>(0, (sum, b) => sum + b.rating!);
    return sum / ratedBooks.length;
  }

  // ============ Speed Stats ============

  UserBook? get fastestRead {
    final booksWithDuration = _filteredBooks
        .where((b) => b.startedAt != null && b.finishedAt != null)
        .toList();
    if (booksWithDuration.isEmpty) return null;

    booksWithDuration.sort((a, b) {
      final durationA = a.finishedAt!.difference(a.startedAt!);
      final durationB = b.finishedAt!.difference(b.startedAt!);
      return durationA.compareTo(durationB);
    });

    return booksWithDuration.first;
  }

  UserBook? get slowestRead {
    final booksWithDuration = _filteredBooks
        .where((b) => b.startedAt != null && b.finishedAt != null)
        .toList();
    if (booksWithDuration.isEmpty) return null;

    booksWithDuration.sort((a, b) {
      final durationA = a.finishedAt!.difference(a.startedAt!);
      final durationB = b.finishedAt!.difference(b.startedAt!);
      return durationB.compareTo(durationA);
    });

    return booksWithDuration.first;
  }

  UserBook? get shortestBook {
    final booksWithPages = _filteredBooks
        .where((b) => b.effectivePageCount != null && b.effectivePageCount! > 0)
        .toList();
    if (booksWithPages.isEmpty) return null;

    booksWithPages.sort(
      (a, b) => a.effectivePageCount!.compareTo(b.effectivePageCount!),
    );

    return booksWithPages.first;
  }

  UserBook? get longestBook {
    final booksWithPages = _filteredBooks
        .where((b) => b.effectivePageCount != null && b.effectivePageCount! > 0)
        .toList();
    if (booksWithPages.isEmpty) return null;

    booksWithPages.sort(
      (a, b) => b.effectivePageCount!.compareTo(a.effectivePageCount!),
    );

    return booksWithPages.first;
  }

  // ============ Top Books (for gallery) ============

  /// Books sorted by user rating, then by external rating
  List<UserBook> get topRatedBooks {
    final books = List<UserBook>.from(_filteredBooks);
    books.sort((a, b) {
      // First by user rating (higher first)
      final ratingA = a.rating ?? 0;
      final ratingB = b.rating ?? 0;
      if (ratingA != ratingB) return ratingB.compareTo(ratingA);
      // Then by external rating
      final extA = a.book?.averageRating ?? 0;
      final extB = b.book?.averageRating ?? 0;
      return extB.compareTo(extA);
    });
    return books;
  }

  /// Books with 5-star user rating
  List<UserBook> get userHighestRated =>
      _filteredBooks.where((b) => b.rating == 5).toList();

  /// Book with highest external (Goodreads/OpenLibrary) rating
  UserBook? get bestExternalRating {
    final booksWithRating = _filteredBooks
        .where(
          (b) => b.book?.averageRating != null && b.book!.averageRating! > 0,
        )
        .toList();
    if (booksWithRating.isEmpty) return null;

    booksWithRating.sort(
      (a, b) => b.book!.averageRating!.compareTo(a.book!.averageRating!),
    );

    return booksWithRating.first;
  }

  /// Rating distribution (1-5 stars)
  Map<int, int> get ratingDistribution {
    final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final book in _filteredBooks) {
      if (book.rating != null && book.rating! >= 1 && book.rating! <= 5) {
        dist[book.rating!] = dist[book.rating!]! + 1;
      }
    }
    return dist;
  }

  // ============ Genre Stats ============

  /// Top genres by book count
  Map<String, int> get genreBreakdown {
    final genres = <String, int>{};

    for (final book in _filteredBooks) {
      if (book.book?.subjects != null) {
        for (final subject in book.book!.subjects!) {
          // Normalize the subject
          final normalized = _normalizeGenre(subject);
          if (normalized.isNotEmpty) {
            genres[normalized] = (genres[normalized] ?? 0) + 1;
          }
        }
      }
    }

    // Sort by count descending
    final sorted = genres.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return top 10
    return Map.fromEntries(sorted.take(10));
  }

  String _normalizeGenre(String subject) {
    // Simple normalization - capitalize first letter
    final clean = subject.trim().toLowerCase();
    if (clean.isEmpty) return '';

    // Skip overly specific subjects
    if (clean.contains('fiction') && clean.length > 20) {
      return 'Fiction';
    }

    // Common genre mappings
    if (clean.contains('science fiction') || clean.contains('sci-fi')) {
      return 'Science Fiction';
    }
    if (clean.contains('fantasy')) return 'Fantasy';
    if (clean.contains('mystery')) return 'Mystery';
    if (clean.contains('romance')) return 'Romance';
    if (clean.contains('thriller')) return 'Thriller';
    if (clean.contains('horror')) return 'Horror';
    if (clean.contains('biography') || clean.contains('memoir')) {
      return 'Biography';
    }
    if (clean.contains('history')) return 'History';
    if (clean.contains('self-help') || clean.contains('self help')) {
      return 'Self-Help';
    }
    if (clean.contains('business')) return 'Business';

    // Capitalize first letter of each word
    return clean
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  // ============ Author Stats ============

  /// Top authors by book count
  Map<String, int> get authorBreakdown {
    final authors = <String, int>{};

    for (final book in _filteredBooks) {
      if (book.book?.authors != null) {
        for (final author in book.book!.authors) {
          final name = author.trim();
          if (name.isNotEmpty) {
            authors[name] = (authors[name] ?? 0) + 1;
          }
        }
      }
    }

    // Sort by count descending
    final sorted = authors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return top 10
    return Map.fromEntries(sorted.take(10));
  }

  // ============ Re-read Stats ============

  int get totalRereadCount {
    int count = 0;
    for (final book in _filteredBooks) {
      final readCount = _booksProvider.getReadCount(book.bookId);
      if (readCount > 1) {
        count += readCount - 1; // Count extra reads
      }
    }
    return count;
  }

  UserBook? get mostRereadBook {
    UserBook? most;
    int maxCount = 0;

    for (final book in _filteredBooks) {
      final readCount = _booksProvider.getReadCount(book.bookId);
      if (readCount > maxCount) {
        maxCount = readCount;
        most = book;
      }
    }

    return maxCount > 1 ? most : null;
  }

  int getMostRereadCount() {
    int maxCount = 0;
    for (final book in _filteredBooks) {
      final readCount = _booksProvider.getReadCount(book.bookId);
      if (readCount > maxCount) {
        maxCount = readCount;
      }
    }
    return maxCount;
  }

  // ============ Helper Methods ============

  /// Get reading activity by date (for heatmap)
  /// Tracks all book interactions: added, started, updated progress, finished
  Map<DateTime, int> get readingActivityByDay {
    final activity = <DateTime, int>{};

    void addActivity(DateTime? dateTime) {
      if (dateTime == null) return;
      final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
      activity[date] = (activity[date] ?? 0) + 1;
    }

    // Include all books for comprehensive activity tracking
    for (final book in _booksProvider.userBooks.values) {
      // When book was added to library
      addActivity(book.addedAt);

      // When reading started
      addActivity(book.startedAt);

      // When book was finished
      addActivity(book.finishedAt);

      // When book was last updated (progress updates, ratings, etc.)
      // Only count if different from other dates to avoid duplicates
      final updateDate = DateTime(
        book.updatedAt.year,
        book.updatedAt.month,
        book.updatedAt.day,
      );
      final addedDate = DateTime(
        book.addedAt.year,
        book.addedAt.month,
        book.addedAt.day,
      );
      final startedDate = book.startedAt != null
          ? DateTime(
              book.startedAt!.year,
              book.startedAt!.month,
              book.startedAt!.day,
            )
          : null;
      final finishedDate = book.finishedAt != null
          ? DateTime(
              book.finishedAt!.year,
              book.finishedAt!.month,
              book.finishedAt!.day,
            )
          : null;

      if (updateDate != addedDate &&
          updateDate != startedDate &&
          updateDate != finishedDate) {
        addActivity(book.updatedAt);
      }
    }

    return activity;
  }

  /// Get detailed activity log with descriptions
  List<Map<String, dynamic>> get recentActivityLog {
    final activities = <Map<String, dynamic>>[];

    for (final book in _booksProvider.userBooks.values) {
      if (book.book == null) continue;

      if (book.finishedAt != null) {
        activities.add({
          'date': book.finishedAt!,
          'type': 'finished',
          'icon': '✅',
          'title': 'Finished reading',
          'book': book,
        });
      }

      if (book.startedAt != null && book.startedAt != book.finishedAt) {
        activities.add({
          'date': book.startedAt!,
          'type': 'started',
          'icon': '📖',
          'title': 'Started reading',
          'book': book,
        });
      }

      // Track progress updates (when updatedAt differs from other dates)
      if (book.readingStatus == ReadingStatus.currentlyReading &&
          book.pagesRead != null &&
          book.pagesRead! > 0) {
        activities.add({
          'date': book.updatedAt,
          'type': 'progress',
          'icon': '📚',
          'title': 'Updated progress',
          'subtitle': '${book.pagesRead} pages',
          'book': book,
        });
      }

      if (book.rating != null && book.readingStatus == ReadingStatus.read) {
        activities.add({
          'date': book.updatedAt,
          'type': 'rated',
          'icon': '⭐',
          'title': 'Rated ${book.rating}/5',
          'book': book,
        });
      }

      // Book added to library
      activities.add({
        'date': book.addedAt,
        'type': 'added',
        'icon': '➕',
        'title': 'Added to library',
        'book': book,
      });
    }

    // Sort by date, newest first
    activities.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    return activities.take(50).toList();
  }

  /// Get books finished in a specific month
  List<UserBook> getBooksForMonth(int year, int month) {
    return _booksProvider.readBooks.where((b) {
      if (b.finishedAt == null) return false;
      return b.finishedAt!.year == year && b.finishedAt!.month == month;
    }).toList();
  }

  /// Get monthly reading counts for the selected year
  Map<int, int> get monthlyBreakdown {
    final year = _selectedYear ?? DateTime.now().year;
    final counts = <int, int>{};
    for (int month = 1; month <= 12; month++) {
      counts[month] = getBooksForMonth(year, month).length;
    }
    return counts;
  }

  /// Get reading milestones (significant events) sorted by date
  List<Map<String, dynamic>> get readingMilestones {
    final milestones = <Map<String, dynamic>>[];
    final allBooks = _booksProvider.readBooks.toList()
      ..sort(
        (a, b) => (a.finishedAt ?? DateTime.now()).compareTo(
          b.finishedAt ?? DateTime.now(),
        ),
      );

    int bookCount = 0;
    int pageCount = 0;

    for (final book in allBooks) {
      if (book.finishedAt == null) continue;
      bookCount++;
      pageCount += book.effectivePageCount ?? 0;

      // Book milestones
      if (bookCount == 1) {
        milestones.add({
          'date': book.finishedAt,
          'type': 'book',
          'title': 'First Book!',
          'subtitle': book.book?.title ?? 'Unknown',
          'icon': '🎉',
        });
      } else if (bookCount == 10 ||
          bookCount == 25 ||
          bookCount == 50 ||
          bookCount == 100) {
        milestones.add({
          'date': book.finishedAt,
          'type': 'book',
          'title': '$bookCount Books Read!',
          'subtitle': book.book?.title ?? 'Unknown',
          'icon': '📚',
        });
      }

      // Page milestones
      if (pageCount >= 1000 &&
          pageCount - (book.effectivePageCount ?? 0) < 1000) {
        milestones.add({
          'date': book.finishedAt,
          'type': 'pages',
          'title': '1,000 Pages!',
          'subtitle': 'Page milestone reached',
          'icon': '📄',
        });
      } else if (pageCount >= 10000 &&
          pageCount - (book.effectivePageCount ?? 0) < 10000) {
        milestones.add({
          'date': book.finishedAt,
          'type': 'pages',
          'title': '10,000 Pages!',
          'subtitle': 'Page milestone reached',
          'icon': '⚡',
        });
      } else if (pageCount >= 50000 &&
          pageCount - (book.effectivePageCount ?? 0) < 50000) {
        milestones.add({
          'date': book.finishedAt,
          'type': 'pages',
          'title': '50,000 Pages!',
          'subtitle': 'Page milestone reached',
          'icon': '🏃',
        });
      }

      // 5-star book
      if (book.rating == 5) {
        milestones.add({
          'date': book.finishedAt,
          'type': 'rating',
          'title': '5-Star Read',
          'subtitle': book.book?.title ?? 'Unknown',
          'icon': '⭐',
        });
      }

      // Longest book
      if ((book.effectivePageCount ?? 0) >= 500) {
        milestones.add({
          'date': book.finishedAt,
          'type': 'length',
          'title': 'Epic Read Complete',
          'subtitle': '${book.effectivePageCount} pages',
          'icon': '📕',
        });
      }
    }

    return milestones;
  }

  /// Fun facts calculations
  Map<String, dynamic> get funFacts {
    final books = _filteredBooks;
    final pages = pagesRead;

    // Average page thickness is about 0.1mm, so pages / 10 = cm
    final stackHeightCm = pages * 0.01; // 0.1mm per page
    final stackHeightFeet = stackHeightCm / 30.48;

    // Average words per page is about 250
    final wordsRead = pages * 250;

    // Harry Potter series is about 4,224 pages
    final harryPotters = pages / 4224;

    // Average reading speed is 250 words per minute
    final hoursReading = wordsRead / 250 / 60;

    // Lord of the Rings is about 1,178 pages
    final lotrCount = pages / 1178;

    // Bible is about 1,200 pages
    final bibles = pages / 1200;

    // War and Peace is about 1,225 pages
    final warAndPeace = pages / 1225;

    return {
      'stackHeightFeet': stackHeightFeet,
      'stackHeightMeters': stackHeightCm / 100,
      'wordsRead': wordsRead,
      'harryPotters': harryPotters,
      'hoursReading': hoursReading,
      'lotrCount': lotrCount,
      'bibles': bibles,
      'warAndPeace': warAndPeace,
      'booksCount': books.length,
      'pagesCount': pages,
    };
  }

  /// Get reading duration as human-readable string
  String getReadingDuration(UserBook book) {
    if (book.startedAt == null || book.finishedAt == null) return 'Unknown';

    final duration = book.finishedAt!.difference(book.startedAt!);
    final days = duration.inDays;

    if (days == 0) return 'Same day';
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    if (days < 14) return '1 week';
    if (days < 30) return '${(days / 7).round()} weeks';
    if (days < 60) return '1 month';
    if (days < 365) return '${(days / 30).round()} months';
    return '${(days / 365).round()} years';
  }

  /// Calculate scale factor for book cover based on rating
  double getBookScale(UserBook book) {
    final rating = book.rating ?? 3;
    switch (rating) {
      case 5:
        return 1.3;
      case 4:
        return 1.15;
      case 3:
        return 1.0;
      case 2:
        return 0.9;
      case 1:
        return 0.8;
      default:
        return 1.0;
    }
  }

  // ============ Reading Personality ============

  /// Get a fun reading personality based on reading habits
  ReadingPersonality get readingPersonality {
    if (_filteredBooks.isEmpty) {
      return ReadingPersonality(
        title: 'Aspiring Reader',
        subtitle: 'Your reading journey awaits!',
        icon: '📚',
        color: Colors.grey,
      );
    }

    final genres = genreBreakdown;
    final allGenres = genres.keys.map((g) => g.toLowerCase()).toList();
    final topGenre = genres.isNotEmpty ? genres.keys.first.toLowerCase() : '';
    final bookCount = booksRead;
    final avgPages = avgBookLength;
    final rating = avgRating;
    final rereadCount = totalRereadCount;
    final uniqueGenreCount = genres.length;

    // Check for special behavior-based personalities first

    // Eclectic Reader - reads many different genres
    if (uniqueGenreCount >= 8 && bookCount >= 10) {
      return ReadingPersonality(
        title: 'Eclectic Wanderer',
        subtitle: 'Your taste knows no boundaries',
        icon: '🌈',
        color: Colors.purple,
      );
    }

    // Re-reader personality
    if (rereadCount >= 5) {
      return ReadingPersonality(
        title: 'Nostalgic Soul',
        subtitle: 'Old favorites are the best favorites',
        icon: '🔄',
        color: Colors.amber.shade700,
      );
    }

    // Speed reader - lots of books, short average time
    final fastBooks = _filteredBooks.where((b) {
      if (b.startedAt == null || b.finishedAt == null) return false;
      return b.finishedAt!.difference(b.startedAt!).inDays <= 2;
    }).length;
    if (fastBooks >= 5 && bookCount >= 10) {
      return ReadingPersonality(
        title: 'Speed Demon',
        subtitle: 'You devour books like snacks',
        icon: '⚡',
        color: Colors.orange,
      );
    }

    // Tome Conqueror - loves long books
    final longBooks = _filteredBooks
        .where((b) => (b.effectivePageCount ?? 0) >= 500)
        .length;
    if (longBooks >= 3) {
      return ReadingPersonality(
        title: 'Tome Conqueror',
        subtitle: 'The longer the better',
        icon: '🏔️',
        color: Colors.indigo.shade700,
      );
    }

    // Genre-based personalities
    if (topGenre.contains('fantasy')) {
      if (avgPages > 400) {
        return ReadingPersonality(
          title: 'Epic Voyager',
          subtitle: 'You love getting lost in vast worlds',
          icon: '🚀',
          color: Colors.deepPurple,
        );
      }
      return ReadingPersonality(
        title: 'Realm Walker',
        subtitle: 'Magic flows through your bookshelf',
        icon: '🧙',
        color: Colors.purple,
      );
    }

    if (topGenre.contains('science fiction') || topGenre.contains('sci-fi')) {
      return ReadingPersonality(
        title: 'Starship Captain',
        subtitle: 'The future is your favorite destination',
        icon: '🛸',
        color: Colors.cyan.shade700,
      );
    }

    if (topGenre.contains('mystery')) {
      return ReadingPersonality(
        title: 'Master Detective',
        subtitle: 'You can\'t resist a good puzzle',
        icon: '🔍',
        color: Colors.blueGrey,
      );
    }

    if (topGenre.contains('thriller') || topGenre.contains('suspense')) {
      return ReadingPersonality(
        title: 'Edge Seeker',
        subtitle: 'You live for the plot twists',
        icon: '🎭',
        color: Colors.red.shade700,
      );
    }

    if (topGenre.contains('romance')) {
      if (allGenres.any((g) => g.contains('historical'))) {
        return ReadingPersonality(
          title: 'Period Drama Devotee',
          subtitle: 'Corsets and courtship, yes please',
          icon: '👗',
          color: Colors.pink.shade300,
        );
      }
      return ReadingPersonality(
        title: 'Hopeless Romantic',
        subtitle: 'Love stories make your heart sing',
        icon: '💕',
        color: Colors.pink,
      );
    }

    if (topGenre.contains('horror')) {
      return ReadingPersonality(
        title: 'Nightmare Collector',
        subtitle: 'Fear is just another feeling to explore',
        icon: '🌙',
        color: Colors.grey.shade800,
      );
    }

    if (topGenre.contains('biography') || topGenre.contains('memoir')) {
      return ReadingPersonality(
        title: 'Life Story Lover',
        subtitle: 'Real people, extraordinary tales',
        icon: '🎬',
        color: Colors.brown.shade600,
      );
    }

    if (topGenre.contains('history')) {
      return ReadingPersonality(
        title: 'Time Traveler',
        subtitle: 'The past has so much to teach',
        icon: '🏛️',
        color: Colors.brown,
      );
    }

    if (topGenre.contains('self-help') ||
        topGenre.contains('personal development')) {
      return ReadingPersonality(
        title: 'Growth Seeker',
        subtitle: 'Always leveling up your potential',
        icon: '🎯',
        color: Colors.teal,
      );
    }

    if (topGenre.contains('business') || topGenre.contains('economics')) {
      return ReadingPersonality(
        title: 'Mogul in Training',
        subtitle: 'Success leaves clues in books',
        icon: '💼',
        color: Colors.blueGrey.shade700,
      );
    }

    if (topGenre.contains('philosophy')) {
      return ReadingPersonality(
        title: 'Deep Thinker',
        subtitle: 'You ponder the big questions',
        icon: '🤔',
        color: Colors.deepPurple.shade300,
      );
    }

    if (topGenre.contains('poetry') || topGenre.contains('poems')) {
      return ReadingPersonality(
        title: 'Verse Virtuoso',
        subtitle: 'Words are your music',
        icon: '🪶',
        color: Colors.pink.shade200,
      );
    }

    if (topGenre.contains('comic') ||
        topGenre.contains('graphic novel') ||
        topGenre.contains('manga')) {
      return ReadingPersonality(
        title: 'Panel Prowler',
        subtitle: 'Art and story, perfectly combined',
        icon: '💥',
        color: Colors.red,
      );
    }

    if (topGenre.contains('young adult') || topGenre.contains('ya')) {
      return ReadingPersonality(
        title: 'Forever Young',
        subtitle: 'Coming-of-age never gets old',
        icon: '🌟',
        color: Colors.lightBlue,
      );
    }

    if (topGenre.contains('classic') || topGenre.contains('literary fiction')) {
      return ReadingPersonality(
        title: 'Literary Connoisseur',
        subtitle: 'Timeless prose is your thing',
        icon: '🎩',
        color: Colors.brown.shade800,
      );
    }

    if (topGenre.contains('true crime')) {
      return ReadingPersonality(
        title: 'Case File Junkie',
        subtitle: 'Real mysteries are the most gripping',
        icon: '🔦',
        color: Colors.grey.shade700,
      );
    }

    if (topGenre.contains('science') ||
        topGenre.contains('technology') ||
        topGenre.contains('nature')) {
      return ReadingPersonality(
        title: 'Knowledge Hunter',
        subtitle: 'Facts fuel your curiosity',
        icon: '🔬',
        color: Colors.green.shade700,
      );
    }

    if (topGenre.contains('travel') || topGenre.contains('adventure')) {
      return ReadingPersonality(
        title: 'Armchair Explorer',
        subtitle: 'The world is your reading list',
        icon: '🗺️',
        color: Colors.teal.shade600,
      );
    }

    if (topGenre.contains('cooking') ||
        topGenre.contains('food') ||
        topGenre.contains('cookbook')) {
      return ReadingPersonality(
        title: 'Recipe Collector',
        subtitle: 'Reading makes you hungry',
        icon: '👨‍🍳',
        color: Colors.orange.shade600,
      );
    }

    if (topGenre.contains('art') ||
        topGenre.contains('photography') ||
        topGenre.contains('design')) {
      return ReadingPersonality(
        title: 'Visual Dreamer',
        subtitle: 'Beauty inspires your reading',
        icon: '🎨',
        color: Colors.pink.shade400,
      );
    }

    if (topGenre.contains('religion') || topGenre.contains('spirituality')) {
      return ReadingPersonality(
        title: 'Soul Searcher',
        subtitle: 'Finding meaning through pages',
        icon: '🕊️',
        color: Colors.blue.shade300,
      );
    }

    if (topGenre.contains('humor') || topGenre.contains('comedy')) {
      return ReadingPersonality(
        title: 'Laughter Seeker',
        subtitle: 'Life\'s too short for serious books',
        icon: '😂',
        color: Colors.yellow.shade700,
      );
    }

    if (topGenre.contains('children') || topGenre.contains('picture book')) {
      return ReadingPersonality(
        title: 'Imagination Keeper',
        subtitle: 'The best stories start young',
        icon: '🧸',
        color: Colors.lightGreen,
      );
    }

    if (topGenre.contains('short stor')) {
      return ReadingPersonality(
        title: 'Bite-Size Believer',
        subtitle: 'Great things come in small packages',
        icon: '📝',
        color: Colors.cyan,
      );
    }

    // Default based on reading volume and behavior
    if (bookCount >= 100) {
      return ReadingPersonality(
        title: 'Library Legend',
        subtitle: 'You ARE a library',
        icon: '🏆',
        color: Colors.amber.shade800,
      );
    }
    if (bookCount >= 50) {
      return ReadingPersonality(
        title: 'Legendary Bibliophile',
        subtitle: 'Books are your superpower',
        icon: '👑',
        color: Colors.amber,
      );
    }
    if (bookCount >= 25) {
      return ReadingPersonality(
        title: 'Devoted Bookworm',
        subtitle: 'Reading is your happy place',
        icon: '🐛',
        color: Colors.green,
      );
    }
    if (bookCount >= 10) {
      return ReadingPersonality(
        title: 'Avid Reader',
        subtitle: 'Building an impressive library',
        icon: '📖',
        color: Colors.blue,
      );
    }
    if (rating >= 4.5) {
      return ReadingPersonality(
        title: 'Discerning Critic',
        subtitle: 'You know quality when you read it',
        icon: '⭐',
        color: Colors.orange,
      );
    }
    if (rating <= 2.5 && bookCount >= 5) {
      return ReadingPersonality(
        title: 'Tough Critic',
        subtitle: 'High standards, few stars',
        icon: '🧐',
        color: Colors.grey.shade600,
      );
    }
    if (avgPages < 200 && bookCount >= 5) {
      return ReadingPersonality(
        title: 'Quick Read Fan',
        subtitle: 'Short and sweet is your style',
        icon: '📱',
        color: Colors.lightBlue.shade400,
      );
    }

    return ReadingPersonality(
      title: 'Curious Reader',
      subtitle: 'Every book is a new adventure',
      icon: '🌟',
      color: Colors.cyan,
    );
  }

  // ============ Achievements ============

  /// Get list of unlocked achievements
  List<Achievement> get unlockedAchievements {
    final achievements = <Achievement>[];
    final allTimeBooks = _booksProvider.readBooks;

    // ========== BOOK COUNT MILESTONES ==========
    if (allTimeBooks.isNotEmpty) {
      achievements.add(
        Achievement(
          id: 'first_book',
          title: 'First Chapter',
          description: 'Finished your first book',
          icon: '🎉',
          unlockedAt: allTimeBooks.last.finishedAt,
        ),
      );
    }
    if (allTimeBooks.length >= 5) {
      achievements.add(
        Achievement(
          id: 'getting_started',
          title: 'Getting Started',
          description: 'Read 5 books',
          icon: '🌱',
        ),
      );
    }
    if (allTimeBooks.length >= 10) {
      achievements.add(
        Achievement(
          id: 'bookworm',
          title: 'Bookworm',
          description: 'Read 10 books',
          icon: '🐛',
        ),
      );
    }
    if (allTimeBooks.length >= 25) {
      achievements.add(
        Achievement(
          id: 'bibliophile',
          title: 'Bibliophile',
          description: 'Read 25 books',
          icon: '📚',
        ),
      );
    }
    if (allTimeBooks.length >= 50) {
      achievements.add(
        Achievement(
          id: 'library_legend',
          title: 'Library Legend',
          description: 'Read 50 books',
          icon: '🏆',
        ),
      );
    }
    if (allTimeBooks.length >= 100) {
      achievements.add(
        Achievement(
          id: 'century_club',
          title: 'Century Club',
          description: 'Read 100 books',
          icon: '💯',
        ),
      );
    }
    if (allTimeBooks.length >= 200) {
      achievements.add(
        Achievement(
          id: 'double_century',
          title: 'Double Century',
          description: 'Read 200 books',
          icon: '🎖️',
        ),
      );
    }
    if (allTimeBooks.length >= 500) {
      achievements.add(
        Achievement(
          id: 'book_dragon',
          title: 'Book Dragon',
          description: 'Read 500 books - you hoard books!',
          icon: '🐉',
        ),
      );
    }

    // ========== PAGE COUNT MILESTONES ==========
    final totalPages = allTimeBooks.fold<int>(
      0,
      (sum, b) => sum + (b.effectivePageCount ?? 0),
    );
    if (totalPages >= 1000) {
      achievements.add(
        Achievement(
          id: 'thousand_pages',
          title: 'Page Turner',
          description: 'Read 1,000 pages',
          icon: '📄',
        ),
      );
    }
    if (totalPages >= 5000) {
      achievements.add(
        Achievement(
          id: 'five_thousand_pages',
          title: 'Page Enthusiast',
          description: 'Read 5,000 pages',
          icon: '📑',
        ),
      );
    }
    if (totalPages >= 10000) {
      achievements.add(
        Achievement(
          id: 'ten_thousand_pages',
          title: 'Speed Reader',
          description: 'Read 10,000 pages',
          icon: '⚡',
        ),
      );
    }
    if (totalPages >= 25000) {
      achievements.add(
        Achievement(
          id: 'twentyfive_thousand_pages',
          title: 'Page Devourer',
          description: 'Read 25,000 pages',
          icon: '🔥',
        ),
      );
    }
    if (totalPages >= 50000) {
      achievements.add(
        Achievement(
          id: 'fifty_thousand_pages',
          title: 'Marathon Reader',
          description: 'Read 50,000 pages',
          icon: '🏃',
        ),
      );
    }
    if (totalPages >= 100000) {
      achievements.add(
        Achievement(
          id: 'hundred_thousand_pages',
          title: 'Reading Machine',
          description: 'Read 100,000 pages',
          icon: '🤖',
        ),
      );
    }

    // ========== RATING ACHIEVEMENTS ==========
    final ratedBooks = allTimeBooks.where((b) => b.rating != null).toList();
    final fiveStarBooks = allTimeBooks.where((b) => b.rating == 5).length;
    final oneStarBooks = allTimeBooks.where((b) => b.rating == 1).length;

    if (ratedBooks.isNotEmpty) {
      achievements.add(
        Achievement(
          id: 'first_rating',
          title: 'Opinion Haver',
          description: 'Rated your first book',
          icon: '💭',
        ),
      );
    }
    if (ratedBooks.length >= 10) {
      achievements.add(
        Achievement(
          id: 'rating_rookie',
          title: 'Rating Rookie',
          description: 'Rated 10 books',
          icon: '📝',
        ),
      );
    }
    if (ratedBooks.length >= 25) {
      achievements.add(
        Achievement(
          id: 'rating_regular',
          title: 'Rating Regular',
          description: 'Rated 25 books',
          icon: '✍️',
        ),
      );
    }
    if (ratedBooks.length >= 50) {
      achievements.add(
        Achievement(
          id: 'rating_expert',
          title: 'Rating Expert',
          description: 'Rated 50 books',
          icon: '🎯',
        ),
      );
    }
    if (fiveStarBooks >= 1) {
      achievements.add(
        Achievement(
          id: 'first_favorite',
          title: 'First Favorite',
          description: 'Gave your first 5-star rating',
          icon: '💫',
        ),
      );
    }
    if (fiveStarBooks >= 5) {
      achievements.add(
        Achievement(
          id: 'five_star_collector',
          title: 'Five Star Collector',
          description: 'Gave 5 stars to 5 books',
          icon: '⭐',
        ),
      );
    }
    if (fiveStarBooks >= 10) {
      achievements.add(
        Achievement(
          id: 'star_shower',
          title: 'Star Shower',
          description: 'Gave 5 stars to 10 books',
          icon: '🌟',
        ),
      );
    }
    if (fiveStarBooks >= 25) {
      achievements.add(
        Achievement(
          id: 'constellation',
          title: 'Constellation',
          description: 'Gave 5 stars to 25 books',
          icon: '✨',
        ),
      );
    }
    if (oneStarBooks >= 1) {
      achievements.add(
        Achievement(
          id: 'not_for_me',
          title: 'Not For Me',
          description: 'Gave your first 1-star rating',
          icon: '👎',
        ),
      );
    }
    if (oneStarBooks >= 5) {
      achievements.add(
        Achievement(
          id: 'harsh_critic',
          title: 'Harsh Critic',
          description: 'Gave 1 star to 5 books',
          icon: '🧊',
        ),
      );
    }

    // All ratings used
    final usedRatings = <int>{};
    for (final book in ratedBooks) {
      if (book.rating != null) usedRatings.add(book.rating!);
    }
    if (usedRatings.length == 5) {
      achievements.add(
        Achievement(
          id: 'full_spectrum',
          title: 'Full Spectrum',
          description: 'Used all ratings from 1 to 5 stars',
          icon: '🌈',
        ),
      );
    }

    // ========== GENRE ACHIEVEMENTS ==========
    final genreCounts = <String, int>{};
    for (final book in allTimeBooks) {
      if (book.book?.subjects != null) {
        for (final subject in book.book!.subjects!) {
          final normalized = _normalizeGenre(subject);
          if (normalized.isNotEmpty) {
            genreCounts[normalized] = (genreCounts[normalized] ?? 0) + 1;
          }
        }
      }
    }
    final uniqueGenres = genreCounts.keys.toSet();

    if (uniqueGenres.length >= 3) {
      achievements.add(
        Achievement(
          id: 'genre_curious',
          title: 'Genre Curious',
          description: 'Read books from 3+ genres',
          icon: '🔍',
        ),
      );
    }
    if (uniqueGenres.length >= 5) {
      achievements.add(
        Achievement(
          id: 'genre_explorer',
          title: 'Genre Explorer',
          description: 'Read books from 5+ genres',
          icon: '🧭',
        ),
      );
    }
    if (uniqueGenres.length >= 10) {
      achievements.add(
        Achievement(
          id: 'literary_adventurer',
          title: 'Literary Adventurer',
          description: 'Read books from 10+ genres',
          icon: '🗺️',
        ),
      );
    }
    if (uniqueGenres.length >= 15) {
      achievements.add(
        Achievement(
          id: 'genre_master',
          title: 'Genre Master',
          description: 'Read books from 15+ genres',
          icon: '🎓',
        ),
      );
    }
    if (uniqueGenres.length >= 20) {
      achievements.add(
        Achievement(
          id: 'omnireader',
          title: 'Omnireader',
          description: 'Read books from 20+ genres',
          icon: '🌍',
        ),
      );
    }

    // Genre specialist - 10+ books in one genre
    for (final entry in genreCounts.entries) {
      if (entry.value >= 10) {
        achievements.add(
          Achievement(
            id: 'genre_specialist_${entry.key.toLowerCase().replaceAll(' ', '_')}',
            title: '${entry.key} Specialist',
            description: 'Read 10+ ${entry.key} books',
            icon: _getGenreIcon(entry.key),
          ),
        );
        break; // Only show first one
      }
    }

    // Genre devotee - 25+ books in one genre
    for (final entry in genreCounts.entries) {
      if (entry.value >= 25) {
        achievements.add(
          Achievement(
            id: 'genre_devotee_${entry.key.toLowerCase().replaceAll(' ', '_')}',
            title: '${entry.key} Devotee',
            description: 'Read 25+ ${entry.key} books',
            icon: '💜',
          ),
        );
        break;
      }
    }

    // ========== BOOK LENGTH ACHIEVEMENTS ==========
    final hasShortBook = allTimeBooks.any(
      (b) =>
          (b.effectivePageCount ?? 0) > 0 && (b.effectivePageCount ?? 0) <= 100,
    );
    final hasMediumBook = allTimeBooks.any((b) {
      final pages = b.effectivePageCount ?? 0;
      return pages >= 200 && pages <= 300;
    });
    final hasLongBook = allTimeBooks.any(
      (b) => (b.effectivePageCount ?? 0) >= 500,
    );
    final hasEpicBook = allTimeBooks.any(
      (b) => (b.effectivePageCount ?? 0) >= 800,
    );
    final hasMassiveBook = allTimeBooks.any(
      (b) => (b.effectivePageCount ?? 0) >= 1000,
    );

    if (hasShortBook) {
      achievements.add(
        Achievement(
          id: 'short_and_sweet',
          title: 'Short and Sweet',
          description: 'Finished a book under 100 pages',
          icon: '🍬',
        ),
      );
    }
    if (hasMediumBook) {
      achievements.add(
        Achievement(
          id: 'just_right',
          title: 'Just Right',
          description: 'Finished a 200-300 page book',
          icon: '👌',
        ),
      );
    }
    if (hasLongBook) {
      achievements.add(
        Achievement(
          id: 'epic_reader',
          title: 'Epic Reader',
          description: 'Finished a 500+ page book',
          icon: '📕',
        ),
      );
    }
    if (hasEpicBook) {
      achievements.add(
        Achievement(
          id: 'tome_tackler',
          title: 'Tome Tackler',
          description: 'Finished an 800+ page book',
          icon: '💪',
        ),
      );
    }
    if (hasMassiveBook) {
      achievements.add(
        Achievement(
          id: 'absolute_unit',
          title: 'Absolute Unit',
          description: 'Finished a 1000+ page book',
          icon: '🏋️',
        ),
      );
    }

    // Multiple long books
    final longBookCount = allTimeBooks
        .where((b) => (b.effectivePageCount ?? 0) >= 500)
        .length;
    if (longBookCount >= 5) {
      achievements.add(
        Achievement(
          id: 'chonky_collector',
          title: 'Chonky Collector',
          description: 'Finished 5 books over 500 pages',
          icon: '📚',
        ),
      );
    }
    if (longBookCount >= 10) {
      achievements.add(
        Achievement(
          id: 'heavyweight_champ',
          title: 'Heavyweight Champ',
          description: 'Finished 10 books over 500 pages',
          icon: '🥊',
        ),
      );
    }

    // ========== READING SPEED ACHIEVEMENTS ==========
    final hasSameDayRead = allTimeBooks.any((b) {
      if (b.startedAt == null || b.finishedAt == null) return false;
      return b.finishedAt!.difference(b.startedAt!).inDays == 0;
    });
    final hasFastRead = allTimeBooks.any((b) {
      if (b.startedAt == null || b.finishedAt == null) return false;
      final days = b.finishedAt!.difference(b.startedAt!).inDays;
      final pages = b.effectivePageCount ?? 0;
      return days <= 1 && pages >= 200;
    });
    final hasWeekendWarrior = allTimeBooks.any((b) {
      if (b.startedAt == null || b.finishedAt == null) return false;
      final days = b.finishedAt!.difference(b.startedAt!).inDays;
      final pages = b.effectivePageCount ?? 0;
      return days <= 2 && pages >= 300;
    });
    final hasSlowBurn = allTimeBooks.any((b) {
      if (b.startedAt == null || b.finishedAt == null) return false;
      final days = b.finishedAt!.difference(b.startedAt!).inDays;
      return days >= 60;
    });
    final hasYearLongRead = allTimeBooks.any((b) {
      if (b.startedAt == null || b.finishedAt == null) return false;
      final days = b.finishedAt!.difference(b.startedAt!).inDays;
      return days >= 365;
    });

    if (hasSameDayRead) {
      achievements.add(
        Achievement(
          id: 'same_day_finish',
          title: 'One Sitting Wonder',
          description: 'Started and finished a book the same day',
          icon: '⏱️',
        ),
      );
    }
    if (hasFastRead) {
      achievements.add(
        Achievement(
          id: 'speed_demon',
          title: 'Speed Demon',
          description: 'Finished a 200+ page book in a day',
          icon: '💨',
        ),
      );
    }
    if (hasWeekendWarrior) {
      achievements.add(
        Achievement(
          id: 'weekend_warrior',
          title: 'Weekend Warrior',
          description: 'Finished a 300+ page book in 2 days',
          icon: '🗓️',
        ),
      );
    }
    if (hasSlowBurn) {
      achievements.add(
        Achievement(
          id: 'slow_burn',
          title: 'Slow Burn',
          description: 'Took 2+ months to finish a book',
          icon: '🐢',
        ),
      );
    }
    if (hasYearLongRead) {
      achievements.add(
        Achievement(
          id: 'year_long_journey',
          title: 'Year-Long Journey',
          description: 'Took a year+ to finish a book',
          icon: '📅',
        ),
      );
    }

    // Fast reader count
    final fastReadCount = allTimeBooks.where((b) {
      if (b.startedAt == null || b.finishedAt == null) return false;
      return b.finishedAt!.difference(b.startedAt!).inDays <= 1;
    }).length;
    if (fastReadCount >= 5) {
      achievements.add(
        Achievement(
          id: 'quick_reader',
          title: 'Quick Reader',
          description: 'Finished 5 books in a day or less',
          icon: '🏎️',
        ),
      );
    }
    if (fastReadCount >= 10) {
      achievements.add(
        Achievement(
          id: 'lightning_reader',
          title: 'Lightning Reader',
          description: 'Finished 10 books in a day or less',
          icon: '⚡',
        ),
      );
    }

    // ========== AUTHOR ACHIEVEMENTS ==========
    final authorCounts = <String, int>{};
    for (final book in allTimeBooks) {
      if (book.book?.authors != null) {
        for (final author in book.book!.authors) {
          final name = author.trim();
          if (name.isNotEmpty) {
            authorCounts[name] = (authorCounts[name] ?? 0) + 1;
          }
        }
      }
    }
    final uniqueAuthors = authorCounts.keys.length;

    if (uniqueAuthors >= 10) {
      achievements.add(
        Achievement(
          id: 'author_explorer',
          title: 'Author Explorer',
          description: 'Read books by 10+ different authors',
          icon: '🖊️',
        ),
      );
    }
    if (uniqueAuthors >= 25) {
      achievements.add(
        Achievement(
          id: 'author_collector',
          title: 'Author Collector',
          description: 'Read books by 25+ different authors',
          icon: '✒️',
        ),
      );
    }
    if (uniqueAuthors >= 50) {
      achievements.add(
        Achievement(
          id: 'author_connoisseur',
          title: 'Author Connoisseur',
          description: 'Read books by 50+ different authors',
          icon: '🎩',
        ),
      );
    }
    if (uniqueAuthors >= 100) {
      achievements.add(
        Achievement(
          id: 'author_aficionado',
          title: 'Author Aficionado',
          description: 'Read books by 100+ different authors',
          icon: '👑',
        ),
      );
    }

    // Author loyalty - multiple books by same author
    for (final entry in authorCounts.entries) {
      if (entry.value >= 3) {
        achievements.add(
          Achievement(
            id: 'loyal_fan',
            title: 'Loyal Fan',
            description: 'Read 3+ books by ${entry.key}',
            icon: '💝',
          ),
        );
        break;
      }
    }
    for (final entry in authorCounts.entries) {
      if (entry.value >= 5) {
        achievements.add(
          Achievement(
            id: 'super_fan',
            title: 'Super Fan',
            description: 'Read 5+ books by ${entry.key}',
            icon: '🦸',
          ),
        );
        break;
      }
    }
    for (final entry in authorCounts.entries) {
      if (entry.value >= 10) {
        achievements.add(
          Achievement(
            id: 'ultimate_fan',
            title: 'Ultimate Fan',
            description: 'Read 10+ books by ${entry.key}',
            icon: '🏅',
          ),
        );
        break;
      }
    }

    // ========== RE-READ ACHIEVEMENTS ==========
    final rereadCount = totalRereadCount;
    final booksWithRereads = allTimeBooks
        .where((b) => _booksProvider.getReadCount(b.bookId) > 1)
        .length;

    if (rereadCount >= 1) {
      achievements.add(
        Achievement(
          id: 'first_reread',
          title: 'Déjà Vu',
          description: 'Re-read a book for the first time',
          icon: '🔄',
        ),
      );
    }
    if (rereadCount >= 5) {
      achievements.add(
        Achievement(
          id: 'comfort_reader',
          title: 'Comfort Reader',
          description: 'Re-read books 5 times total',
          icon: '🛋️',
        ),
      );
    }
    if (rereadCount >= 10) {
      achievements.add(
        Achievement(
          id: 'nostalgia_lover',
          title: 'Nostalgia Lover',
          description: 'Re-read books 10 times total',
          icon: '💭',
        ),
      );
    }
    if (booksWithRereads >= 5) {
      achievements.add(
        Achievement(
          id: 'many_favorites',
          title: 'Many Favorites',
          description: 'Re-read 5 different books',
          icon: '💕',
        ),
      );
    }

    // Triple read
    final hasTripleRead = allTimeBooks.any(
      (b) => _booksProvider.getReadCount(b.bookId) >= 3,
    );
    if (hasTripleRead) {
      achievements.add(
        Achievement(
          id: 'triple_read',
          title: 'Triple Threat',
          description: 'Read the same book 3+ times',
          icon: '3️⃣',
        ),
      );
    }

    // ========== YEARLY ACHIEVEMENTS ==========
    final booksByYear = <int, int>{};
    for (final book in allTimeBooks) {
      if (book.finishedAt != null) {
        final year = book.finishedAt!.year;
        booksByYear[year] = (booksByYear[year] ?? 0) + 1;
      }
    }

    for (final entry in booksByYear.entries) {
      if (entry.value >= 12) {
        achievements.add(
          Achievement(
            id: 'book_a_month_${entry.key}',
            title: 'Book a Month ${entry.key}',
            description: 'Read 12+ books in ${entry.key}',
            icon: '📆',
          ),
        );
      }
      if (entry.value >= 24) {
        achievements.add(
          Achievement(
            id: 'two_a_month_${entry.key}',
            title: 'Overachiever ${entry.key}',
            description: 'Read 24+ books in ${entry.key}',
            icon: '🚀',
          ),
        );
      }
      if (entry.value >= 52) {
        achievements.add(
          Achievement(
            id: 'book_a_week_${entry.key}',
            title: 'Book a Week ${entry.key}',
            description: 'Read 52+ books in ${entry.key}',
            icon: '🏆',
          ),
        );
      }
      if (entry.value >= 100) {
        achievements.add(
          Achievement(
            id: 'centurion_${entry.key}',
            title: 'Centurion ${entry.key}',
            description: 'Read 100+ books in ${entry.key}',
            icon: '🎖️',
          ),
        );
      }
    }

    // Multi-year reader
    if (booksByYear.length >= 2) {
      achievements.add(
        Achievement(
          id: 'consistent_reader',
          title: 'Consistent Reader',
          description: 'Read books across 2+ years',
          icon: '📈',
        ),
      );
    }
    if (booksByYear.length >= 5) {
      achievements.add(
        Achievement(
          id: 'dedicated_reader',
          title: 'Dedicated Reader',
          description: 'Read books across 5+ years',
          icon: '🎯',
        ),
      );
    }
    if (booksByYear.length >= 10) {
      achievements.add(
        Achievement(
          id: 'decade_reader',
          title: 'Decade of Reading',
          description: 'Read books across 10+ years',
          icon: '🏛️',
        ),
      );
    }

    // ========== SPECIAL/FUN ACHIEVEMENTS ==========

    // Variety pack - different page counts
    final hasUnder150 = allTimeBooks.any(
      (b) =>
          (b.effectivePageCount ?? 0) > 0 && (b.effectivePageCount ?? 0) < 150,
    );
    final has150to300 = allTimeBooks.any((b) {
      final p = b.effectivePageCount ?? 0;
      return p >= 150 && p < 300;
    });
    final has300to500 = allTimeBooks.any((b) {
      final p = b.effectivePageCount ?? 0;
      return p >= 300 && p < 500;
    });
    final hasOver500 = allTimeBooks.any(
      (b) => (b.effectivePageCount ?? 0) >= 500,
    );
    if (hasUnder150 && has150to300 && has300to500 && hasOver500) {
      achievements.add(
        Achievement(
          id: 'variety_pack',
          title: 'Variety Pack',
          description: 'Read books of all sizes',
          icon: '🎁',
        ),
      );
    }

    // Bookworm's dozen
    if (allTimeBooks.length >= 13) {
      achievements.add(
        Achievement(
          id: 'bakers_dozen',
          title: "Bookworm's Dozen",
          description: 'Read 13 books',
          icon: '🥖',
        ),
      );
    }

    // Nice
    if (allTimeBooks.length >= 69) {
      achievements.add(
        Achievement(
          id: 'nice',
          title: 'Nice',
          description: 'Read 69 books',
          icon: '😏',
        ),
      );
    }

    // Perfectly balanced
    final twoStarCount = allTimeBooks.where((b) => b.rating == 2).length;
    final threeStarCount = allTimeBooks.where((b) => b.rating == 3).length;
    final fourStarCount = allTimeBooks.where((b) => b.rating == 4).length;
    if (twoStarCount >= 1 &&
        threeStarCount >= 1 &&
        fourStarCount >= 1 &&
        fiveStarBooks >= 1 &&
        oneStarBooks >= 1 &&
        ratedBooks.length >= 10) {
      final avgRatingValue =
          ratedBooks.fold<int>(0, (s, b) => s + b.rating!) / ratedBooks.length;
      if (avgRatingValue >= 2.9 && avgRatingValue <= 3.1) {
        achievements.add(
          Achievement(
            id: 'perfectly_balanced',
            title: 'Perfectly Balanced',
            description: 'Average rating is exactly 3 stars',
            icon: '⚖️',
          ),
        );
      }
    }

    // The Finisher - finished every book started
    final currentlyReading = _booksProvider.currentlyReadingBooks.length;
    if (allTimeBooks.length >= 10 && currentlyReading == 0) {
      achievements.add(
        Achievement(
          id: 'the_finisher',
          title: 'The Finisher',
          description: 'No books left unfinished!',
          icon: '🏁',
        ),
      );
    }

    return achievements;
  }

  /// Get icon for a genre
  String _getGenreIcon(String genre) {
    final g = genre.toLowerCase();
    if (g.contains('fantasy')) return '🧙';
    if (g.contains('science fiction') || g.contains('sci-fi')) return '🚀';
    if (g.contains('mystery')) return '🔍';
    if (g.contains('thriller')) return '😱';
    if (g.contains('romance')) return '💕';
    if (g.contains('horror')) return '👻';
    if (g.contains('biography') || g.contains('memoir')) return '📝';
    if (g.contains('history')) return '🏛️';
    if (g.contains('self-help')) return '🎯';
    if (g.contains('business')) return '💼';
    if (g.contains('philosophy')) return '🤔';
    if (g.contains('poetry')) return '🪶';
    if (g.contains('comic') || g.contains('manga')) return '💥';
    if (g.contains('young adult')) return '🌟';
    if (g.contains('classic')) return '📜';
    if (g.contains('true crime')) return '🔦';
    if (g.contains('science')) return '🔬';
    if (g.contains('travel')) return '🗺️';
    if (g.contains('cooking') || g.contains('food')) return '👨‍🍳';
    if (g.contains('art')) return '🎨';
    if (g.contains('religion')) return '🕊️';
    if (g.contains('humor')) return '😂';
    if (g.contains('children')) return '🧸';
    return '📖';
  }

  /// Get next achievements to unlock
  List<Achievement> get nextAchievements {
    final next = <Achievement>[];
    final allTimeBooks = _booksProvider.readBooks;
    final totalPages = allTimeBooks.fold<int>(
      0,
      (sum, b) => sum + (b.effectivePageCount ?? 0),
    );
    final ratedBooks = allTimeBooks.where((b) => b.rating != null).length;
    final fiveStarBooks = allTimeBooks.where((b) => b.rating == 5).length;

    // Find next book milestone
    if (allTimeBooks.length < 5) {
      next.add(
        Achievement(
          id: 'getting_started',
          title: 'Getting Started',
          description: 'Read ${5 - allTimeBooks.length} more books',
          icon: '🌱',
          progress: allTimeBooks.length / 5,
        ),
      );
    } else if (allTimeBooks.length < 10) {
      next.add(
        Achievement(
          id: 'bookworm',
          title: 'Bookworm',
          description: 'Read ${10 - allTimeBooks.length} more books',
          icon: '🐛',
          progress: allTimeBooks.length / 10,
        ),
      );
    } else if (allTimeBooks.length < 25) {
      next.add(
        Achievement(
          id: 'bibliophile',
          title: 'Bibliophile',
          description: 'Read ${25 - allTimeBooks.length} more books',
          icon: '📚',
          progress: allTimeBooks.length / 25,
        ),
      );
    } else if (allTimeBooks.length < 50) {
      next.add(
        Achievement(
          id: 'library_legend',
          title: 'Library Legend',
          description: 'Read ${50 - allTimeBooks.length} more books',
          icon: '🏆',
          progress: allTimeBooks.length / 50,
        ),
      );
    } else if (allTimeBooks.length < 100) {
      next.add(
        Achievement(
          id: 'century_club',
          title: 'Century Club',
          description: 'Read ${100 - allTimeBooks.length} more books',
          icon: '💯',
          progress: allTimeBooks.length / 100,
        ),
      );
    }

    // Find next page milestone
    if (totalPages < 5000) {
      next.add(
        Achievement(
          id: 'five_thousand_pages',
          title: 'Page Enthusiast',
          description:
              '${((5000 - totalPages) / 100).ceil() * 100} pages to go',
          icon: '📑',
          progress: totalPages / 5000,
        ),
      );
    } else if (totalPages < 10000) {
      next.add(
        Achievement(
          id: 'ten_thousand_pages',
          title: 'Speed Reader',
          description: '${((10000 - totalPages) / 1000).ceil()}K pages to go',
          icon: '⚡',
          progress: totalPages / 10000,
        ),
      );
    } else if (totalPages < 25000) {
      next.add(
        Achievement(
          id: 'twentyfive_thousand_pages',
          title: 'Page Devourer',
          description: '${((25000 - totalPages) / 1000).ceil()}K pages to go',
          icon: '🔥',
          progress: totalPages / 25000,
        ),
      );
    }

    // Five star collector progress
    if (fiveStarBooks < 5) {
      next.add(
        Achievement(
          id: 'five_star_collector',
          title: 'Five Star Collector',
          description: 'Give ${5 - fiveStarBooks} more 5-star ratings',
          icon: '⭐',
          progress: fiveStarBooks / 5,
        ),
      );
    } else if (fiveStarBooks < 10) {
      next.add(
        Achievement(
          id: 'star_shower',
          title: 'Star Shower',
          description: 'Give ${10 - fiveStarBooks} more 5-star ratings',
          icon: '🌟',
          progress: fiveStarBooks / 10,
        ),
      );
    }

    // Rating rookie
    if (ratedBooks < 10) {
      next.add(
        Achievement(
          id: 'rating_rookie',
          title: 'Rating Rookie',
          description: 'Rate ${10 - ratedBooks} more books',
          icon: '📝',
          progress: ratedBooks / 10,
        ),
      );
    }

    return next.take(3).toList();
  }

  /// Get ALL possible achievements with unlock status, grouped by category
  List<Achievement> get allPossibleAchievements {
    final unlocked = unlockedAchievements.map((a) => a.id).toSet();
    final allTimeBooks = _booksProvider.readBooks;
    final totalPages = allTimeBooks.fold<int>(
      0,
      (sum, b) => sum + (b.effectivePageCount ?? 0),
    );
    final ratedBooks = allTimeBooks.where((b) => b.rating != null).length;
    final fiveStarBooks = allTimeBooks.where((b) => b.rating == 5).length;

    final all = <Achievement>[
      // ========== BOOK COUNT ==========
      Achievement(
        id: 'first_book',
        title: 'First Chapter',
        description: 'Finish your first book',
        icon: '🎉',
        category: AchievementCategory.bookCount,
        isUnlocked: unlocked.contains('first_book'),
        progress: allTimeBooks.isNotEmpty ? 1.0 : 0.0,
      ),
      Achievement(
        id: 'getting_started',
        title: 'Getting Started',
        description: 'Read 5 books',
        icon: '🌱',
        category: AchievementCategory.bookCount,
        isUnlocked: unlocked.contains('getting_started'),
        progress: (allTimeBooks.length / 5).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'bookworm',
        title: 'Bookworm',
        description: 'Read 10 books',
        icon: '🐛',
        category: AchievementCategory.bookCount,
        isUnlocked: unlocked.contains('bookworm'),
        progress: (allTimeBooks.length / 10).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'bibliophile',
        title: 'Bibliophile',
        description: 'Read 25 books',
        icon: '📚',
        category: AchievementCategory.bookCount,
        isUnlocked: unlocked.contains('bibliophile'),
        progress: (allTimeBooks.length / 25).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'library_legend',
        title: 'Library Legend',
        description: 'Read 50 books',
        icon: '🏆',
        category: AchievementCategory.bookCount,
        isUnlocked: unlocked.contains('library_legend'),
        progress: (allTimeBooks.length / 50).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'century_club',
        title: 'Century Club',
        description: 'Read 100 books',
        icon: '💯',
        category: AchievementCategory.bookCount,
        isUnlocked: unlocked.contains('century_club'),
        progress: (allTimeBooks.length / 100).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'double_century',
        title: 'Double Century',
        description: 'Read 200 books',
        icon: '🎖️',
        category: AchievementCategory.bookCount,
        isUnlocked: unlocked.contains('double_century'),
        progress: (allTimeBooks.length / 200).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'book_dragon',
        title: 'Book Dragon',
        description: 'Read 500 books',
        icon: '🐉',
        category: AchievementCategory.bookCount,
        isUnlocked: unlocked.contains('book_dragon'),
        progress: (allTimeBooks.length / 500).clamp(0.0, 1.0),
      ),

      // ========== PAGE COUNT ==========
      Achievement(
        id: 'thousand_pages',
        title: 'Page Turner',
        description: 'Read 1,000 pages',
        icon: '📄',
        category: AchievementCategory.pageCount,
        isUnlocked: unlocked.contains('thousand_pages'),
        progress: (totalPages / 1000).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'five_thousand_pages',
        title: 'Page Enthusiast',
        description: 'Read 5,000 pages',
        icon: '📑',
        category: AchievementCategory.pageCount,
        isUnlocked: unlocked.contains('five_thousand_pages'),
        progress: (totalPages / 5000).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'ten_thousand_pages',
        title: 'Bookstacker',
        description: 'Read 10,000 pages',
        icon: '📚',
        category: AchievementCategory.pageCount,
        isUnlocked: unlocked.contains('ten_thousand_pages'),
        progress: (totalPages / 10000).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'twentyfive_thousand_pages',
        title: 'Page Devourer',
        description: 'Read 25,000 pages',
        icon: '🔥',
        category: AchievementCategory.pageCount,
        isUnlocked: unlocked.contains('twentyfive_thousand_pages'),
        progress: (totalPages / 25000).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'fifty_thousand_pages',
        title: 'Paper Champion',
        description: 'Read 50,000 pages',
        icon: '🏅',
        category: AchievementCategory.pageCount,
        isUnlocked: unlocked.contains('fifty_thousand_pages'),
        progress: (totalPages / 50000).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'hundred_thousand_pages',
        title: 'Paper Legend',
        description: 'Read 100,000 pages',
        icon: '👑',
        category: AchievementCategory.pageCount,
        isUnlocked: unlocked.contains('hundred_thousand_pages'),
        progress: (totalPages / 100000).clamp(0.0, 1.0),
      ),

      // ========== RATINGS ==========
      Achievement(
        id: 'first_rating',
        title: 'Opinion Haver',
        description: 'Rate your first book',
        icon: '💭',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('first_rating'),
        progress: ratedBooks > 0 ? 1.0 : 0.0,
      ),
      Achievement(
        id: 'rating_rookie',
        title: 'Rating Rookie',
        description: 'Rate 10 books',
        icon: '📝',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('rating_rookie'),
        progress: (ratedBooks / 10).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'rating_regular',
        title: 'Rating Regular',
        description: 'Rate 25 books',
        icon: '✍️',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('rating_regular'),
        progress: (ratedBooks / 25).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'rating_expert',
        title: 'Rating Expert',
        description: 'Rate 50 books',
        icon: '🎯',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('rating_expert'),
        progress: (ratedBooks / 50).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'five_star_collector',
        title: 'Five Star Fan',
        description: 'Give 5 books a 5-star rating',
        icon: '⭐',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('five_star_collector'),
        progress: (fiveStarBooks / 5).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'star_shower',
        title: 'Star Shower',
        description: 'Give 10 books a 5-star rating',
        icon: '🌟',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('star_shower'),
        progress: (fiveStarBooks / 10).clamp(0.0, 1.0),
      ),
      Achievement(
        id: 'constellation',
        title: 'Constellation',
        description: 'Give 25 books a 5-star rating',
        icon: '✨',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('constellation'),
        progress: (fiveStarBooks / 25).clamp(0.0, 1.0),
      ),

      // ========== RATINGS (continued) ==========
      Achievement(
        id: 'first_favorite',
        title: 'First Favorite',
        description: 'Give your first 5-star rating',
        icon: '💫',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('first_favorite'),
        progress: fiveStarBooks > 0 ? 1.0 : 0.0,
      ),
      Achievement(
        id: 'not_for_me',
        title: 'Not For Me',
        description: 'Give your first 1-star rating',
        icon: '👎',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('not_for_me'),
      ),
      Achievement(
        id: 'harsh_critic',
        title: 'Harsh Critic',
        description: 'Give 1 star to 5 books',
        icon: '🧊',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('harsh_critic'),
      ),
      Achievement(
        id: 'full_spectrum',
        title: 'Full Spectrum',
        description: 'Use all ratings from 1 to 5 stars',
        icon: '🌈',
        category: AchievementCategory.ratings,
        isUnlocked: unlocked.contains('full_spectrum'),
      ),

      // ========== BOOK LENGTH ==========
      Achievement(
        id: 'short_and_sweet',
        title: 'Short and Sweet',
        description: 'Read a book under 150 pages',
        icon: '🍬',
        category: AchievementCategory.bookLength,
        isUnlocked: unlocked.contains('short_and_sweet'),
      ),
      Achievement(
        id: 'just_right',
        title: 'Just Right',
        description: 'Read a book between 200-400 pages',
        icon: '👌',
        category: AchievementCategory.bookLength,
        isUnlocked: unlocked.contains('just_right'),
      ),
      Achievement(
        id: 'epic_reader',
        title: 'Epic Reader',
        description: 'Read a 500+ page book',
        icon: '📖',
        category: AchievementCategory.bookLength,
        isUnlocked: unlocked.contains('epic_reader'),
      ),
      Achievement(
        id: 'tome_tackler',
        title: 'Tome Tackler',
        description: 'Read a 600+ page book',
        icon: '📕',
        category: AchievementCategory.bookLength,
        isUnlocked: unlocked.contains('tome_tackler'),
      ),
      Achievement(
        id: 'absolute_unit',
        title: 'Absolute Unit',
        description: 'Read a 750+ page book',
        icon: '🦣',
        category: AchievementCategory.bookLength,
        isUnlocked: unlocked.contains('absolute_unit'),
      ),
      Achievement(
        id: 'chonky_collector',
        title: 'Chonky Collector',
        description: 'Read 3 books over 500 pages',
        icon: '📚',
        category: AchievementCategory.bookLength,
        isUnlocked: unlocked.contains('chonky_collector'),
      ),
      Achievement(
        id: 'heavyweight_champ',
        title: 'Heavyweight Champ',
        description: 'Read a 1000+ page book',
        icon: '🏋️',
        category: AchievementCategory.bookLength,
        isUnlocked: unlocked.contains('heavyweight_champ'),
      ),

      // ========== SPEED ==========
      Achievement(
        id: 'same_day_finish',
        title: 'Same Day Finish',
        description: 'Finish a book the same day you started',
        icon: '☀️',
        category: AchievementCategory.speed,
        isUnlocked: unlocked.contains('same_day_finish'),
      ),
      Achievement(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Finish a book in one day',
        icon: '⚡',
        category: AchievementCategory.speed,
        isUnlocked: unlocked.contains('speed_demon'),
      ),
      Achievement(
        id: 'weekend_warrior',
        title: 'Weekend Warrior',
        description: 'Finish a book in under 3 days',
        icon: '🗓️',
        category: AchievementCategory.speed,
        isUnlocked: unlocked.contains('weekend_warrior'),
      ),
      Achievement(
        id: 'slow_burn',
        title: 'Slow Burn',
        description: 'Take over 2 months to finish a book',
        icon: '🐢',
        category: AchievementCategory.speed,
        isUnlocked: unlocked.contains('slow_burn'),
      ),
      Achievement(
        id: 'year_long_journey',
        title: 'Year Long Journey',
        description: 'Take over a year to finish a book',
        icon: '🗺️',
        category: AchievementCategory.speed,
        isUnlocked: unlocked.contains('year_long_journey'),
      ),
      Achievement(
        id: 'quick_reader',
        title: 'Quick Reader',
        description: 'Average under 7 days per book (5+ books)',
        icon: '🏃',
        category: AchievementCategory.speed,
        isUnlocked: unlocked.contains('quick_reader'),
      ),
      Achievement(
        id: 'lightning_reader',
        title: 'Lightning Reader',
        description: 'Average under 3 days per book (10+ books)',
        icon: '⚡',
        category: AchievementCategory.speed,
        isUnlocked: unlocked.contains('lightning_reader'),
      ),

      // ========== AUTHORS ==========
      Achievement(
        id: 'author_explorer',
        title: 'Author Explorer',
        description: 'Read books by 10 different authors',
        icon: '🔍',
        category: AchievementCategory.authors,
        isUnlocked: unlocked.contains('author_explorer'),
      ),
      Achievement(
        id: 'author_collector',
        title: 'Author Collector',
        description: 'Read books by 25 different authors',
        icon: '📚',
        category: AchievementCategory.authors,
        isUnlocked: unlocked.contains('author_collector'),
      ),
      Achievement(
        id: 'author_connoisseur',
        title: 'Author Connoisseur',
        description: 'Read books by 50 different authors',
        icon: '🎩',
        category: AchievementCategory.authors,
        isUnlocked: unlocked.contains('author_connoisseur'),
      ),
      Achievement(
        id: 'author_aficionado',
        title: 'Author Aficionado',
        description: 'Read books by 100 different authors',
        icon: '👑',
        category: AchievementCategory.authors,
        isUnlocked: unlocked.contains('author_aficionado'),
      ),
      Achievement(
        id: 'loyal_fan',
        title: 'Loyal Fan',
        description: 'Read 3+ books by the same author',
        icon: '🤝',
        category: AchievementCategory.authors,
        isUnlocked: unlocked.contains('loyal_fan'),
      ),
      Achievement(
        id: 'super_fan',
        title: 'Super Fan',
        description: 'Read 5+ books by the same author',
        icon: '💕',
        category: AchievementCategory.authors,
        isUnlocked: unlocked.contains('super_fan'),
      ),
      Achievement(
        id: 'ultimate_fan',
        title: 'Ultimate Fan',
        description: 'Read 10+ books by the same author',
        icon: '💗',
        category: AchievementCategory.authors,
        isUnlocked: unlocked.contains('ultimate_fan'),
      ),

      // ========== GENRES ==========
      Achievement(
        id: 'genre_curious',
        title: 'Genre Curious',
        description: 'Read books from 3+ genres',
        icon: '🔮',
        category: AchievementCategory.genres,
        isUnlocked: unlocked.contains('genre_curious'),
      ),
      Achievement(
        id: 'genre_explorer',
        title: 'Genre Explorer',
        description: 'Read books from 5+ genres',
        icon: '🗺️',
        category: AchievementCategory.genres,
        isUnlocked: unlocked.contains('genre_explorer'),
      ),
      Achievement(
        id: 'literary_adventurer',
        title: 'Literary Adventurer',
        description: 'Read books from 7+ genres',
        icon: '🧭',
        category: AchievementCategory.genres,
        isUnlocked: unlocked.contains('literary_adventurer'),
      ),
      Achievement(
        id: 'genre_master',
        title: 'Genre Master',
        description: 'Read books from 10+ genres',
        icon: '🌍',
        category: AchievementCategory.genres,
        isUnlocked: unlocked.contains('genre_master'),
      ),
      Achievement(
        id: 'omnireader',
        title: 'Omnireader',
        description: 'Read books from 15+ genres',
        icon: '🌌',
        category: AchievementCategory.genres,
        isUnlocked: unlocked.contains('omnireader'),
      ),

      // ========== RE-READS ==========
      Achievement(
        id: 'first_reread',
        title: 'Encore!',
        description: 'Re-read a book',
        icon: '🔄',
        category: AchievementCategory.rereads,
        isUnlocked: unlocked.contains('first_reread'),
      ),
      Achievement(
        id: 'comfort_reader',
        title: 'Comfort Reader',
        description: 'Re-read 3 different books',
        icon: '☕',
        category: AchievementCategory.rereads,
        isUnlocked: unlocked.contains('comfort_reader'),
      ),
      Achievement(
        id: 'nostalgia_lover',
        title: 'Nostalgia Lover',
        description: 'Re-read 5 different books',
        icon: '💭',
        category: AchievementCategory.rereads,
        isUnlocked: unlocked.contains('nostalgia_lover'),
      ),
      Achievement(
        id: 'many_favorites',
        title: 'Many Favorites',
        description: 'Re-read 10 different books',
        icon: '📚',
        category: AchievementCategory.rereads,
        isUnlocked: unlocked.contains('many_favorites'),
      ),
      Achievement(
        id: 'triple_read',
        title: 'Triple Read',
        description: 'Read the same book 3+ times',
        icon: '🛋️',
        category: AchievementCategory.rereads,
        isUnlocked: unlocked.contains('triple_read'),
      ),

      // ========== YEARLY ==========
      Achievement(
        id: 'consistent_reader',
        title: 'Consistent Reader',
        description: 'Read at least 1 book in 2 different years',
        icon: '📆',
        category: AchievementCategory.yearly,
        isUnlocked: unlocked.contains('consistent_reader'),
      ),
      Achievement(
        id: 'dedicated_reader',
        title: 'Dedicated Reader',
        description: 'Read at least 1 book in 5 different years',
        icon: '🗓️',
        category: AchievementCategory.yearly,
        isUnlocked: unlocked.contains('dedicated_reader'),
      ),
      Achievement(
        id: 'decade_reader',
        title: 'Decade Reader',
        description: 'Read at least 1 book in 10 different years',
        icon: '🏛️',
        category: AchievementCategory.yearly,
        isUnlocked: unlocked.contains('decade_reader'),
      ),

      // ========== SPECIAL ==========
      Achievement(
        id: 'variety_pack',
        title: 'Variety Pack',
        description: 'Read books of 5+ different page lengths',
        icon: '🎨',
        category: AchievementCategory.special,
        isUnlocked: unlocked.contains('variety_pack'),
      ),
      Achievement(
        id: 'bakers_dozen',
        title: "Baker's Dozen",
        description: 'Read exactly 13 books',
        icon: '🥖',
        category: AchievementCategory.special,
        isUnlocked: unlocked.contains('bakers_dozen'),
      ),
      Achievement(
        id: 'nice',
        title: 'Nice',
        description: 'Read exactly 69 books',
        icon: '😏',
        category: AchievementCategory.special,
        isUnlocked: unlocked.contains('nice'),
      ),
      Achievement(
        id: 'perfectly_balanced',
        title: 'Perfectly Balanced',
        description: 'Have same number of 5-star and 1-star ratings (5+ each)',
        icon: '⚖️',
        category: AchievementCategory.special,
        isUnlocked: unlocked.contains('perfectly_balanced'),
      ),
      Achievement(
        id: 'the_finisher',
        title: 'The Finisher',
        description: 'Finish every book you start (10+ books)',
        icon: '🏁',
        category: AchievementCategory.special,
        isUnlocked: unlocked.contains('the_finisher'),
      ),
    ];

    return all;
  }

  /// Get achievements grouped by category
  Map<AchievementCategory, List<Achievement>> get achievementsByCategory {
    final all = allPossibleAchievements;
    final grouped = <AchievementCategory, List<Achievement>>{};

    for (final category in AchievementCategory.values) {
      final categoryAchievements = all
          .where((a) => a.category == category)
          .toList();
      if (categoryAchievements.isNotEmpty) {
        grouped[category] = categoryAchievements;
      }
    }

    return grouped;
  }
}
