enum FriendStatus {
  pending,
  accepted,
  blocked,
}

extension FriendStatusExtension on FriendStatus {
  String get apiValue {
    switch (this) {
      case FriendStatus.pending:
        return 'PENDING';
      case FriendStatus.accepted:
        return 'ACCEPTED';
      case FriendStatus.blocked:
        return 'BLOCKED';
    }
  }

  static FriendStatus fromApiValue(String value) {
    switch (value) {
      case 'PENDING':
        return FriendStatus.pending;
      case 'ACCEPTED':
        return FriendStatus.accepted;
      case 'BLOCKED':
        return FriendStatus.blocked;
      default:
        return FriendStatus.pending;
    }
  }
}

class Friend {
  final String userId;
  final String friendId;
  final FriendStatus status;
  final DateTime createdAt;

  Friend({
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userId: json['userId'] as String,
      friendId: json['friendId'] as String,
      status: FriendStatusExtension.fromApiValue(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'friendId': friendId,
      'status': status.apiValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
