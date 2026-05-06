class UserModel {
  final String id;
  final String nombre;
  final String? apellido;
  final String? cedula;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? language;
  final String? units;
  final String? theme;
  final String? avatarUrl;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.nombre,
    this.apellido,
    this.cedula,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.age,
    this.heightCm,
    this.weightKg,
    this.language,
    this.units,
    this.theme,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'],
      cedula: json['cedula'],
      email: json['correo_electronico'] ?? '',
      phone: json['teléfono'],
      role: json['rol'] ?? 'member',
      status: json['estado'] ?? 'active',
      age: json['edad'],
      heightCm: json['altura_cm']?.toDouble(),
      weightKg: json['peso_kg']?.toDouble(),
      language: json['idioma'] ?? 'es',
      units: json['unidades'] ?? 'metric',
      theme: json['theme'] ?? 'system',
      avatarUrl: json['url_avatar'],
      createdAt: json['fecha_creacion'] != null ? DateTime.parse(json['fecha_creacion']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'correo_electronico': email,
      'teléfono': phone,
      'rol': role,
      'estado': status,
      'edad': age,
      'altura_cm': heightCm,
      'peso_kg': weightKg,
      'idioma': language,
      'unidades': units,
      'theme': theme,
      'url_avatar': avatarUrl,
      'fecha_creacion': createdAt?.toIso8601String(),
    };
  }
}

