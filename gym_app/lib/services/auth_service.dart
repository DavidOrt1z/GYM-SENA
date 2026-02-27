import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

      // Crear registro en tabla users (si falla, no bloquear el registro)
      if (response.user != null) {
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'role': 'member',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (dbError) {
          print('Error creando perfil en BD: $dbError');
          // Si falla el insert en la tabla, el usuario ya está en Auth
          // El perfil se creará cuando entre a ProfileScreen
        }
      }

      return response;
    } catch (e) {
      print('Error en el registro: $e');
      rethrow;
    }
  }

  // Login
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
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
        emailRedirectTo: null, // Esto fuerza el envío de código OTP en lugar de link
      );
    } catch (e) {
      print('Error enviando OTP: $e');
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
      print('Error verificando OTP: $e');
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
      print('Error actualizando contraseña: $e');
      rethrow;
    }
  }
}
