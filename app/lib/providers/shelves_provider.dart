import 'package:flutter/foundation.dart';
import '../models/custom_shelf.dart';
import '../services/graphql_service.dart';

class ShelvesProvider extends ChangeNotifier {
  final GraphQLService _graphQLService;

  List<CustomShelf> _customShelves = [];
  bool _isLoading = false;
  String? _error;

  List<CustomShelf> get customShelves => List.unmodifiable(_customShelves);
  List<CustomShelf> get sortedShelves =>
      [..._customShelves]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get shelfCount => _customShelves.length;

  ShelvesProvider({GraphQLService? graphQLService})
      : _graphQLService = graphQLService ?? GraphQLService() {
    syncFromBackend();
  }

  /// Sync custom shelves from backend
  Future<void> syncFromBackend() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final backendShelves = await _graphQLService.fetchMyCustomShelves();
      _customShelves = backendShelves
          .map((data) => CustomShelf.fromGraphQL(data))
          .toList();
    } catch (e) {
      _error = 'Failed to load shelves: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new custom shelf
  Future<CustomShelf?> createShelf(String name, {String? description}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Shelf name cannot be empty');
    }

    // Check for duplicate names locally
    final exists = _customShelves.any(
      (s) => s.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (exists) {
      throw ArgumentError('A shelf with this name already exists');
    }

    try {
      final result = await _graphQLService.createCustomShelf(
        name: trimmedName,
        description: description,
      );

      if (result != null) {
        final shelf = CustomShelf.fromGraphQL(result);
        _customShelves.add(shelf);
        notifyListeners();
        return shelf;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to create shelf: $e');
      rethrow;
    }
  }

  /// Rename an existing shelf
  Future<void> renameShelf(String shelfId, String newName, {String? description}) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Shelf name cannot be empty');
    }

    // Check for duplicate names (excluding current shelf)
    final exists = _customShelves.any(
      (s) => s.shelfId != shelfId && s.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (exists) {
      throw ArgumentError('A shelf with this name already exists');
    }

    final index = _customShelves.indexWhere((s) => s.shelfId == shelfId);
    if (index == -1) {
      throw ArgumentError('Shelf not found');
    }

    try {
      final result = await _graphQLService.updateCustomShelf(
        shelfId: shelfId,
        name: trimmedName,
        description: description,
      );

      if (result != null) {
        _customShelves[index] = CustomShelf.fromGraphQL(result);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to rename shelf: $e');
      rethrow;
    }
  }

  /// Delete a custom shelf
  Future<void> deleteShelf(String shelfId) async {
    try {
      await _graphQLService.deleteCustomShelf(shelfId);
      _customShelves.removeWhere((s) => s.shelfId == shelfId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete shelf: $e');
      rethrow;
    }
  }

  /// Get a shelf by ID
  CustomShelf? getShelf(String id) {
    try {
      return _customShelves.firstWhere((s) => s.shelfId == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if a shelf with the given name exists
  bool shelfNameExists(String name) {
    return _customShelves.any(
      (s) => s.name.toLowerCase() == name.trim().toLowerCase(),
    );
  }

  /// Get existing shelf by name or create it if it doesn't exist
  /// Returns the shelf ID
  Future<String?> getOrCreateShelf(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;

    // Check if shelf already exists
    final existing = _customShelves.firstWhere(
      (s) => s.name.toLowerCase() == trimmedName.toLowerCase(),
      orElse: () => CustomShelf(
        shelfId: '',
        userId: '',
        name: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existing.shelfId.isNotEmpty) {
      return existing.shelfId;
    }

    // Create new shelf
    try {
      final shelf = await createShelf(trimmedName);
      return shelf?.shelfId;
    } catch (e) {
      debugPrint('Failed to create shelf "$trimmedName": $e');
      return null;
    }
  }

  /// Get shelf by name
  CustomShelf? getShelfByName(String name) {
    final trimmedName = name.trim().toLowerCase();
    try {
      return _customShelves.firstWhere(
        (s) => s.name.toLowerCase() == trimmedName,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get the rating for a book on a specific shelf
  int? getBookRatingOnShelf(String shelfId, String bookId) {
    final shelf = getShelf(shelfId);
    return shelf?.getBookRating(bookId);
  }

  /// Update the rating for a book on a specific shelf
  /// Pass null for rating to remove the rating
  Future<void> updateBookRatingOnShelf(String shelfId, String bookId, int? rating) async {
    final index = _customShelves.indexWhere((s) => s.shelfId == shelfId);
    if (index == -1) {
      throw ArgumentError('Shelf not found');
    }

    // Optimistic update
    final oldShelf = _customShelves[index];
    final newRatings = Map<String, int>.from(oldShelf.bookRatings);
    if (rating != null) {
      newRatings[bookId] = rating;
    } else {
      newRatings.remove(bookId);
    }
    _customShelves[index] = oldShelf.copyWith(
      bookRatings: newRatings,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      final result = await _graphQLService.updateShelfBookRating(
        shelfId: shelfId,
        bookId: bookId,
        rating: rating,
      );

      if (result != null) {
        _customShelves[index] = CustomShelf.fromGraphQL(result);
        notifyListeners();
      }
    } catch (e) {
      // Revert on error
      _customShelves[index] = oldShelf;
      notifyListeners();
      debugPrint('Failed to update shelf book rating: $e');
      rethrow;
    }
  }
}
