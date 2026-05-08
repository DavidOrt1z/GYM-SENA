import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _ensureUserProfile({
    required User user,
    required String email,
    required String fullName,
    String? lastName,
    String? cedula,
  }) async {
    try {
      final cleanCedula = cedula?.trim();

      if (cleanCedula != null && cleanCedula.isNotEmpty) {
        final existingByCedula = await _supabase
            .from('users')
            .select('id')
            .eq('cedula', cleanCedula)
            .maybeSingle();

        if (existingByCedula != null) {
          final Map<String, dynamic> updateData = {
            'id_autenticacion': user.id,
            'correo_electronico': email,
            'nombre': fullName,
            'cedula': cleanCedula,
            'estado': 'active',
          };
          final cleanLastName = lastName?.trim();
          if (cleanLastName != null && cleanLastName.isNotEmpty) {
            updateData['apellido'] = cleanLastName;
          }

          await _supabase
              .from('users')
              .update(updateData)
              .eq('id', existingByCedula['id']);
          return;
        }
      }

      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('correo_electronico', email)
          .maybeSingle();

      if (existingUser != null) {
        final Map<String, dynamic> updateData = {
          'id_autenticacion': user.id,
          'nombre': fullName,
          'estado': 'active',
        };
        final cleanLastName = lastName?.trim();
        if (cleanLastName != null && cleanLastName.isNotEmpty) {
          updateData['apellido'] = cleanLastName;
        }
        if (cleanCedula != null && cleanCedula.isNotEmpty) {
          updateData['cedula'] = cleanCedula;
        }

        await _supabase
            .from('users')
            .update(updateData)
            .eq('correo_electronico', email);
        return;
      }

      await _supabase.from('users').insert({
        'id_autenticacion': user.id,
        'correo_electronico': email,
        'nombre': fullName,
        'apellido': (lastName ?? '').trim(),
        'cedula': (cedula ?? '').trim(),
        'rol': 'member',
        'estado': 'active',
      });
    } catch (dbError) {
      debugPrint('Error creando perfil en BD: $dbError');
    }
  }

  // Obtener usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  // Obtener cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Registro de nuevo usuario
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String lastName,
    required String cedula,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'last_name': lastName,
          'cedula': cedula,
        },
      );

      if (response.user != null) {
        await _ensureUserProfile(
          user: response.user!,
          email: email,
          fullName: fullName,
          lastName: lastName,
          cedula: cedula,
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error en el registro: $e');
      rethrow;
    }
  }

  // Login
  Future<AuthResponse> signInWithCedula({
    required String cedula,
    required String password,
  }) async {
    try {
      final cleanCedula = cedula.trim();
      final userRecord = await _supabase
          .from('users')
          .select('correo_electronico, nombre, apellido, cedula')
          .eq('cedula', cleanCedula)
          .maybeSingle();

      if (userRecord == null) {
        throw AuthException('cedula_not_found');
      }

      final email = userRecord['correo_electronico']?.toString().trim() ?? '';
      if (email.isEmpty) {
        throw AuthException('cedula_without_email');
      }

      if (email.toLowerCase().endsWith('@gymapp.local')) {
        throw AuthException('cedula_not_linked_to_auth');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final metadataName = response.user!.userMetadata?['full_name'];
        final metadataLastName =
            response.user!.userMetadata?['last_name'] ??
            response.user!.userMetadata?['apellido'];
        final metadataCedula =
            response.user!.userMetadata?['cedula']?.toString();
        final fullName =
            (userRecord['nombre']?.toString().trim().isNotEmpty ?? false)
            ? userRecord['nombre'].toString().trim()
            : (metadataName is String && metadataName.trim().isNotEmpty)
                ? metadataName.trim()
                : email.split('@').first;
        final lastName =
            (userRecord['apellido']?.toString().trim().isNotEmpty ?? false)
            ? userRecord['apellido'].toString().trim()
            : (metadataLastName is String && metadataLastName.trim().isNotEmpty)
                ? metadataLastName.trim()
                : null;
        final cedula =
            (userRecord['cedula']?.toString().trim().isNotEmpty ?? false)
            ? userRecord['cedula'].toString().trim()
            : (metadataCedula != null && metadataCedula.trim().isNotEmpty)
                ? metadataCedula.trim()
                : null;

        await _ensureUserProfile(
          user: response.user!,
          email: email,
          fullName: fullName,
          lastName: lastName,
          cedula: cedula,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Recuperar contraseña - Enviar OTP (Código numérico)
  Future<void> resetPassword(String email) async {
    try {
      // Usar signInWithOtp con emailRedirectTo null para forzar código OTP
      // En Supabase Dashboard:
      // 1. Authentication → Providers → Email
      // 2. Desactiva "Confirm email"
      // 3. En Email OTP Length, configura a 6
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
        emailRedirectTo:
            null, // Esto fuerza el envío de código OTP en lugar de link
      );
    } catch (e) {
      debugPrint('Error enviando OTP: $e');
      rethrow;
    }
  }

  // Verificar OTP para recuperación de contraseña
  Future<AuthResponse> verifyOtpForPasswordReset({
    required String email,
    required String token,
  }) async {
    try {
      // Usar magiclink type ya que signInWithOtp envía ese tipo
      return await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.magiclink,
      );
    } catch (e) {
      debugPrint('Error verificando OTP: $e');
      rethrow;
    }
  }

  // Actualizar contraseña del usuario autenticado
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      debugPrint('Error actualizando contraseña: $e');
      rethrow;
    }
  }
}
