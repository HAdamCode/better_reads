class ReadingLocation {
  final String locationId;
  final String userId;
  final String? bookId;
  final double latitude;
  final double longitude;
  final String locationName;
  final String? address;
  final String? notes;
  final DateTime createdAt;

  ReadingLocation({
    required this.locationId,
    required this.userId,
    this.bookId,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.address,
    this.notes,
    required this.createdAt,
  });

  factory ReadingLocation.fromGraphQL(Map<String, dynamic> json) {
    return ReadingLocation(
      locationId: json['locationId'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['locationName'] as String,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'userId': userId,
      if (bookId != null) 'bookId': bookId,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReadingLocation copyWith({
    String? locationId,
    String? userId,
    String? bookId,
    double? latitude,
    double? longitude,
    String? locationName,
    String? address,
    String? notes,
    DateTime? createdAt,
  }) {
    return ReadingLocation(
      locationId: locationId ?? this.locationId,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingLocation &&
          runtimeType == other.runtimeType &&
          locationId == other.locationId;

  @override
  int get hashCode => locationId.hashCode;
}
