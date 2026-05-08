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
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();
  String _documentType = 'dni';
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String get _selectedDocumentLabel {
    switch (_documentType) {
      case 'cc':
        return 'Cédula de Ciudadanía';
      case 'ti':
        return 'Tarjeta de Identidad';
      case 'ce':
        return 'Cédula de Extranjería';
      case 'ppt':
        return 'Permiso por Protección Temporal';
      default:
        return 'DNI';
    }
  }

  List<MapEntry<String, String>> get _documentTypes => const [
    MapEntry('dni', 'DNI'),
    MapEntry('cc', 'Cédula de Ciudadanía'),
    MapEntry('ti', 'Tarjeta de Identidad'),
    MapEntry('ce', 'Cédula de Extranjería'),
    MapEntry('ppt', 'Permiso por Protección Temporal'),
  ];

  Future<void> _showDocumentTypeSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DARK_BG,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tipo de documento',
                        style: TextStyle(
                          color: WHITE,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: SECONDARY_COLOR),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._documentTypes.map((item) {
                  final isSelected = item.key == _documentType;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, item.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? PRIMARY_COLOR.withValues(alpha: 0.13)
                              : const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? PRIMARY_COLOR : const Color(0xFF262626),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.value,
                                style: TextStyle(
                                  color: isSelected ? WHITE : SECONDARY_COLOR,
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: isSelected ? PRIMARY_COLOR : SECONDARY_COLOR,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() => _documentType = selected);
  }

  Widget _buildDocumentTypeSelector(bool isEnglish) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _showDocumentTypeSheet,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isEnglish ? 'Document type' : 'Tipo de documento',
          labelStyle: const TextStyle(
            color: SECONDARY_COLOR,
            fontSize: 14,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: DARK_BG,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SECONDARY_COLOR, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SECONDARY_COLOR, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PRIMARY_COLOR, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedDocumentLabel,
                style: const TextStyle(color: WHITE, fontSize: 16),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: SECONDARY_COLOR, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final cedula = _cedulaController.text.trim();
    if (cedula.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = isEnglish
            ? 'Please complete all fields'
            : 'Completa todos los campos';
      });
      return;
    }

    if (!RegExp(r'^\d{6,15}$').hasMatch(cedula)) {
      setState(() {
        _errorMessage = isEnglish
            ? 'Enter a valid ID number'
            : 'Ingresa una cédula válida';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    var didNavigate = false;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        cedula,
        _passwordController.text,
      );

      if (success && mounted) {
        didNavigate = true;
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
      if (!mounted) return;
      setState(() {
        _errorMessage = AppErrorMessages.map(
          e,
          fallback: isEnglish
              ? 'Could not sign in. Please try again.'
              : 'No se pudo iniciar sesión. Intenta nuevamente',
        );
      });
    } finally {
      if (mounted && !didNavigate) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

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
                    color: ERROR_COLOR.withValues(alpha: 0.15),
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

              _buildDocumentTypeSelector(isEnglish),
              const SizedBox(height: 16),

              // Cedula TextField
              TextField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: WHITE, fontSize: 16),
                decoration: InputDecoration(
                  hintText: isEnglish ? 'Document number' : _selectedDocumentLabel,
                  hintStyle: const TextStyle(
                    color: SECONDARY_COLOR,
                    fontSize: 14,
                  ),
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
                  disabledBackgroundColor: PRIMARY_COLOR.withValues(alpha: 0.5),
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
