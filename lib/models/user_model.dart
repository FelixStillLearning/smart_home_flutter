class User {
  final int userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? faceEncodingPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.faceEncodingPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      faceEncodingPath: json['face_encoding_path'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'face_encoding_path': faceEncodingPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isSuspended => status == 'suspended';
  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String? role;
  final String? faceImage;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.role,
    this.faceImage,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'password': password,
    };

    if (role != null) {
      data['role'] = role;
    }

    if (faceImage != null && faceImage!.isNotEmpty) {
      data['face_image'] = faceImage;
    }

    return data;
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final User? user;
  final String? error;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      error: json['error'],
    );
  }
}
