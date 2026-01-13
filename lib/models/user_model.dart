class UserModel {
  final String id;
  final String email;
  final String? name;
  final String role; // 'admin' or 'user'
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
}