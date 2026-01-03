import 'package:uuid/uuid.dart';

class CustomShelf {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomShelf({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomShelf.create(String name) {
    final now = DateTime.now();
    return CustomShelf(
      id: const Uuid().v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CustomShelf.fromJson(Map<String, dynamic> json) {
    return CustomShelf(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CustomShelf copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomShelf(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomShelf &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
