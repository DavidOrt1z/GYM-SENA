import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gym_app/models/user_model.dart';
import 'package:gym_app/services/database_service.dart';
import 'package:gym_app/providers/auth_provider.dart';
import 'package:gym_app/screens/perfil/pantalla_editar_perfil.dart';
import 'package:gym_app/screens/perfil/pantalla_codigo_qr.dart';
import 'package:gym_app/screens/perfil/pantalla_unidades.dart';
import 'package:gym_app/screens/perfil/pantalla_cerrar_sesion.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _user;
  bool _isLoading = true;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserProfile();
    }
  }

  Future<void> _crearPerfilInicial({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    await Supabase.instance.client.from('users').upsert({
      'id_autenticacion': userId,
      'correo_electronico': email,
      'nombre_completo': fullName,
      'rol': 'member',
      'estado': 'active',
    }, onConflict: 'correo_electronico');
  }

  Future<void> _loadUserProfile() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id;

      if (userId != null) {
        // Intentar obtener perfil de base de datos
        final user = await _databaseService.getUserProfile(userId);

        if (user != null) {
          if (mounted) {
            debugPrint(
              'DEBUG: Usuario cargado: ${user.fullName}, Avatar: ${user.avatarUrl}',
            );
            setState(() {
              _user = user;
              _avatarUrl = user.avatarUrl;
              _isLoading = false;
            });
          }
        } else {
          // Si no existe, crear un registro con datos del auth
          final email = currentUser?.email ?? 'No disponible';
          final fullName =
              currentUser?.userMetadata?['full_name'] ?? email.split('@')[0];

          // Crear registro en BD
          await _crearPerfilInicial(
            userId: userId,
            email: email,
            fullName: fullName,
          );

          // Cargar el perfil creado
          final newUser = await _databaseService.getUserProfile(userId);
          if (mounted) {
            setState(() {
              _user = newUser;
              _avatarUrl = newUser?.avatarUrl;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: DARKER_BG,
        body: Center(child: CircularProgressIndicator(color: PRIMARY_COLOR)),
      );
    }

    if (_user == null) {
      final isEnglish = Localizations.localeOf(context).languageCode == 'en';
      return Scaffold(
        backgroundColor: DARKER_BG,
        appBar: AppBar(
          backgroundColor: DARKER_BG,
          title: Text(
            AppLocalizations.of(context, 'perfil'),
            style: const TextStyle(color: WHITE),
          ),
        ),
        body: Center(
          child: Text(
            isEnglish ? 'Error loading profile' : 'Error al cargar perfil',
            style: const TextStyle(color: WHITE),
          ),
        ),
      );
    }

    // Usa datos del auth si el perfil no cargó correctamente
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final fullName =
        _user?.fullName ??
        Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ??
        Supabase.instance.client.auth.currentUser?.email ??
        (isEnglish ? 'User' : 'Usuario');
    final role = _user?.role ?? 'member';
    final unitLabel = (_user?.units == 'imperial')
        ? 'Imperial.'
        : (isEnglish ? 'Metric.' : 'Métrico.');

    return Scaffold(
      backgroundColor: DARKER_BG,
      appBar: AppBar(
        backgroundColor: DARKER_BG,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context, 'perfil'),
          style: TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Avatar y nombre
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFE8D4B8),
                  child: ClipOval(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? Image.network(
                              '$_avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: PRIMARY_COLOR,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 48,
                                      color: Color(0xFF6B5D4F),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: Color(0xFF6B5D4F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(
                    color: WHITE,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role == 'admin'
                      ? (isEnglish ? 'Administrator' : 'Administrador')
                      : (isEnglish ? 'User' : 'Usuario'),
                  style: const TextStyle(color: SECONDARY_COLOR, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón Editar Perfil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: _user!),
                  ),
                );
                // Siempre recargar al volver
                _loadUserProfile();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context, 'editar_perfil'),
                    style: TextStyle(
                      color: WHITE,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.edit_outlined, color: WHITE, size: 20),
                ],
              ),
            ),
          ),

          // Botón Codigo QR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QrCodeScreen()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context, 'codigo_qr'),
                    style: TextStyle(
                      color: WHITE,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.qr_code_outlined, color: WHITE, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Título: Información Básica
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isEnglish ? 'Basic Information' : 'Información Basica',
              style: TextStyle(
                color: WHITE,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Grid de información
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? 'Age' : 'Años',
                        style: const TextStyle(
                          color: SECONDARY_COLOR,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_user?.age ?? 'N/A'}',
                        style: const TextStyle(
                          color: WHITE,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context, 'peso'),
                        style: const TextStyle(
                          color: SECONDARY_COLOR,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_user?.weightKg ?? 'N/A'} kg',
                        style: const TextStyle(
                          color: WHITE,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Altura
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context, 'altura'),
                  style: const TextStyle(
                    color: SECONDARY_COLOR,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_user?.heightCm ?? 'N/A'} cm',
                  style: const TextStyle(
                    color: WHITE,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Unidades de Medida
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UnitsScreen()),
                );
                _loadUserProfile();
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: DARK_BG,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/Medidas.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEnglish ? 'Units of Measure' : 'Unidades de Medida',
                          style: TextStyle(
                            color: WHITE,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unitLabel,
                          style: TextStyle(
                            color: SECONDARY_COLOR,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: SECONDARY_COLOR,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Botón Cerrar sesión
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  context.read<AuthProvider>().logout();
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LogoutScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context, 'cerrar_sesion'),
                  style: TextStyle(
                    color: WHITE,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
