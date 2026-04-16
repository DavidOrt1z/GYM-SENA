import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_app/models/user_model.dart';
import 'package:gym_app/models/weight_log_model.dart';
import 'package:gym_app/models/reservation_model.dart';
import 'package:gym_app/models/slot_model.dart';
import 'package:gym_app/services/servicio_notificaciones.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ServicioNotificaciones _notificationService = ServicioNotificaciones();

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notificaciones_historial').insert({
        'usuario_id': userId,
        'titulo': title,
        'cuerpo': body,
        'tipo': type,
        'datos': data ?? <String, dynamic>{},
        'entregada': true,
        'abierta': false,
      });
    } catch (_) {
      // No romper el flujo principal de reserva por un fallo de notificacion.
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<String> _candidateUserIds(String authUserId, String? dbUserId) {
    final candidates = <String>[];
    if (dbUserId != null && dbUserId.isNotEmpty) {
      candidates.add(dbUserId);
    }
    if (authUserId.isNotEmpty && !candidates.contains(authUserId)) {
      candidates.add(authUserId);
    }
    return candidates;
  }

  Future<Map<String, dynamic>?> _safeUserQuery({
    required String column,
    required String value,
    String select = 'id',
  }) async {
    try {
      final row = await _supabase
          .from('users')
          .select(select)
          .eq(column, value)
          .maybeSingle();

      if (row == null) return null;
      return Map<String, dynamic>.from(row);
    } on PostgrestException catch (error) {
      // Si la columna no existe en este esquema, seguimos con el siguiente fallback.
      if (error.code == 'PGRST204') return null;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveDbUserId(String authUserId) async {
    try {
      final byAuthId = await _safeUserQuery(
        column: 'id_autenticacion',
        value: authUserId,
      );

      if (byAuthId != null && byAuthId['id'] != null) {
        return byAuthId['id'].toString();
      }

      final legacyById = await _safeUserQuery(column: 'id', value: authUserId);

      if (legacyById != null && legacyById['id'] != null) {
        return legacyById['id'].toString();
      }

      final authEmail = _supabase.auth.currentUser?.email;
      if (authEmail != null && authEmail.isNotEmpty) {
        final bySpanishEmail = await _safeUserQuery(
          column: 'correo_electronico',
          value: authEmail,
        );

        if (bySpanishEmail != null && bySpanishEmail['id'] != null) {
          final resolvedId = bySpanishEmail['id'].toString();
          try {
            await _supabase
                .from('users')
                .update({'id_autenticacion': authUserId})
                .eq('id', resolvedId);
          } catch (_) {}
          return resolvedId;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> _getSlotDate(String slotId) async {
    try {
      final row = await _supabase
          .from('franjas_horarias')
          .select('fecha')
          .eq('id', slotId)
          .maybeSingle();

      final rawDate = row?['fecha']?.toString();
      if (rawDate == null || rawDate.isEmpty) return null;
      return DateTime.parse(rawDate);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _hasReservationOnDate({
    required String userId,
    required DateTime targetDate,
  }) async {
    try {
      final reservations = await _supabase
          .from('reservas')
          .select('id_franja_horaria, estado')
          .eq('id_usuario', userId)
          .neq('estado', 'cancelled');

      final rows = (reservations as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (rows.isEmpty) return false;

      final slotIds = rows
          .map((item) => item['id_franja_horaria']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (slotIds.isEmpty) return false;

      final slots = await _supabase
          .from('franjas_horarias')
          .select('id, fecha')
          .inFilter('id', slotIds);

      final slotDateById = <String, DateTime>{};
      for (final item in slots as List) {
        final row = Map<String, dynamic>.from(item as Map);
        final id = row['id']?.toString();
        final rawDate = row['fecha']?.toString();
        if (id == null || rawDate == null || rawDate.isEmpty) continue;

        try {
          slotDateById[id] = DateTime.parse(rawDate);
        } catch (_) {}
      }

      for (final row in rows) {
        final slotId = row['id_franja_horaria']?.toString();
        if (slotId == null || slotId.isEmpty) continue;

        final slotDate = slotDateById[slotId];
        if (slotDate != null && _isSameDay(slotDate, targetDate)) {
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // Obtener perfil del usuario
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final byAuthId = await _safeUserQuery(
        column: 'id_autenticacion',
        value: userId,
        select: '*',
      );

      if (byAuthId != null) {
        return UserModel.fromJson(byAuthId);
      }

      final response = await _safeUserQuery(
        column: 'id',
        value: userId,
        select: '*',
      );

      if (response == null) return null;

      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Actualizar perfil
  Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _supabase.from('users').update(data).eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RESERVATIONS - Manejo de reservas
  // ═══════════════════════════════════════════════════════════════

  /// Obtener reservas del usuario
  Future<List<ReservationModel>> getUserReservations(String userId) async {
    try {
      final dbUserId = await _resolveDbUserId(userId);
      final userIds = _candidateUserIds(userId, dbUserId);
      if (userIds.isEmpty) return [];

      PostgrestException? lastError;

      for (final candidateId in userIds) {
        try {
          final response = await _supabase
              .from('reservas')
              .select()
              .eq('id_usuario', candidateId)
              .order('fecha_creacion', ascending: false);

          return (response as List)
              .map(
                (json) =>
                    ReservationModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        } on PostgrestException catch (error) {
          lastError = error;
        }
      }

      if (lastError != null) {
        print('Error fetching user reservations: $lastError');
      }
      return [];
    } catch (e) {
      print('Error fetching user reservations: $e');
      return [];
    }
  }

  /// Obtener reserva por ID
  Future<ReservationModel?> getReservation(String reservationId) async {
    try {
      final response = await _supabase
          .from('reservas')
          .select()
          .eq('id', reservationId)
          .single();

      return ReservationModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Crear nueva reserva
  Future<ReservationModel?> createReservation(
    String userId,
    String slotId,
  ) async {
    try {
      if (userId.isEmpty) {
        print('Error creating reservation: usuario autenticado no disponible');
        return null;
      }

      final dbUserId = await _resolveDbUserId(userId);
      final userIds = _candidateUserIds(userId, dbUserId);
      if (userIds.isEmpty) {
        print('Error creating reservation: no se pudo resolver id_usuario');
        return null;
      }

      final slotDate = await _getSlotDate(slotId);

      PostgrestException? lastError;

      for (final candidateId in userIds) {
        if (slotDate != null) {
          final hasReservation = await _hasReservationOnDate(
            userId: candidateId,
            targetDate: slotDate,
          );

          if (hasReservation) {
            print(
              'Error creating reservation: usuario ya tiene reserva en esa fecha',
            );
            return null;
          }
        }

        try {
          final duplicatedBySlotResponse = await _supabase
              .from('reservas')
              .select('id')
              .eq('id_usuario', candidateId)
              .eq('id_franja_horaria', slotId)
              .neq('estado', 'cancelled')
              .limit(1);

          if (duplicatedBySlotResponse is List &&
              duplicatedBySlotResponse.isNotEmpty) {
            print(
              'Error creating reservation: usuario ya tiene una reserva activa/completada en este horario',
            );
            return null;
          }

          final response = await _supabase
              .from('reservas')
              .insert({
                'id_usuario': candidateId,
                'id_franja_horaria': slotId,
                'estado': 'active',
                'token_qr': 'tmp_${DateTime.now().millisecondsSinceEpoch}',
              })
              .select()
              .single();

          try {
            final slotInfo = await _supabase
                .from('franjas_horarias')
                .select('fecha, hora_inicio, hora_fin')
                .eq('id', slotId)
                .maybeSingle();

            final fecha = slotInfo?['fecha']?.toString() ?? '';
            final horaInicio = slotInfo?['hora_inicio']?.toString() ?? '';
            final horaFin = slotInfo?['hora_fin']?.toString() ?? '';

            await _createNotification(
              userId: candidateId,
              title: 'Reserva confirmada',
              body: fecha.isNotEmpty && horaInicio.isNotEmpty
                  ? 'Tu reserva fue confirmada para $fecha, $horaInicio - $horaFin.'
                  : 'Tu reserva fue confirmada correctamente.',
              type: 'reserva_confirmada',
              data: {
                'reserva_id': response['id']?.toString(),
                'franja_id': slotId,
                'fecha': fecha,
                'hora_inicio': horaInicio,
                'hora_fin': horaFin,
              },
            );

            final reservationId = response['id']?.toString() ?? '';
            if (reservationId.isNotEmpty &&
                fecha.isNotEmpty &&
                horaInicio.isNotEmpty) {
              await _notificationService.programarRecordatorioReserva(
                reservationId: reservationId,
                fecha: fecha,
                horaInicio: horaInicio,
                horaFin: horaFin,
              );
            }
          } catch (_) {}

          return ReservationModel.fromJson(response);
        } on PostgrestException catch (error) {
          lastError = error;
          continue;
        }
      }

      if (lastError != null) {
        print('Error creating reservation: $lastError');
      }
      return null;
    } catch (e) {
      print('Error creating reservation: $e');
      return null;
    }
  }

  /// Cancelar reserva
  Future<bool> cancelReservation(String reservationId, String reason) async {
    try {
      final response = await _supabase
          .from('reservas')
          .update({
            'estado': 'cancelled',
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id', reservationId)
          .select('id, estado');

      // Si RLS bloquea el UPDATE, PostgREST puede responder sin error pero con 0 filas.
      if (response is List && response.isNotEmpty) {
        await _notificationService.cancelarRecordatorioReserva(reservationId);
        return true;
      }

      print(
        'Error cancelling reservation: no se actualizó ninguna fila para $reservationId',
      );
      return false;
    } catch (e) {
      print('Error cancelling reservation: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SLOTS - Manejo de horarios
  // ═══════════════════════════════════════════════════════════════

  /// Obtener todos los slots disponibles
  Future<List<SlotModel>> getAvailableSlots() async {
    try {
      final response = await _supabase
          .from('franjas_horarias')
          .select()
          .order('fecha', ascending: true)
          .order('hora_inicio', ascending: true);

      return (response as List)
          .map((json) => SlotModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching available slots: $e');
      return [];
    }
  }

  /// Obtener slot por ID
  Future<SlotModel?> getSlot(String slotId) async {
    try {
      final response = await _supabase
          .from('franjas_horarias')
          .select()
          .eq('id', slotId)
          .single();

      return SlotModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Incrementar reservas en un slot
  Future<bool> incrementSlotReservations(String slotId) async {
    try {
      final slot = await getSlot(slotId);
      if (slot != null) {
        await _supabase
            .from('franjas_horarias')
            .update({'cantidad_reservada': slot.reservedCount + 1})
            .eq('id', slotId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error incrementing slot reservations: $e');
      return false;
    }
  }

  /// Decrementar reservas en un slot
  Future<bool> decrementSlotReservations(String slotId) async {
    try {
      final slot = await getSlot(slotId);
      if (slot != null && slot.reservedCount > 0) {
        await _supabase
            .from('franjas_horarias')
            .update({'cantidad_reservada': slot.reservedCount - 1})
            .eq('id', slotId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error decrementing slot reservations: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WEIGHT LOGS - Manejo de registros de peso
  // ═══════════════════════════════════════════════════════════════

  /// Obtener todos los registros de peso del usuario
  Future<List<WeightLogModel>> getWeightLogs(String userId) async {
    try {
      final dbUserId = await _resolveDbUserId(userId) ?? userId;

      final response = await _supabase
          .from('registros_peso')
          .select()
          .eq('id_usuario', dbUserId)
          .order('fecha', ascending: true);

      final logs = (response as List)
          .map((json) => WeightLogModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (logs.isNotEmpty) {
        return logs;
      }

      // Fallback: si no hay historial en registros_peso,
      // usar el peso actual guardado en perfil (tabla users).
      final userRow = await _supabase
          .from('users')
          .select(
            'peso_kg, fecha_actualizacion, updated_at, fecha_creacion, created_at',
          )
          .eq('id', dbUserId)
          .maybeSingle();

      final profileWeight = (userRow?['peso_kg'] as num?)?.toDouble();
      if (profileWeight == null || profileWeight <= 0) {
        return [];
      }

      final rawDate =
          userRow?['fecha_actualizacion'] ??
          userRow?['updated_at'] ??
          userRow?['fecha_creacion'] ??
          userRow?['created_at'];

      final parsedDate = rawDate != null
          ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
          : DateTime.now();

      return [
        WeightLogModel(
          id: 'perfil-$dbUserId',
          userId: dbUserId,
          weight: profileWeight,
          unit: 'kg',
          recordedAt: parsedDate,
          notes: 'Peso base del perfil',
          createdAt: parsedDate,
          updatedAt: parsedDate,
        ),
      ];
    } catch (e) {
      print('Error fetching weight logs: $e');
      return [];
    }
  }

  /// Agregar nuevo registro de peso
  Future<WeightLogModel?> addWeightLog(
    String userId,
    double weight,
    String unit,
  ) async {
    try {
      final now = DateTime.now();
      final dbUserId = await _resolveDbUserId(userId) ?? userId;

      final response = await _supabase
          .from('registros_peso')
          .insert({
            'id_usuario': dbUserId,
            'peso_kg': weight,
            'fecha': now.toIso8601String(),
          })
          .select()
          .single();

      return WeightLogModel.fromJson(response);
    } catch (e) {
      print('Error adding weight log: $e');
      return null;
    }
  }

  /// Actualizar registro de peso
  Future<bool> updateWeightLog(String logId, double weight, String unit) async {
    try {
      await _supabase
          .from('registros_peso')
          .update({'peso_kg': weight})
          .eq('id', logId);
      return true;
    } catch (e) {
      print('Error updating weight log: $e');
      return false;
    }
  }

  /// Eliminar registro de peso
  Future<bool> deleteWeightLog(String logId) async {
    try {
      await _supabase.from('registros_peso').delete().eq('id', logId);
      return true;
    } catch (e) {
      print('Error deleting weight log: $e');
      return false;
    }
  }
}
