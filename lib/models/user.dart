// lib/models/user.dart
class AppUser {
  final String id;
  final String username;
  final String? area;
  final String salesman;
  final String email;
  final String userType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.username,
    this.area,
    required this.salesman,
    required this.email,
    required this.userType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      area: json['area'] as String?,
      salesman: json['salesman'] as String,
      email: json['email'] as String,
      userType: json['user_type'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'area': area,
      'salesman': salesman,
      'email': email,
      'user_type': userType,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => userType == 'admin';
}
