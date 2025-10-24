class User {
  final String? id;
  final String username;
  final String fullName;
  final String? email;
  final String role;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  User({
    this.id,
    required this.username,
    required this.fullName,
    this.email,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String?,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'username': username,
      'fullName': fullName,
      if (email != null) 'email': email,
      'role': role,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  // Copy with method để tạo bản sao với một số trường được cập nhật
  User copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, fullName: $fullName, email: $email, role: $role, isActive: $isActive}';
  }
}
