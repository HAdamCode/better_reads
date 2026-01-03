class BookLoan {
  final String loanId;
  final String userId;
  final String bookId;
  final String borrowerName;
  final DateTime lentAt;
  final DateTime? returnedAt;

  BookLoan({
    required this.loanId,
    required this.userId,
    required this.bookId,
    required this.borrowerName,
    required this.lentAt,
    this.returnedAt,
  });

  /// Alias for loanId for backward compatibility
  String get id => loanId;

  bool get isActive => returnedAt == null;

  factory BookLoan.fromGraphQL(Map<String, dynamic> json) {
    return BookLoan(
      loanId: json['loanId'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      borrowerName: json['borrowerName'] as String,
      lentAt: DateTime.parse(json['lentAt'] as String),
      returnedAt: json['returnedAt'] != null
          ? DateTime.parse(json['returnedAt'] as String)
          : null,
    );
  }

  BookLoan copyWith({
    String? loanId,
    String? userId,
    String? bookId,
    String? borrowerName,
    DateTime? lentAt,
    DateTime? returnedAt,
  }) {
    return BookLoan(
      loanId: loanId ?? this.loanId,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      borrowerName: borrowerName ?? this.borrowerName,
      lentAt: lentAt ?? this.lentAt,
      returnedAt: returnedAt ?? this.returnedAt,
    );
  }

  /// Mark this loan as returned
  BookLoan markReturned() {
    return copyWith(returnedAt: DateTime.now());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookLoan && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
