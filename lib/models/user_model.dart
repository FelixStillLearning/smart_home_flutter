// lib/models/user_model.dart
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
    };
  }
  
  bool get isAdmin => role == 'admin';
  bool get isActive => status == 'active';
}
