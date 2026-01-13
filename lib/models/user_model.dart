class UserModel {
  final int? id;
  final String name;
  final String email;
  final String faceId;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.faceId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'face_id': faceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      faceId: map['face_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  UserModel copyWith({int? id, String? name, String? email, String? faceId, DateTime? createdAt}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      faceId: faceId ?? this.faceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, faceId: $faceId)';
  }
}
