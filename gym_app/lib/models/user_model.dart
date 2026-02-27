class UserModel {
  final String id;
  final String fullName;
  final String? lastName;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? language;
  final String? theme;
  final String? avatarUrl;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    this.lastName,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.age,
    this.heightCm,
    this.weightKg,
    this.language,
    this.theme,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      lastName: json['last_name'],
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'active',
      age: json['age'],
      heightCm: json['height_cm']?.toDouble(),
      weightKg: json['weight_kg']?.toDouble(),
      language: json['language'] ?? 'es',
      theme: json['theme'] ?? 'system',
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'language': language,
      'theme': theme,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

