import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_app/providers/auth_provider.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:gym_app/utils/error_messages.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import 'pantalla_olvide_contrasena.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = isEnglish
            ? 'Please complete all fields'
            : 'Completa todos los campos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        // Login exitoso, navegar al home
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (mounted) {
        // Si falla, mostrar el error del provider
        setState(() {
          _errorMessage =
              authProvider.errorMessage ??
              (isEnglish ? 'Login error' : 'Error al iniciar sesión');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppErrorMessages.map(
          e,
          fallback: isEnglish
              ? 'Could not sign in. Please try again.'
              : 'No se pudo iniciar sesión. Intenta nuevamente',
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      appBar: AppBar(
        backgroundColor: DARKER_BG,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WHITE),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context, 'iniciar_sesion'),
          style: const TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Título principal
              Text(
                AppLocalizations.of(context, 'bienvenido'),
                style: const TextStyle(
                  color: WHITE,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Mensaje de error
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ERROR_COLOR.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ERROR_COLOR),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: ERROR_COLOR, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: ERROR_COLOR, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 20),

              // Email TextField
              TextField(
                controller: _emailController,
                style: const TextStyle(color: WHITE, fontSize: 16),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context, 'email'),
                  labelStyle: const TextStyle(
                    color: SECONDARY_COLOR,
                    fontSize: 14,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: SECONDARY_COLOR,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: SECONDARY_COLOR,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: PRIMARY_COLOR,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: DARK_BG,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password TextField
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: WHITE, fontSize: 16),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context, 'contrasena'),
                  labelStyle: const TextStyle(
                    color: SECONDARY_COLOR,
                    fontSize: 14,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: PRIMARY_COLOR,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: SECONDARY_COLOR,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: SECONDARY_COLOR,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: PRIMARY_COLOR,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: DARK_BG,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context, 'olvidaste_contrasena'),
                    style: const TextStyle(
                      color: PRIMARY_COLOR,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                  disabledBackgroundColor: PRIMARY_COLOR.withOpacity(0.5),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(WHITE),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context, 'ingresar'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WHITE,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
