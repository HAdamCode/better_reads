import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

class GraphQLService {
  static final GraphQLService _instance = GraphQLService._internal();
  factory GraphQLService() => _instance;
  GraphQLService._internal();

  /// Fetch all books for the current user
  Future<List<Map<String, dynamic>>> fetchMyBooks() async {
    const query = '''
      query MyBooks {
        myBooks {
          userId
          bookId
          shelf
          customShelfIds
          rating
          startedAt
          finishedAt
          pagesRead
          addedAt
          updatedAt
        }
      }
    ''';

    try {
      final request = GraphQLRequest<String>(document: query);
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) {
        return [];
      }

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      final books = data['myBooks'] as List<dynamic>? ?? [];
      return books.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Failed to fetch my books: $e');
      rethrow;
    }
  }

  /// Add a book to shelf
  Future<Map<String, dynamic>?> addBookToShelf({
    required String bookId,
    required String shelf,
    List<String>? customShelfIds,
    int? rating,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? pagesRead,
  }) async {
    const mutation = '''
      mutation AddBookToShelf(\$input: AddBookToShelfInput!) {
        addBookToShelf(input: \$input) {
          userId
          bookId
          shelf
          customShelfIds
          rating
          startedAt
          finishedAt
          pagesRead
          addedAt
          updatedAt
        }
      }
    ''';

    try {
      final variables = {
        'input': {
          'bookId': bookId,
          'shelf': shelf,
          if (customShelfIds != null && customShelfIds.isNotEmpty) 'customShelfIds': customShelfIds,
          if (rating != null) 'rating': rating,
          if (startedAt != null) 'startedAt': startedAt.toUtc().toIso8601String(),
          if (finishedAt != null) 'finishedAt': finishedAt.toUtc().toIso8601String(),
          if (pagesRead != null) 'pagesRead': pagesRead,
        },
      };

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: variables,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) return null;

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      return data['addBookToShelf'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to add book to shelf: $e');
      rethrow;
    }
  }

  /// Update book shelf
  Future<Map<String, dynamic>?> updateBookShelf({
    required String bookId,
    required String shelf,
    List<String>? customShelfIds,
    int? rating,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? pagesRead,
  }) async {
    const mutation = '''
      mutation UpdateBookShelf(\$input: UpdateBookShelfInput!) {
        updateBookShelf(input: \$input) {
          userId
          bookId
          shelf
          customShelfIds
          rating
          startedAt
          finishedAt
          pagesRead
          addedAt
          updatedAt
        }
      }
    ''';

    try {
      final variables = {
        'input': {
          'bookId': bookId,
          'shelf': shelf,
          if (customShelfIds != null) 'customShelfIds': customShelfIds,
          if (rating != null) 'rating': rating,
          if (startedAt != null) 'startedAt': startedAt.toUtc().toIso8601String(),
          if (finishedAt != null) 'finishedAt': finishedAt.toUtc().toIso8601String(),
          if (pagesRead != null) 'pagesRead': pagesRead,
        },
      };

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: variables,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) return null;

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      return data['updateBookShelf'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to update book shelf: $e');
      rethrow;
    }
  }

  /// Remove book from shelf
  Future<bool> removeBookFromShelf(String bookId) async {
    const mutation = '''
      mutation RemoveBookFromShelf(\$bookId: String!) {
        removeBookFromShelf(bookId: \$bookId) {
          bookId
        }
      }
    ''';

    try {
      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {'bookId': bookId},
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to remove book from shelf: $e');
      rethrow;
    }
  }

  // ========================================
  // CUSTOM SHELVES
  // ========================================

  /// Fetch all custom shelves for the current user
  Future<List<Map<String, dynamic>>> fetchMyCustomShelves() async {
    const query = '''
      query MyCustomShelves {
        myCustomShelves {
          userId
          shelfId
          name
          description
          bookRatings
          createdAt
          updatedAt
        }
      }
    ''';

    try {
      final request = GraphQLRequest<String>(document: query);
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) {
        return [];
      }

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      final shelves = data['myCustomShelves'] as List<dynamic>? ?? [];
      return shelves.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Failed to fetch custom shelves: $e');
      rethrow;
    }
  }

  /// Create a custom shelf
  Future<Map<String, dynamic>?> createCustomShelf({
    required String name,
    String? description,
  }) async {
    const mutation = '''
      mutation CreateCustomShelf(\$input: CreateCustomShelfInput!) {
        createCustomShelf(input: \$input) {
          userId
          shelfId
          name
          description
          bookRatings
          createdAt
          updatedAt
        }
      }
    ''';

    try {
      final variables = {
        'input': {
          'name': name,
          if (description != null) 'description': description,
        },
      };

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: variables,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) return null;

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      return data['createCustomShelf'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to create custom shelf: $e');
      rethrow;
    }
  }

  /// Update a custom shelf
  Future<Map<String, dynamic>?> updateCustomShelf({
    required String shelfId,
    String? name,
    String? description,
  }) async {
    const mutation = '''
      mutation UpdateCustomShelf(\$input: UpdateCustomShelfInput!) {
        updateCustomShelf(input: \$input) {
          userId
          shelfId
          name
          description
          bookRatings
          createdAt
          updatedAt
        }
      }
    ''';

    try {
      final variables = {
        'input': {
          'shelfId': shelfId,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        },
      };

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: variables,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) return null;

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      return data['updateCustomShelf'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to update custom shelf: $e');
      rethrow;
    }
  }

  /// Delete a custom shelf
  Future<bool> deleteCustomShelf(String shelfId) async {
    const mutation = '''
      mutation DeleteCustomShelf(\$shelfId: ID!) {
        deleteCustomShelf(shelfId: \$shelfId) {
          shelfId
        }
      }
    ''';

    try {
      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {'shelfId': shelfId},
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to delete custom shelf: $e');
      rethrow;
    }
  }

  /// Update the rating for a book on a specific shelf
  /// Pass null for rating to remove the rating
  Future<Map<String, dynamic>?> updateShelfBookRating({
    required String shelfId,
    required String bookId,
    int? rating,
  }) async {
    const mutation = '''
      mutation UpdateShelfBookRating(\$shelfId: ID!, \$bookId: String!, \$rating: Int) {
        updateShelfBookRating(shelfId: \$shelfId, bookId: \$bookId, rating: \$rating) {
          userId
          shelfId
          name
          description
          bookRatings
          createdAt
          updatedAt
        }
      }
    ''';

    try {
      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'shelfId': shelfId,
          'bookId': bookId,
          if (rating != null) 'rating': rating,
        },
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) return null;

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      return data['updateShelfBookRating'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to update shelf book rating: $e');
      rethrow;
    }
  }

  // ========================================
  // BOOK LOANS
  // ========================================

  /// Fetch all loans for the current user
  Future<List<Map<String, dynamic>>> fetchMyLoans() async {
    const query = '''
      query MyLoans {
        myLoans {
          userId
          loanId
          bookId
          borrowerName
          lentAt
          returnedAt
        }
      }
    ''';

    try {
      final request = GraphQLRequest<String>(document: query);
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) {
        return [];
      }

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      final loans = data['myLoans'] as List<dynamic>? ?? [];
      return loans.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Failed to fetch loans: $e');
      rethrow;
    }
  }

  /// Fetch only active (unreturned) loans
  Future<List<Map<String, dynamic>>> fetchActiveLoans() async {
    const query = '''
      query ActiveLoans {
        activeLoans {
          userId
          loanId
          bookId
          borrowerName
          lentAt
          returnedAt
        }
      }
    ''';

    try {
      final request = GraphQLRequest<String>(document: query);
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) {
        return [];
      }

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      final loans = data['activeLoans'] as List<dynamic>? ?? [];
      return loans.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Failed to fetch active loans: $e');
      rethrow;
    }
  }

  /// Lend a book to someone
  Future<Map<String, dynamic>?> lendBook({
    required String bookId,
    required String borrowerName,
  }) async {
    const mutation = '''
      mutation LendBook(\$input: LendBookInput!) {
        lendBook(input: \$input) {
          userId
          loanId
          bookId
          borrowerName
          lentAt
          returnedAt
        }
      }
    ''';

    try {
      final variables = {
        'input': {
          'bookId': bookId,
          'borrowerName': borrowerName,
        },
      };

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: variables,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) return null;

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      return data['lendBook'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to lend book: $e');
      rethrow;
    }
  }

  /// Mark a book as returned
  Future<Map<String, dynamic>?> returnBook(String loanId) async {
    const mutation = '''
      mutation ReturnBook(\$loanId: ID!) {
        returnBook(loanId: \$loanId) {
          userId
          loanId
          bookId
          borrowerName
          lentAt
          returnedAt
        }
      }
    ''';

    try {
      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {'loanId': loanId},
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) return null;

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      return data['returnBook'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to return book: $e');
      rethrow;
    }
  }

  /// Update loan borrower name
  Future<Map<String, dynamic>?> updateLoan({
    required String loanId,
    required String borrowerName,
  }) async {
    const mutation = '''
      mutation UpdateLoan(\$input: UpdateLoanInput!) {
        updateLoan(input: \$input) {
          userId
          loanId
          bookId
          borrowerName
          lentAt
          returnedAt
        }
      }
    ''';

    try {
      final variables = {
        'input': {
          'loanId': loanId,
          'borrowerName': borrowerName,
        },
      };

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: variables,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      if (response.data == null) return null;

      final data = jsonDecode(response.data!) as Map<String, dynamic>;
      return data['updateLoan'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to update loan: $e');
      rethrow;
    }
  }

  /// Delete a loan record
  Future<bool> deleteLoan(String loanId) async {
    const mutation = '''
      mutation DeleteLoan(\$loanId: ID!) {
        deleteLoan(loanId: \$loanId) {
          loanId
        }
      }
    ''';

    try {
      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {'loanId': loanId},
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        debugPrint('GraphQL errors: ${response.errors}');
        throw Exception(response.errors.first.message);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to delete loan: $e');
      rethrow;
    }
  }
}
