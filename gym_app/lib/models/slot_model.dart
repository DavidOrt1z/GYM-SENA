class SlotModel {
  final String id;
  final int gymId;
  final int dayOfWeek;      // 0=Lunes, 1=Martes, 2=Miércoles, 3=Jueves, 4=Viernes, 5=Sábado, 6=Domingo
  final String startTime;   // Formato: "06:30"
  final String endTime;     // Formato: "07:30"
  final int capacity;       // Capacidad máxima de personas
  final int reservedCount;  // Cuántas personas ya se reservaron
  final String status;      // "active", "inactive", "maintenance"
  final DateTime createdAt;
  final DateTime updatedAt;

  SlotModel({
    required this.id,
    required this.gymId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.reservedCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ PROPIEDADES CALCULADAS
  
  /// Espacios disponibles = capacidad - reservados
  int get availableSpots => capacity - reservedCount;
  
  /// ¿Hay espacios disponibles?
  bool get isAvailable => availableSpots > 0 && status == 'active';
  
  /// ¿Está lleno?
  bool get isFull => reservedCount >= capacity;
  
  /// Nombre del día en español
  String get dayName {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return days[dayOfWeek % 7];
  }
  
  /// Porcentaje de ocupación (0-100)
  double get occupancyPercentage {
    if (capacity == 0) return 0;
    return (reservedCount / capacity) * 100;
  }
  
  /// Texto de disponibilidad
  String get availabilityText {
    if (!isAvailable) return 'Agotado';
    return '$availableSpots de $capacity disponibles';
  }
  
  /// Información formateada para mostrar
  String get displayTime => '$startTime - $endTime';
  
  /// Formato de hora con AM/PM (Ej: "6:30 - 7:30 AM")
  String get displayTimeWithPeriod {
    try {
      // Parse start time
      final startParts = startTime.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = startParts[1];
      
      // Parse end time
      final endParts = endTime.split(':');
      final endHour = int.parse(endParts[0]);
      final endMinute = endParts[1];
      
      // Convertir a formato 12 horas
      final startHour12 = startHour > 12 ? startHour - 12 : (startHour == 0 ? 12 : startHour);
      final endHour12 = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);
      
      final startPeriod = startHour >= 12 ? 'PM' : 'AM';
      final endPeriod = endHour >= 12 ? 'PM' : 'AM';
      
      // Si el horario no cambia de período, mostrar solo una vez al final
      if (startPeriod == endPeriod) {
        return '$startHour12:$startMinute - $endHour12:$endMinute $endPeriod';
      } else {
        return '$startHour12:$startMinute $startPeriod - $endHour12:$endMinute $endPeriod';
      }
    } catch (e) {
      return '$startTime - $endTime';
    }
  }
  
  /// Formato de lugares disponibles (Ej: "4/7 lugares disponibles")
  String get placesText {
    final available = availableSpots;
    return '$available/$capacity lugares disponibles';
  }

  // 🔄 FACTORY: Convertir JSON de Supabase a SlotModel
  factory SlotModel.fromJson(Map<String, dynamic> json) {
    final fecha = DateTime.parse(json['fecha'] as String);
    final startRaw = (json['hora_inicio'] ?? '').toString();
    final endRaw = (json['hora_fin'] ?? '').toString();
    final start = startRaw.length >= 5 ? startRaw.substring(0, 5) : startRaw;
    final end = endRaw.length >= 5 ? endRaw.substring(0, 5) : endRaw;

    return SlotModel(
      id: json['id'].toString(),
      gymId: (json['gym_id'] as int?) ?? 1,
      dayOfWeek: fecha.weekday - 1,
      startTime: start,
      endTime: end,
      capacity: (json['capacidad'] as int?) ?? 0,
      reservedCount: (json['cantidad_reservada'] as int?) ?? 0,
      status: (json['estado'] as String?) ?? 'active',
      createdAt: DateTime.parse((json['fecha_creacion'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse((json['fecha_actualizacion'] ?? json['fecha_creacion'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  // 📤 Convertir SlotModel a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': DateTime.now().toIso8601String().split('T').first,
      'hora_inicio': startTime,
      'hora_fin': endTime,
      'capacidad': capacity,
      'cantidad_reservada': reservedCount,
      'fecha_creacion': createdAt.toIso8601String(),
      'fecha_actualizacion': updatedAt.toIso8601String(),
    };
  }

  // 📋 JSON para UPDATE sin timestamps
  Map<String, dynamic> toUpdateJson() {
    return {
      'hora_inicio': startTime,
      'hora_fin': endTime,
      'capacidad': capacity,
      'cantidad_reservada': reservedCount,
    };
  }

  // 📋 CopyWith para actualizar selectivamente
  SlotModel copyWith({
    String? id,
    int? gymId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? capacity,
    int? reservedCount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SlotModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      capacity: capacity ?? this.capacity,
      reservedCount: reservedCount ?? this.reservedCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 🔄 Incrementar contador de reservados
  SlotModel incrementReserved() {
    return copyWith(
      reservedCount: reservedCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  // 🔄 Decrementar contador de reservados (para cancelar)
  SlotModel decrementReserved() {
    final newCount = (reservedCount - 1).clamp(0, capacity);
    return copyWith(
      reservedCount: newCount,
      updatedAt: DateTime.now(),
    );
  }

  // 📊 Información para debug
  @override
  String toString() {
    return '''SlotModel(
      id: $id,
      dayOfWeek: $dayOfWeek ($dayName),
      time: $displayTime,
      capacity: $capacity,
      reserved: $reservedCount,
      available: $availableSpots,
      status: $status
    )''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SlotModel &&
        other.id == id &&
        other.dayOfWeek == dayOfWeek &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        dayOfWeek.hashCode ^
        startTime.hashCode ^
        endTime.hashCode;
  }
}
