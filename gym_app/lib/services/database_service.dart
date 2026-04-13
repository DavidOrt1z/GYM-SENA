import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_app/models/user_model.dart';
import 'package:gym_app/models/weight_log_model.dart';
import 'package:gym_app/models/reservation_model.dart';
import 'package:gym_app/models/slot_model.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

      PostgrestException? lastError;

      for (final candidateId in userIds) {
        try {
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

      return (response as List)
          .map((json) => WeightLogModel.fromJson(json as Map<String, dynamic>))
          .toList();
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
