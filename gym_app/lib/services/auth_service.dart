import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _ensureUserProfile({
    required User user,
    required String email,
    required String fullName,
  }) async {
    try {
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('correo_electronico', email)
          .maybeSingle();

      if (existingUser != null) {
        await _supabase
            .from('users')
            .update({
              'id_autenticacion': user.id,
              'nombre_completo': fullName,
              'estado': 'active',
            })
            .eq('correo_electronico', email);
        return;
      }

      await _supabase.from('users').insert({
        'id_autenticacion': user.id,
        'correo_electronico': email,
        'nombre_completo': fullName,
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
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        await _ensureUserProfile(
          user: response.user!,
          email: email,
          fullName: fullName,
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error en el registro: $e');
      rethrow;
    }
  }

  // Login
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final metadataName = response.user!.userMetadata?['full_name'];
        final fullName =
            (metadataName is String && metadataName.trim().isNotEmpty)
            ? metadataName.trim()
            : email.split('@').first;

        await _ensureUserProfile(
          user: response.user!,
          email: email,
          fullName: fullName,
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
