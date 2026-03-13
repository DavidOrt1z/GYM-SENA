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
      fullName: json['nombre_completo'] ?? '',
      lastName: json['apellido'],
      email: json['correo_electronico'] ?? '',
      phone: json['teléfono'],
      role: json['rol'] ?? 'member',
      status: json['estado'] ?? 'active',
      age: json['edad'],
      heightCm: json['altura_cm']?.toDouble(),
      weightKg: json['peso_kg']?.toDouble(),
      language: json['idioma'] ?? 'es',
      theme: json['theme'] ?? 'system',
      avatarUrl: json['url_avatar'],
      createdAt: json['fecha_creacion'] != null ? DateTime.parse(json['fecha_creacion']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': fullName,
      'apellido': lastName,
      'correo_electronico': email,
      'teléfono': phone,
      'rol': role,
      'estado': status,
      'edad': age,
      'altura_cm': heightCm,
      'peso_kg': weightKg,
      'idioma': language,
      'theme': theme,
      'url_avatar': avatarUrl,
      'fecha_creacion': createdAt?.toIso8601String(),
    };
  }
}

