import 'package:flutter/foundation.dart';
import '../models/book_loan.dart';
import '../services/graphql_service.dart';

class LendingProvider extends ChangeNotifier {
  final GraphQLService _graphQLService;

  List<BookLoan> _loans = [];
  bool _isLoading = false;
  String? _error;

  List<BookLoan> get loans => List.unmodifiable(_loans);
  List<BookLoan> get activeLoans => _loans.where((l) => l.isActive).toList();
  List<BookLoan> get returnedLoans => _loans.where((l) => !l.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get activeLoanCount => activeLoans.length;

  LendingProvider({GraphQLService? graphQLService})
      : _graphQLService = graphQLService ?? GraphQLService() {
    syncFromBackend();
  }

  /// Sync loans from backend
  Future<void> syncFromBackend() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final backendLoans = await _graphQLService.fetchMyLoans();
      _loans = backendLoans
          .map((data) => BookLoan.fromGraphQL(data))
          .toList();
    } catch (e) {
      _error = 'Failed to load loans: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lend a book to someone
  Future<BookLoan?> lendBook(String bookId, String borrowerName) async {
    final trimmedName = borrowerName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Borrower name cannot be empty');
    }

    // Check if this book is already lent out
    if (isBookLentOut(bookId)) {
      throw ArgumentError('This book is already lent out');
    }

    try {
      final result = await _graphQLService.lendBook(
        bookId: bookId,
        borrowerName: trimmedName,
      );

      if (result != null) {
        final loan = BookLoan.fromGraphQL(result);
        _loans.add(loan);
        notifyListeners();
        return loan;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to lend book: $e');
      rethrow;
    }
  }

  /// Mark a book as returned
  Future<void> returnBook(String loanId) async {
    final index = _loans.indexWhere((l) => l.loanId == loanId);
    if (index == -1) {
      throw ArgumentError('Loan not found');
    }

    try {
      final result = await _graphQLService.returnBook(loanId);

      if (result != null) {
        _loans[index] = BookLoan.fromGraphQL(result);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to return book: $e');
      rethrow;
    }
  }

  /// Update the borrower name for a loan
  Future<void> updateBorrowerName(String loanId, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Borrower name cannot be empty');
    }

    final index = _loans.indexWhere((l) => l.loanId == loanId);
    if (index == -1) {
      throw ArgumentError('Loan not found');
    }

    try {
      final result = await _graphQLService.updateLoan(
        loanId: loanId,
        borrowerName: trimmedName,
      );

      if (result != null) {
        _loans[index] = BookLoan.fromGraphQL(result);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update borrower name: $e');
      rethrow;
    }
  }

  /// Delete a loan record (for corrections)
  Future<void> deleteLoan(String loanId) async {
    try {
      await _graphQLService.deleteLoan(loanId);
      _loans.removeWhere((l) => l.loanId == loanId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete loan: $e');
      rethrow;
    }
  }

  /// Get the active loan for a specific book (if any)
  BookLoan? getActiveLoanForBook(String bookId) {
    try {
      return _loans.firstWhere((l) => l.bookId == bookId && l.isActive);
    } catch (_) {
      return null;
    }
  }

  /// Check if a book is currently lent out
  bool isBookLentOut(String bookId) {
    return _loans.any((l) => l.bookId == bookId && l.isActive);
  }

  /// Get all loans (active and returned) for a specific book
  List<BookLoan> getLoanHistoryForBook(String bookId) {
    return _loans.where((l) => l.bookId == bookId).toList()
      ..sort((a, b) => b.lentAt.compareTo(a.lentAt));
  }
}
