import 'package:flutter/material.dart';
import 'package:gym_app/services/auth_service.dart';
import 'package:gym_app/utils/constants.dart';
import 'pantalla_contrasena_actualizada.dart';

class ResetNewPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetNewPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetNewPasswordScreen> createState() => _ResetNewPasswordScreenState();
}

class _ResetNewPasswordScreenState extends State<ResetNewPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _resetPassword() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = isEnglish
            ? 'Passwords do not match'
            : 'Las contraseñas no coinciden';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Actualizar la contraseña del usuario ya autenticado
      await _authService.updatePassword(_newPasswordController.text);

      if (mounted) {
        // Navegar a la pantalla de éxito
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PasswordResetSuccessScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = isEnglish
            ? 'Error updating password'
            : 'Error al actualizar la contraseña';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      backgroundColor: DARKER_BG,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: DARKER_BG,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEnglish ? 'Reset password' : 'Restablecer contraseña',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: WHITE,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WHITE),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        isEnglish
                            ? 'Enter your new password'
                            : 'Ingresa tu nueva contraseña',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: WHITE,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        isEnglish
                            ? 'Create a secure password to protect your account'
                            : 'Crea una contraseña segura para proteger tu cuenta',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: SECONDARY_COLOR,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Nueva contraseña
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        style: const TextStyle(color: WHITE, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: isEnglish
                              ? 'New password'
                              : 'Nueva contraseña',
                          labelStyle: const TextStyle(
                            color: SECONDARY_COLOR,
                            fontSize: 14,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: PRIMARY_COLOR,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFF243244),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: SECONDARY_COLOR,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: SECONDARY_COLOR,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: PRIMARY_COLOR,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isEnglish
                                ? 'Please enter a password'
                                : 'Por favor ingresa una contraseña';
                          }
                          if (value.length < 6) {
                            return isEnglish
                                ? 'Password must be at least 6 characters'
                                : 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Confirmar contraseña
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: WHITE, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: isEnglish
                              ? 'Confirm password'
                              : 'Confirmar contraseña',
                          labelStyle: const TextStyle(
                            color: SECONDARY_COLOR,
                            fontSize: 14,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: PRIMARY_COLOR,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFF243244),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: SECONDARY_COLOR,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: SECONDARY_COLOR,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: PRIMARY_COLOR,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isEnglish
                                ? 'Please confirm your password'
                                : 'Por favor confirma tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      WHITE,
                                    ),
                                  ),
                                )
                              : Text(
                                  isEnglish ? 'Confirm' : 'Confirmar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: WHITE,
                                  ),
                                ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
