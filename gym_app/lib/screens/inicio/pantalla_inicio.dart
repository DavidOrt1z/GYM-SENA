import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import 'package:gym_app/services/database_service.dart';
import 'package:gym_app/screens/notificaciones/pantalla_notificaciones.dart';
import 'package:gym_app/providers/proveedor_notificaciones.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final PageController _facilitiesPageController = PageController();
  late final AnimationController _homeRevealController;
  String _firstName = '';
  int _currentFacilityIndex = 0;
  Timer? _facilitiesTimer;

  static const List<String> _facilityImages = [
    'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=1200',
    'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=1200',
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200',
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=1200',
  ];

  @override
  void initState() {
    super.initState();
    _homeRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _facilitiesTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_facilitiesPageController.hasClients) return;
      final nextIndex = (_currentFacilityIndex + 1) % _facilityImages.length;
      _facilitiesPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });

    _loadFirstName();
  }

  Future<void> _loadFirstName() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final authUserId = currentUser?.id;

    if (authUserId == null || authUserId.isEmpty) return;

    try {
      final profile = await _databaseService.getUserProfile(authUserId);
      final metadata = currentUser?.userMetadata ?? <String, dynamic>{};

      final profileFullName =
          '${profile?.nombre ?? ''} ${profile?.apellido ?? ''}'.trim();

      final fullName = profileFullName.isNotEmpty
          ? profileFullName
          : (metadata['nombre_completo']?.toString() ??
                    metadata['full_name']?.toString() ??
                    metadata['name']?.toString() ??
                    '')
                .trim();

      final firstName = _extractFirstName(fullName);
      if (!mounted) return;

      setState(() {
        _firstName = firstName;
      });
    } catch (_) {
      // Si falla, dejamos el saludo sin nombre.
    }
  }

  String _extractFirstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first.trim() : '';
  }

  String _formattedToday({required bool isEnglish}) {
    final today = DateTime.now();

    const weekdaysEs = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    const monthsEs = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    const weekdaysEn = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    const monthsEn = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];

    if (isEnglish) {
      final weekday = weekdaysEn[today.weekday - 1];
      final month = monthsEn[today.month - 1];
      return '$weekday, $month ${today.day}';
    }

    final weekday = weekdaysEs[today.weekday - 1];
    final month = monthsEs[today.month - 1];
    return '$weekday, ${today.day} de $month';
  }

  String _greetingText({required bool isEnglish}) {
    if (_firstName.isEmpty) {
      return isEnglish ? 'HELLO!' : '¡HOLA!';
    }

    final upperName = _firstName.toUpperCase();
    return isEnglish ? 'HELLO, $upperName!' : '¡HOLA, $upperName!';
  }

  Widget _buildReveal({required int order, required Widget child}) {
    final start = (order * 0.12).clamp(0.0, 0.8);
    final animation = CurvedAnimation(
      parent: _homeRevealController,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 22),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: DARKER_BG,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: DARKER_BG,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            title: Text(
              AppLocalizations.of(context, 'inicio'),
              style: const TextStyle(
                color: WHITE,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              Consumer<ProveedorNotificaciones>(
                builder: (context, provider, _) {
                  final hasUnread = provider.notificaciones.any(
                    (item) => item['abierta'] != true,
                  );

                  return IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_outlined, color: WHITE),
                        if (hasUnread)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: DARKER_BG,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );

                      if (!context.mounted) return;
                      await context
                          .read<ProveedorNotificaciones>()
                          .cargarNotificaciones();
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: WHITE),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildWelcomeHeader(context, isEnglish: isEnglish),
              _buildReveal(order: 1, child: const SizedBox(height: 16)),
              _buildReveal(order: 2, child: _buildMainBanner(context)),
              _buildReveal(order: 3, child: const SizedBox(height: 28)),
              _buildReveal(
                order: 4,
                child: _buildSectionTitle(context, 'instalaciones'),
              ),
              _buildReveal(order: 5, child: const SizedBox(height: 12)),
              _buildReveal(order: 6, child: _buildInstalacionesSection()),
              _buildReveal(order: 7, child: const SizedBox(height: 28)),
              _buildReveal(
                order: 8,
                child: _buildSectionTitle(context, 'beneficios'),
              ),
              _buildReveal(order: 9, child: const SizedBox(height: 12)),
              _buildReveal(order: 10, child: _buildBeneficiosSection(context)),
              _buildReveal(order: 11, child: const SizedBox(height: 28)),
              _buildReveal(
                order: 12,
                child: _buildSectionTitle(context, 'equipamiento'),
              ),
              _buildReveal(order: 13, child: const SizedBox(height: 12)),
              _buildReveal(order: 14, child: _buildEquipamientoSection(context)),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, {required bool isEnglish}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formattedToday(isEnglish: isEnglish),
            style: const TextStyle(
              color: PRIMARY_COLOR,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _greetingText(isEnglish: isEnglish),
            style: const TextStyle(
              color: WHITE,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              AppLocalizations.of(context, 'explore_services'),
              style: const TextStyle(
                color: WHITE,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String titleKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        AppLocalizations.of(context, titleKey),
        style: const TextStyle(
          color: WHITE,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInstalacionesSection() {
    return Column(
      children: [
        SizedBox(
          height: 178,
          child: PageView.builder(
            controller: _facilitiesPageController,
            itemCount: _facilityImages.length,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() {
                _currentFacilityIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(_facilityImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_facilityImages.length, (index) {
            final isActive = index == _currentFacilityIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive ? PRIMARY_COLOR : const Color(0xFF5C5C5C),
                borderRadius: BorderRadius.circular(9),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _facilitiesTimer?.cancel();
    _facilitiesPageController.dispose();
    _homeRevealController.dispose();
    super.dispose();
  }

  Widget _buildBeneficiosSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildBeneficioItem(
            icon: Icons.card_membership_outlined,
            title: AppLocalizations.of(context, 'free_access'),
            subtitle: AppLocalizations.of(context, 'free_access_subtitle'),
          ),
          const SizedBox(height: 12),
          _buildBeneficioItem(
            icon: Icons.access_time_outlined,
            title: AppLocalizations.of(context, 'flexible_hours'),
            subtitle: AppLocalizations.of(context, 'flexible_hours_subtitle'),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficioItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: PRIMARY_COLOR,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: WHITE, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: WHITE,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: SECONDARY_COLOR, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEquipamientoSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 36) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Primera fila - 2 items
          Row(
            children: [
              Expanded(
                child: _buildEquipamientoCard(
                  imageUrl:
                      'https://images.unsplash.com/photo-1576678927484-cc907957088c?w=400',
                  title: AppLocalizations.of(context, 'treadmills'),
                  subtitle: AppLocalizations.of(context, 'treadmills_subtitle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEquipamientoCard(
                  imageUrl:
                      'https://images.unsplash.com/photo-1638536532686-d610adfc8e5c?w=400',
                  title: AppLocalizations.of(context, 'weight_machines'),
                  subtitle: AppLocalizations.of(
                    context,
                    'weight_machines_subtitle',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda fila - 1 item
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: cardWidth,
              child: _buildEquipamientoCard(
                imageUrl:
                    'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400',
                title: AppLocalizations.of(context, 'free_weights'),
                subtitle: AppLocalizations.of(context, 'free_weights_subtitle'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipamientoCard({
    required String imageUrl,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: WHITE,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12),
        ),
      ],
    );
  }
}
