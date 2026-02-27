import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_app/models/user_model.dart';
import 'package:gym_app/models/weight_log_model.dart';
import 'package:gym_app/models/reservation_model.dart';
import 'package:gym_app/models/slot_model.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener perfil del usuario
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Actualizar perfil
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('users')
          .update(data)
          .eq('id', userId);
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
      final response = await _supabase
          .from('reservations')
          .select()
          .eq('user_id', userId)
          .order('reserved_at', ascending: false);

      return (response as List)
          .map((json) => ReservationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching user reservations: $e');
      return [];
    }
  }

  /// Obtener reserva por ID
  Future<ReservationModel?> getReservation(int reservationId) async {
    try {
      final response = await _supabase
          .from('reservations')
          .select()
          .eq('id', reservationId)
          .single();

      return ReservationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Crear nueva reserva
  Future<ReservationModel?> createReservation(String userId, int slotId) async {
    try {
      final response = await _supabase
          .from('reservations')
          .insert({
            'user_id': userId,
            'slot_id': slotId,
            'status': 'confirmed',
            'reserved_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ReservationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating reservation: $e');
      return null;
    }
  }

  /// Cancelar reserva
  Future<bool> cancelReservation(int reservationId, String reason) async {
    try {
      await _supabase
          .from('reservations')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
            'notes': reason,
          })
          .eq('id', reservationId);
      return true;
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
          .from('slots')
          .select()
          .eq('status', 'active')
          .order('day_of_week', ascending: true)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => SlotModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching available slots: $e');
      return [];
    }
  }

  /// Obtener slot por ID
  Future<SlotModel?> getSlot(int slotId) async {
    try {
      final response = await _supabase
          .from('slots')
          .select()
          .eq('id', slotId)
          .single();

      return SlotModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Incrementar reservas en un slot
  Future<bool> incrementSlotReservations(int slotId) async {
    try {
      final slot = await getSlot(slotId);
      if (slot != null) {
        await _supabase
            .from('slots')
            .update({'reserved_count': slot.reservedCount + 1})
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
  Future<bool> decrementSlotReservations(int slotId) async {
    try {
      final slot = await getSlot(slotId);
      if (slot != null && slot.reservedCount > 0) {
        await _supabase
            .from('slots')
            .update({'reserved_count': slot.reservedCount - 1})
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
      final response = await _supabase
          .from('weight_logs')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: true);

      return (response as List)
          .map((json) => WeightLogModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching weight logs: $e');
      return [];
    }
  }

  /// Agregar nuevo registro de peso
  Future<WeightLogModel?> addWeightLog(String userId, double weight, String unit) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('weight_logs')
          .insert({
            'user_id': userId,
            'weight': weight,
            'unit': unit,
            'recorded_at': now.toIso8601String(),
          })
          .select()
          .single();

      return WeightLogModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error adding weight log: $e');
      return null;
    }
  }

  /// Actualizar registro de peso
  Future<bool> updateWeightLog(int logId, double weight, String unit) async {
    try {
      await _supabase
          .from('weight_logs')
          .update({
            'weight': weight,
            'unit': unit,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', logId);
      return true;
    } catch (e) {
      print('Error updating weight log: $e');
      return false;
    }
  }

  /// Eliminar registro de peso
  Future<bool> deleteWeightLog(int logId) async {
    try {
      await _supabase
          .from('weight_logs')
          .delete()
          .eq('id', logId);
      return true;
    } catch (e) {
      print('Error deleting weight log: $e');
      return false;
    }
  }
}
