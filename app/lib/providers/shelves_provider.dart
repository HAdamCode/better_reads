import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_shelf.dart';

class ShelvesProvider extends ChangeNotifier {
  static const String _storageKey = 'custom_shelves';

  List<CustomShelf> _customShelves = [];
  bool _isLoading = false;
  String? _error;

  List<CustomShelf> get customShelves => List.unmodifiable(_customShelves);
  List<CustomShelf> get sortedShelves =>
      [..._customShelves]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get shelfCount => _customShelves.length;

  ShelvesProvider() {
    loadShelves();
  }

  /// Load shelves from local storage
  Future<void> loadShelves() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);

      if (data != null) {
        final decoded = json.decode(data) as Map<String, dynamic>;
        final shelvesList = decoded['shelves'] as List<dynamic>? ?? [];
        _customShelves = shelvesList
            .map((e) => CustomShelf.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error = 'Failed to load shelves: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save shelves to local storage
  Future<void> _saveShelves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode({
        'shelves': _customShelves.map((s) => s.toJson()).toList(),
      });
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Failed to save shelves: $e');
    }
  }

  /// Create a new custom shelf
  Future<CustomShelf> createShelf(String name) async {
    // Check for duplicate names
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Shelf name cannot be empty');
    }

    final exists = _customShelves.any(
      (s) => s.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (exists) {
      throw ArgumentError('A shelf with this name already exists');
    }

    final shelf = CustomShelf.create(trimmedName);
    _customShelves.add(shelf);
    await _saveShelves();
    notifyListeners();
    return shelf;
  }

  /// Rename an existing shelf
  Future<void> renameShelf(String shelfId, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Shelf name cannot be empty');
    }

    // Check for duplicate names (excluding current shelf)
    final exists = _customShelves.any(
      (s) => s.id != shelfId && s.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (exists) {
      throw ArgumentError('A shelf with this name already exists');
    }

    final index = _customShelves.indexWhere((s) => s.id == shelfId);
    if (index == -1) {
      throw ArgumentError('Shelf not found');
    }

    _customShelves[index] = _customShelves[index].copyWith(
      name: trimmedName,
      updatedAt: DateTime.now(),
    );
    await _saveShelves();
    notifyListeners();
  }

  /// Delete a custom shelf
  Future<void> deleteShelf(String shelfId) async {
    _customShelves.removeWhere((s) => s.id == shelfId);
    await _saveShelves();
    notifyListeners();
  }

  /// Get a shelf by ID
  CustomShelf? getShelf(String id) {
    try {
      return _customShelves.firstWhere((s) => s.id == id);
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
}
