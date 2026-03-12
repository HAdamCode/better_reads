import 'package:flutter/foundation.dart';
import '../models/reading_location.dart';
import '../services/graphql_service.dart';

class LocationsProvider extends ChangeNotifier {
  final GraphQLService _graphQLService;

  List<ReadingLocation> _locations = [];
  final Map<String, List<ReadingLocation>> _friendLocations = {};
  bool _isLoading = false;
  String? _error;

  List<ReadingLocation> get locations => List.unmodifiable(_locations);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get locationCount => _locations.length;

  LocationsProvider({GraphQLService? graphQLService})
      : _graphQLService = graphQLService ?? GraphQLService() {
    syncFromBackend();
  }

  /// Sync locations from backend
  Future<void> syncFromBackend() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final backendLocations = await _graphQLService.fetchMyReadingLocations();
      _locations = backendLocations
          .map((data) => ReadingLocation.fromGraphQL(data))
          .toList();
    } catch (e) {
      _error = 'Failed to load locations: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new reading location
  Future<ReadingLocation?> addLocation({
    String? bookId,
    required double latitude,
    required double longitude,
    required String locationName,
    String? address,
    String? notes,
  }) async {
    try {
      final result = await _graphQLService.createReadingLocation(
        bookId: bookId,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        address: address,
        notes: notes,
      );

      if (result != null) {
        final location = ReadingLocation.fromGraphQL(result);
        _locations.add(location);
        notifyListeners();
        return location;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to add location: $e');
      rethrow;
    }
  }

  /// Update an existing reading location
  Future<void> updateLocation({
    required String locationId,
    String? bookId,
    String? locationName,
    String? address,
    String? notes,
  }) async {
    final index = _locations.indexWhere((l) => l.locationId == locationId);
    if (index == -1) {
      throw ArgumentError('Location not found');
    }

    try {
      final result = await _graphQLService.updateReadingLocation(
        locationId: locationId,
        bookId: bookId,
        locationName: locationName,
        address: address,
        notes: notes,
      );

      if (result != null) {
        _locations[index] = ReadingLocation.fromGraphQL(result);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update location: $e');
      rethrow;
    }
  }

  /// Delete a reading location
  Future<void> deleteLocation(String locationId) async {
    try {
      await _graphQLService.deleteReadingLocation(locationId);
      _locations.removeWhere((l) => l.locationId == locationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete location: $e');
      rethrow;
    }
  }

  /// Fetch a friend's reading locations
  Future<List<ReadingLocation>> fetchFriendLocations(String userId) async {
    try {
      final data = await _graphQLService.fetchUserReadingLocations(userId);
      final locations = data
          .map((d) => ReadingLocation.fromGraphQL(d))
          .toList();
      _friendLocations[userId] = locations;
      notifyListeners();
      return locations;
    } catch (e) {
      debugPrint('Failed to fetch friend locations: $e');
      rethrow;
    }
  }

  /// Get cached friend locations
  List<ReadingLocation> getFriendLocations(String userId) {
    return _friendLocations[userId] ?? [];
  }

  /// Get all cached friend locations combined
  List<ReadingLocation> get allFriendLocations {
    return _friendLocations.values.expand((list) => list).toList();
  }

  /// Get locations linked to a specific book
  List<ReadingLocation> getLocationsForBook(String bookId) {
    return _locations.where((l) => l.bookId == bookId).toList();
  }
}
