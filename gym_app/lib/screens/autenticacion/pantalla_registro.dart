import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_app/providers/auth_provider.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import 'pantalla_registro_exitoso.dart';
import 'pantalla_terminos_uso.dart';
import 'pantalla_politicas_privacidad.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedRegion;
  String? _selectedCenter;
  bool _isLoadingRegions = true;
  String? _regionsLoadError;
  bool _isCheckingCedula = false;
  bool _cedulaValidated = false;
  bool _cedulaAvailable = false;
  String? _cedulaValidationMessage;
  String? _validatedCedulaValue;

  Map<String, List<String>> _centersByRegion = const {};

  @override
  void initState() {
    super.initState();
    _loadRegionsAndCenters();
  }

  Future<void> _loadRegionsAndCenters() async {
    setState(() {
      _isLoadingRegions = true;
      _regionsLoadError = null;
    });

    try {
      final client = Supabase.instance.client;

      final regionsRaw = await client
          .from('regiones')
          .select('id, nombre')
          .order('nombre');

      final centersRaw = await client
          .from('centros_formacion')
          .select('regional_id, nombre_centro')
          .order('nombre_centro');

      final regions = List<Map<String, dynamic>>.from(regionsRaw);
      final centers = List<Map<String, dynamic>>.from(centersRaw);

      final regionById = <int, String>{};
      for (final row in regions) {
        final id = row['id'];
        final name = row['nombre'];
        if (id is int && name is String && name.trim().isNotEmpty) {
          regionById[id] = name.trim();
        }
      }

      final result = <String, List<String>>{};
      for (final regionName in regionById.values) {
        result[regionName] = [];
      }

      for (final row in centers) {
        final regionId = row['regional_id'];
        final centerName = row['nombre_centro'];
        if (regionId is! int || centerName is! String) continue;
        final regionName = regionById[regionId];
        if (regionName == null) continue;
        final cleanName = centerName.trim();
        if (cleanName.isEmpty) continue;
        result[regionName]!.add(cleanName);
      }

      for (final entry in result.entries) {
        entry.value.sort();
      }

      if (!mounted) return;
      setState(() {
        _centersByRegion = result;
        _isLoadingRegions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRegions = false;
        _regionsLoadError =
            'No se pudieron cargar regionales y centros. Intenta nuevamente';
      });
    }
  }

  Future<void> _pickRegion() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DARK_BG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ChecklistSelectorSheet(
          title: 'Selecciona una regional',
          options: _centersByRegion.keys.toList(),
          selected: _selectedRegion,
        );
      },
    );

    if (selected == null || selected == _selectedRegion) return;
    setState(() {
      _selectedRegion = selected;
      _selectedCenter = null;
    });
  }

  Future<void> _pickCenter() async {
    if (_selectedRegion == null) return;
    final centers = _centersByRegion[_selectedRegion] ?? [];
    if (centers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay centros disponibles para esta regional'),
          backgroundColor: PRIMARY_COLOR,
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DARK_BG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ChecklistSelectorSheet(
          title: 'Selecciona un centro',
          options: centers,
          selected: _selectedCenter,
        );
      },
    );

    if (selected == null) return;
    setState(() {
      _selectedCenter = selected;
    });
  }

  bool _validateChecklistFields() {
    if (_selectedRegion != null && _selectedCenter != null) return true;
    final message = _selectedRegion == null
        ? 'Debes seleccionar una regional'
        : 'Debes seleccionar un centro de formacion';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PRIMARY_COLOR,
      ),
    );
    return false;
  }

  Future<void> _validateCedula() async {
    final cedula = _cedulaController.text.trim();
    if (cedula.isEmpty) {
      setState(() {
        _cedulaValidated = false;
        _cedulaAvailable = false;
        _cedulaValidationMessage = 'Ingresa la cédula para validar';
        _validatedCedulaValue = null;
      });
      return;
    }

    if (!RegExp(r'^\d{6,15}$').hasMatch(cedula)) {
      setState(() {
        _cedulaValidated = false;
        _cedulaAvailable = false;
        _cedulaValidationMessage = 'La cédula debe tener entre 6 y 15 dígitos';
        _validatedCedulaValue = null;
      });
      return;
    }

    setState(() {
      _isCheckingCedula = true;
      _cedulaValidationMessage = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id, nombre, apellido')
          .eq('cedula', cedula)
          .limit(1);
      final rows = List<Map<String, dynamic>>.from(response);
      final exists = rows.isNotEmpty;

      if (!mounted) return;
      setState(() {
        _isCheckingCedula = false;
        _cedulaValidated = true;
        _validatedCedulaValue = cedula;
        _cedulaAvailable = exists;
        if (exists) {
          final user = rows.first;
          final dbName = (user['nombre'] ?? '').toString().trim();
          final dbLastName = (user['apellido'] ?? '').toString().trim();
          if (dbLastName.isNotEmpty) {
            _nameController.text = dbName;
            _lastNameController.text = dbLastName;
          } else {
            final parts = dbName.split(RegExp(r'\s+'));
            _nameController.text = parts.isNotEmpty ? parts.first : dbName;
            _lastNameController.text =
                parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }
          _cedulaValidationMessage =
              'Cédula validada. Completa los datos restantes para registrarte.';
        } else {
          _nameController.clear();
          _lastNameController.clear();
          _cedulaValidationMessage =
              'Esta cédula no está registrada. Contacta al administrador.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingCedula = false;
        _cedulaValidated = false;
        _cedulaAvailable = false;
        _validatedCedulaValue = null;
        _cedulaValidationMessage = 'No se pudo validar la cédula. Intenta nuevamente';
      });
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
          AppLocalizations.of(context, 'registrarse'),
          style: const TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                TextFormField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: WHITE),
                  onChanged: (_) {
                    setState(() {
                      _cedulaValidated = false;
                      _cedulaAvailable = false;
                      _cedulaValidationMessage = null;
                      _validatedCedulaValue = null;
                      _nameController.clear();
                      _lastNameController.clear();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Cédula',
                    labelStyle: const TextStyle(color: SECONDARY_COLOR),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SECONDARY_COLOR),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SECONDARY_COLOR),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: PRIMARY_COLOR, width: 2),
                    ),
                    filled: true,
                    fillColor: DARK_BG,
                  ),
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) {
                      return 'Por favor ingresa tu cédula';
                    }
                    if (!RegExp(r'^\d{6,15}$').hasMatch(trimmed)) {
                      return 'La cédula debe tener entre 6 y 15 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isCheckingCedula ? null : _validateCedula,
                  icon: _isCheckingCedula
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(PRIMARY_COLOR),
                          ),
                        )
                      : Icon(
                          _cedulaAvailable
                              ? Icons.verified_rounded
                              : Icons.fact_check_outlined,
                          color: PRIMARY_COLOR,
                          size: 18,
                        ),
                  label: const Text('Validar cédula'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: PRIMARY_COLOR),
                    foregroundColor: WHITE,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (_cedulaValidationMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _cedulaValidationMessage!,
                    style: TextStyle(
                      color: _cedulaAvailable ? const Color(0xFF7FD885) : Colors.red,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                if (_cedulaAvailable) ...[
                  TextFormField(
                    controller: _nameController,
                    readOnly: true,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(color: WHITE),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context, 'nombre'),
                      labelStyle: const TextStyle(color: SECONDARY_COLOR),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SECONDARY_COLOR),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SECONDARY_COLOR),
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
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Valida primero la cédula';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    readOnly: true,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(color: WHITE),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context, 'apellido'),
                      labelStyle: const TextStyle(color: SECONDARY_COLOR),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SECONDARY_COLOR),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SECONDARY_COLOR),
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
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Valida primero la cédula';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: WHITE),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context, 'email'),
                    labelStyle: const TextStyle(color: SECONDARY_COLOR),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SECONDARY_COLOR),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SECONDARY_COLOR),
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
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return isEnglish
                          ? 'Please enter your email'
                          : 'Por favor ingresa tu correo';
                    }
                    if (!value!.contains('@')) {
                      return isEnglish
                          ? 'Enter a valid email'
                          : 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _ChecklistField(
                  label: 'Regional',
                  value: _selectedRegion,
                  placeholder: _isLoadingRegions
                      ? 'Cargando regionales...'
                      : 'Selecciona una regional',
                  onTap: _isLoadingRegions || _centersByRegion.isEmpty
                      ? null
                      : _pickRegion,
                ),
                const SizedBox(height: 16),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  opacity: _selectedRegion == null ? 0.78 : 1,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    offset: _selectedRegion == null
                        ? const Offset(0, 0.02)
                        : Offset.zero,
                    child: _ChecklistField(
                      label: 'Centro de Formacion SENA',
                      value: _selectedCenter,
                      placeholder: _isLoadingRegions
                          ? 'Cargando centros...'
                          : _selectedRegion == null
                          ? 'Selecciona primero una regional'
                          : 'Selecciona un centro',
                      onTap: _isLoadingRegions || _selectedRegion == null
                          ? null
                          : _pickCenter,
                    ),
                  ),
                ),
                if (_regionsLoadError != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _regionsLoadError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadRegionsAndCenters,
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(color: PRIMARY_COLOR),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: WHITE),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context, 'contrasena'),
                    labelStyle: const TextStyle(color: SECONDARY_COLOR),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: PRIMARY_COLOR,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SECONDARY_COLOR),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SECONDARY_COLOR),
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
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return isEnglish
                          ? 'Please enter a password'
                          : 'Por favor ingresa una contraseña';
                    }
                    if (value!.length < 6) {
                      return isEnglish
                          ? 'Minimum 6 characters'
                          : 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: WHITE),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                      'confirmar_contrasena',
                    ),
                    labelStyle: const TextStyle(color: SECONDARY_COLOR),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: PRIMARY_COLOR,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SECONDARY_COLOR),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SECONDARY_COLOR),
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
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return isEnglish
                          ? 'Please confirm your password'
                          : 'Por favor confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return isEnglish
                          ? 'Passwords do not match'
                          : 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Register Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                if (!_validateChecklistFields()) return;
                                final currentCedula = _cedulaController.text.trim();
                                final isCedulaReady =
                                    _cedulaValidated &&
                                    _cedulaAvailable &&
                                    _validatedCedulaValue == currentCedula;
                                if (!isCedulaReady) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Debes validar una cédula disponible antes de registrarte',
                                      ),
                                      backgroundColor: PRIMARY_COLOR,
                                    ),
                                  );
                                  return;
                                }
                                final success = await authProvider.register(
                                  _emailController.text.trim(),
                                  _passwordController.text,
                                  _nameController.text.trim(),
                                  _lastNameController.text.trim(),
                                  currentCedula,
                                );
                                if (!mounted) return;
                                if (success) {
                                  Navigator.of(this.context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SuccessScreen(),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PRIMARY_COLOR,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  WHITE,
                                ),
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context, 'registrarse'),
                              style: const TextStyle(
                                color: WHITE,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),

                // Error message
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    if (authProvider.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 12),

                // Política de Privacidad y Términos de uso
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        color: SECONDARY_COLOR,
                        fontSize: 11,
                      ),
                      children: [
                        TextSpan(
                          text: AppLocalizations.of(context, 'acepto_terminos'),
                        ),
                        TextSpan(
                          text: AppLocalizations.of(
                            context,
                            'politicas_privacidad',
                          ),
                          style: const TextStyle(
                            color: PRIMARY_COLOR,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                        ),
                        const TextSpan(text: ' y '),
                        TextSpan(
                          text: AppLocalizations.of(context, 'terminos_uso'),
                          style: const TextStyle(
                            color: PRIMARY_COLOR,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TermsOfUseScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _cedulaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class _ChecklistField extends StatelessWidget {
  const _ChecklistField({
    required this.label,
    required this.placeholder,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String placeholder;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SECONDARY_COLOR,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 56,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: DARK_BG,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value != null
                      ? PRIMARY_COLOR
                      : (isEnabled ? SECONDARY_COLOR : SECONDARY_COLOR),
                  width: value != null ? 1.6 : 1,
                ),
              ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    value == null
                        ? Icons.checklist_rounded
                        : Icons.check_circle_rounded,
                    key: ValueKey<bool>(value != null),
                    color: isEnabled ? PRIMARY_COLOR : SECONDARY_COLOR,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      value ?? placeholder,
                      key: ValueKey<String>(value ?? placeholder),
                      style: TextStyle(
                        color: value == null ? SECONDARY_COLOR : WHITE,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isEnabled ? WHITE : SECONDARY_COLOR,
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistSelectorSheet extends StatelessWidget {
  const _ChecklistSelectorSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<String> options;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: WHITE,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              itemCount: options.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == selected;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 160 + (index * 35)),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 8),
                        child: child,
                      ),
                    );
                  },
                  child: InkWell(
                    onTap: () => Navigator.pop(context, option),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? PRIMARY_COLOR : SECONDARY_COLOR,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: isSelected ? PRIMARY_COLOR : SECONDARY_COLOR,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(
                                color: WHITE,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
