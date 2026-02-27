import 'package:flutter/material.dart';
import 'package:gym_app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      _isAuthenticated = response.user != null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      
      print('Error en login: $errorMsg'); // Para debug
      
      if (errorMsg.contains('Invalid login credentials')) {
        _errorMessage = 'Email o contraseña incorrectos';
      } else if (errorMsg.contains('Email not confirmed')) {
        _errorMessage = 'Por favor confirma tu email';
      } else if (errorMsg.contains('User not found')) {
        _errorMessage = 'Usuario no encontrado';
      } else if (errorMsg.contains('invalid_grant')) {
        _errorMessage = 'Email o contraseña incorrectos';
      } else {
        _errorMessage = 'Error: ${errorMsg.split('\n').first.replaceAll('Exception: ', '')}';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Registro
  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      _isAuthenticated = response.user != null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Procesar mensajes de error para hacerlos más amigables
      String errorMsg = e.toString();
      
      print('Error completo de registro: $errorMsg'); // Para debug
      
      if (errorMsg.contains('Password should be at least 8 characters')) {
        _errorMessage = 'La contraseña debe tener mínimo 8 caracteres';
      } else if (errorMsg.contains('already_registered') || errorMsg.contains('User already registered')) {
        _errorMessage = 'Este email ya está registrado';
      } else if (errorMsg.contains('invalid_credentials')) {
        _errorMessage = 'Email o contraseña inválidos';
      } else if (errorMsg.contains('duplicate')) {
        _errorMessage = 'Este email ya existe en el sistema';
      } else if (errorMsg.contains('email')) {
        _errorMessage = 'El email no es válido';
      } else {
        // Mostrar un extracto del error real para debug
        _errorMessage = 'Error: ${errorMsg.split('\n').first.replaceAll('Exception: ', '')}';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.signOut();
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Check auth state
  Future<void> checkAuthState() async {
    final user = _authService.currentUser;
    _isAuthenticated = user != null;
    notifyListeners();
  }
}
