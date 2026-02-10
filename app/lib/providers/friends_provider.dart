import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../models/user.dart';
import '../models/user_book.dart';
import '../services/graphql_service.dart';

class FriendsProvider extends ChangeNotifier {
  final GraphQLService _graphQLService;

  List<Friend> _friends = [];
  List<Friend> _friendRequests = [];
  List<User> _searchResults = [];
  final Map<String, User> _userCache = {};
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<Friend> get friends => List.unmodifiable(_friends);
  List<Friend> get friendRequests => List.unmodifiable(_friendRequests);
  List<User> get searchResults => List.unmodifiable(_searchResults);
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  int get friendCount => _friends.length;
  int get pendingRequestCount => _friendRequests.length;

  FriendsProvider({GraphQLService? graphQLService})
      : _graphQLService = graphQLService ?? GraphQLService() {
    syncFromBackend();
  }

  /// Sync friends and requests from backend
  Future<void> syncFromBackend() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _graphQLService.fetchFriends(),
        _graphQLService.fetchFriendRequests(),
      ]);

      _friends = (results[0])
          .map((data) => Friend.fromJson(data))
          .toList();

      _friendRequests = (results[1])
          .map((data) => Friend.fromJson(data))
          .toList();

      // Fetch user details for friends and requests
      await _fetchUserDetails();
    } catch (e) {
      _error = 'Failed to load friends: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user details for all friends and requesters
  Future<void> _fetchUserDetails() async {
    final userIds = <String>{};

    for (final friend in _friends) {
      userIds.add(friend.friendId);
    }
    for (final request in _friendRequests) {
      // For requests, userId is the person who sent the request
      userIds.add(request.userId);
    }

    // Fetch users not already in cache
    for (final userId in userIds) {
      if (!_userCache.containsKey(userId)) {
        try {
          final userData = await _graphQLService.getUser(userId);
          if (userData != null) {
            _userCache[userId] = User.fromJson(userData);
          }
        } catch (e) {
          debugPrint('Failed to fetch user $userId: $e');
        }
      }
    }
  }

  /// Get user details for a friend
  User? getUserForFriend(Friend friend) {
    return _userCache[friend.friendId];
  }

  /// Get user details for a friend request (the sender)
  User? getUserForRequest(Friend request) {
    return _userCache[request.userId];
  }

  /// Search for users by name or email
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final results = await _graphQLService.searchUsers(query, limit: 20);
      _searchResults = results.map((data) => User.fromJson(data)).toList();

      // Cache the users
      for (final user in _searchResults) {
        _userCache[user.userId] = user;
      }
    } catch (e) {
      debugPrint('Failed to search users: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  /// Send a friend request
  Future<void> sendFriendRequest(String userId) async {
    try {
      final result = await _graphQLService.addFriend(userId);

      if (result != null) {
        // Request sent - it's in PENDING status from our side
        // We don't add to _friends until accepted by them
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to send friend request: $e');
      rethrow;
    }
  }

  /// Accept a friend request
  Future<void> acceptRequest(String friendId) async {
    final requestIndex = _friendRequests.indexWhere((r) => r.userId == friendId);
    if (requestIndex == -1) {
      throw ArgumentError('Friend request not found');
    }

    try {
      final result = await _graphQLService.acceptFriend(friendId);

      if (result != null) {
        // Remove from requests
        final request = _friendRequests.removeAt(requestIndex);

        // Add to friends (status is now ACCEPTED)
        final friend = Friend(
          userId: request.userId,
          friendId: request.friendId,
          status: FriendStatus.accepted,
          createdAt: request.createdAt,
        );
        _friends.add(friend);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to accept friend request: $e');
      rethrow;
    }
  }

  /// Decline a friend request
  Future<void> declineRequest(String friendId) async {
    final requestIndex = _friendRequests.indexWhere((r) => r.userId == friendId);
    if (requestIndex == -1) {
      throw ArgumentError('Friend request not found');
    }

    try {
      // To decline, we need the requester to remove their request
      // But since we can't do that, we just remove it locally
      // In a real app, you'd want a separate "decline" mutation
      _friendRequests.removeAt(requestIndex);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to decline friend request: $e');
      rethrow;
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    final friendIndex = _friends.indexWhere((f) => f.friendId == friendId);
    if (friendIndex == -1) {
      throw ArgumentError('Friend not found');
    }

    try {
      await _graphQLService.removeFriend(friendId);
      _friends.removeAt(friendIndex);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove friend: $e');
      rethrow;
    }
  }

  /// Check if a user is already a friend
  bool isFriend(String userId) {
    return _friends.any((f) => f.friendId == userId);
  }

  /// Check if a friend request is pending for this user
  bool hasPendingRequest(String userId) {
    return _friendRequests.any((r) => r.userId == userId);
  }

  /// Get a user from cache
  User? getCachedUser(String userId) {
    return _userCache[userId];
  }

  /// Fetch and cache a user
  Future<User?> fetchUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final userData = await _graphQLService.getUser(userId);
      if (userData != null) {
        final user = User.fromJson(userData);
        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Failed to fetch user $userId: $e');
    }
    return null;
  }

  /// Fetch books for a user (friend's library)
  Future<List<UserBook>> fetchUserBooks(String userId) async {
    try {
      final booksData = await _graphQLService.getUserBooks(userId);
      return booksData.map((data) => UserBook.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Failed to fetch user books: $e');
      return [];
    }
  }
}
