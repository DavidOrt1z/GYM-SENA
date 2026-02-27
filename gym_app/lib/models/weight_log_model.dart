class WeightLogModel {
  final int id;
  final String userId;          // ID del usuario
  final double weight;          // Peso en kg
  final String unit;            // "kg" o "lbs"
  final DateTime recordedAt;    // Fecha/hora del registro
  final String? notes;          // Notas adicionales
  final DateTime createdAt;
  final DateTime updatedAt;

  WeightLogModel({
    required this.id,
    required this.userId,
    required this.weight,
    required this.unit,
    required this.recordedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ PROPIEDADES CALCULADAS

  /// Conversión a libras (si está en kg)
  double get weightInLbs {
    if (unit == 'lbs') return weight;
    return weight * 2.20462;
  }

  /// Conversión a kg (si está en lbs)
  double get weightInKg {
    if (unit == 'kg') return weight;
    return weight / 2.20462;
  }

  /// Peso formateado con unidad (Ej: "75.5 kg")
  String get displayWeight => '${weight.toStringAsFixed(1)} $unit';

  /// Fecha formateada en español (Ej: "08 Feb 2026")
  String get displayDate {
    final day = recordedAt.day.toString().padLeft(2, '0');
    final month = _getMonthAbbr(recordedAt.month);
    final year = recordedAt.year;
    return '$day $month $year';
  }

  /// Fecha y hora formateada (Ej: "08 Feb 2026 - 14:30")
  String get displayDateTime {
    final day = recordedAt.day.toString().padLeft(2, '0');
    final month = _getMonthAbbr(recordedAt.month);
    final year = recordedAt.year;
    final hour = recordedAt.hour.toString().padLeft(2, '0');
    final minute = recordedAt.minute.toString().padLeft(2, '0');
    return '$day $month $year - $hour:$minute';
  }

  /// Solo la fecha en formato corto (Ej: "08/02")
  String get shortDate {
    final day = recordedAt.day.toString().padLeft(2, '0');
    final month = recordedAt.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  /// Día de la semana en español
  String get dayOfWeek {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return days[(recordedAt.weekday - 1) % 7];
  }

  /// ¿Es un registro reciente? (menos de 24 horas)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(recordedAt).inHours < 24;
  }

  /// Cuántos días desde el registro
  int get daysAgo {
    final now = DateTime.now();
    return now.difference(recordedAt).inDays;
  }

  /// Texto de cuándo fue (Ej: "hace 3 días", "hoy")
  String get timeAgoText {
    if (daysAgo == 0) return 'Hoy';
    if (daysAgo == 1) return 'Ayer';
    if (daysAgo < 7) return 'hace $daysAgo días';
    if (daysAgo < 30) return 'hace ${(daysAgo / 7).toStringAsFixed(0)} semanas';
    return 'hace ${(daysAgo / 30).toStringAsFixed(0)} meses';
  }

  // 🔄 FACTORY: Convertir JSON de Supabase a WeightLogModel
  factory WeightLogModel.fromJson(Map<String, dynamic> json) {
    return WeightLogModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      weight: (json['weight'] as num).toDouble(),
      unit: (json['unit'] as String?) ?? 'kg',
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // 📤 Convertir WeightLogModel a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'weight': weight,
      'unit': unit,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 📋 JSON para INSERT (sin ID ni timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'weight': weight,
      'unit': unit,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }

  // 📋 JSON para UPDATE
  Map<String, dynamic> toUpdateJson() {
    return {
      'weight': weight,
      'unit': unit,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }

  // 📋 CopyWith para actualizar selectivamente
  WeightLogModel copyWith({
    int? id,
    String? userId,
    double? weight,
    String? unit,
    DateTime? recordedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 📊 Calcular diferencia con otro peso
  double getDifference(WeightLogModel other) {
    // Convertir ambos a la misma unidad (kg)
    final thisWeight = weightInKg;
    final otherWeight = other.weightInKg;
    return thisWeight - otherWeight;
  }

  /// ¿Bajaste de peso respecto a otro registro?
  bool isLowerThan(WeightLogModel other) {
    return getDifference(other) < 0;
  }

  /// ¿Subiste de peso respecto a otro registro?
  bool isHigherThan(WeightLogModel other) {
    return getDifference(other) > 0;
  }

  /// Obtener porcentaje de cambio
  double getPercentageChange(WeightLogModel other) {
    final otherWeightKg = other.weightInKg;
    if (otherWeightKg == 0) return 0;
    return ((weightInKg - otherWeightKg) / otherWeightKg) * 100;
  }

  /// Texto de progreso (Ej: "Bajaste 2.5 kg", "Subiste 0.5 kg")
  String getProgressText(WeightLogModel? previous) {
    if (previous == null) return 'Primer registro';
    
    final diff = getDifference(previous);
    final absDiff = diff.abs().toStringAsFixed(1);
    
    if (diff < -0.1) {
      return '📉 Bajaste $absDiff kg';
    } else if (diff > 0.1) {
      return '📈 Subiste $absDiff kg';
    } else {
      return '➡️ Sin cambios';
    }
  }

  // 📊 Información para debug
  @override
  String toString() {
    return '''WeightLogModel(
      id: $id,
      userId: $userId,
      weight: $displayWeight,
      recordedAt: $displayDate,
      daysAgo: $daysAgo
    )''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightLogModel &&
        other.id == id &&
        other.userId == userId &&
        other.weight == weight;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ weight.hashCode;
  }

  // 🛠️ HELPERS PRIVADOS

  /// Obtener abreviatura del mes en español
  String _getMonthAbbr(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return months[(month - 1) % 12];
  }
}
