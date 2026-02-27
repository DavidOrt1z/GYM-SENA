class ReservationModel {
  final int id;
  final String userId;          // ID del usuario que hace la reserva
  final int slotId;             // ID del horario (slot)
  final String status;          // "confirmed", "cancelled", "completed", "no_show"
  final String? qrToken;        // Token QR para check-in
  final DateTime reservedAt;    // Cuándo se hizo la reserva
  final DateTime? cancelledAt;  // Cuándo se canceló (si aplica)
  final DateTime? completedAt;  // Cuándo se completó (si aplica)
  final String? notes;          // Notas adicionales
  final DateTime createdAt;
  final DateTime updatedAt;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.status,
    this.qrToken,
    required this.reservedAt,
    this.cancelledAt,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ PROPIEDADES CALCULADAS

  /// ¿La reserva está confirmada?
  bool get isConfirmed => status == 'confirmed';

  /// ¿Fue cancelada?
  bool get isCancelled => status == 'cancelled';

  /// ¿Fue completada?
  bool get isCompleted => status == 'completed';

  /// ¿No asistió?
  bool get isNoShow => status == 'no_show';

  /// ¿Está activa? (confirmada y no cancelada)
  bool get isActive => status == 'confirmed';

  /// Texto del estado en español
  String get statusText {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      case 'completed':
        return 'Completada';
      case 'no_show':
        return 'No asistió';
      default:
        return 'Desconocido';
    }
  }

  /// Color del estado (para UI)
  String get statusColor {
    switch (status) {
      case 'confirmed':
        return '#1273D4'; // Azul
      case 'cancelled':
        return '#D32F2F'; // Rojo
      case 'completed':
        return '#388E3C'; // Verde
      case 'no_show':
        return '#FF9800'; // Naranja
      default:
        return '#91ADC9'; // Gris
    }
  }

  /// Cuántos días faltan para la reserva
  int get daysUntilReservation {
    final now = DateTime.now();
    return reservedAt.difference(now).inDays;
  }

  /// ¿Fue hace poco? (menos de 1 hora)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inMinutes;
    return difference < 60;
  }

  /// Información formateada para mostrar
  String get displayReservationDate {
    final day = _getDayName(reservedAt.weekday);
    final date = reservedAt.day;
    final month = _getMonthName(reservedAt.month);
    return '$day, $date de $month';
  }

  // 🔄 FACTORY: Convertir JSON de Supabase a ReservationModel
  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      slotId: json['slot_id'] as int,
      status: (json['status'] as String?) ?? 'confirmed',
      qrToken: json['qr_token'] as String?,
      reservedAt: DateTime.parse(json['reserved_at'] as String),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // 📤 Convertir ReservationModel a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'slot_id': slotId,
      'status': status,
      'qr_token': qrToken,
      'reserved_at': reservedAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 📋 JSON para INSERT (sin ID ni timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'slot_id': slotId,
      'status': 'confirmed',
      'reserved_at': reservedAt.toIso8601String(),
      'notes': notes,
    };
  }

  // 📋 JSON para UPDATE
  Map<String, dynamic> toUpdateJson() {
    return {
      'status': status,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  // 📋 CopyWith para actualizar selectivamente
  ReservationModel copyWith({
    int? id,
    String? userId,
    int? slotId,
    String? status,
    String? qrToken,
    DateTime? reservedAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      slotId: slotId ?? this.slotId,
      status: status ?? this.status,
      qrToken: qrToken ?? this.qrToken,
      reservedAt: reservedAt ?? this.reservedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 🔄 Cancelar la reserva
  ReservationModel cancel({String? reason}) {
    return copyWith(
      status: 'cancelled',
      cancelledAt: DateTime.now(),
      notes: reason ?? 'Cancelada por el usuario',
      updatedAt: DateTime.now(),
    );
  }

  // ✅ Marcar como completada
  ReservationModel markAsCompleted() {
    return copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ❌ Marcar como no asistió
  ReservationModel markAsNoShow() {
    return copyWith(
      status: 'no_show',
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // 📊 Información para debug
  @override
  String toString() {
    return '''ReservationModel(
      id: $id,
      userId: $userId,
      slotId: $slotId,
      status: $status,
      reservedAt: $reservedAt,
      qrToken: $qrToken
    )''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReservationModel &&
        other.id == id &&
        other.userId == userId &&
        other.slotId == slotId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ slotId.hashCode;
  }

  // 🛠️ HELPERS PRIVADOS

  /// Obtener nombre del día en español (Lunes a Viernes)
  String _getDayName(int weekday) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
    ];
    final index = (weekday - 1) % 5;
    return index < days.length ? days[index] : 'Desconocido';
  }

  /// Obtener nombre del mes en español (Febrero a Diciembre)
  String _getMonthName(int month) {
    const months = [
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    // Mes 1 = Febrero (índice 0), Mes 12 = Diciembre (índice 10)
    if (month >= 2 && month <= 12) {
      return months[month - 2];
    }
    return 'Mes no disponible';
  }
}
