class ReadingSession {
  final String userId;
  final String bookId;
  final String sessionId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;

  ReadingSession({
    required this.userId,
    required this.bookId,
    required this.sessionId,
    required this.startedAt,
    this.finishedAt,
    required this.createdAt,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      sessionId: json['sessionId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'bookId': bookId,
      'sessionId': sessionId,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReadingSession copyWith({
    String? userId,
    String? bookId,
    String? sessionId,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? createdAt,
  }) {
    return ReadingSession(
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get the duration of this reading session
  Duration? get duration {
    if (finishedAt == null) return null;
    return finishedAt!.difference(startedAt);
  }

  /// Check if this session is complete (has a finish date)
  bool get isComplete => finishedAt != null;

  /// Get a human-readable duration string
  String get durationString {
    final dur = duration;
    if (dur == null) return 'In progress';

    final days = dur.inDays;
    if (days == 0) return 'Same day';
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    if (days < 30) {
      final weeks = (days / 7).round();
      return '$weeks week${weeks > 1 ? 's' : ''}';
    }
    final months = (days / 30).round();
    return '$months month${months > 1 ? 's' : ''}';
  }
}
