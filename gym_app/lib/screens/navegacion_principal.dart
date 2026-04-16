import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:gym_app/screens/inicio/pantalla_inicio.dart';
import 'package:gym_app/screens/reservas/pantalla_reservas.dart';
import 'package:gym_app/screens/progreso/pantalla_progreso.dart';
import 'package:gym_app/screens/perfil/pantalla_perfil.dart';
import 'package:gym_app/utils/constants.dart';
import 'package:gym_app/providers/proveedor_notificaciones.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialMessage;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialMessage,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  // ✅ Fondo solicitado para la barra
  static const Color _navBg = Color(0xFF192633);

  final List<Widget> _screens = const [
    HomeScreen(),
    ReservationsScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _screens.length - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProveedorNotificaciones>().inicializar();
    });

    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialMessage!),
            backgroundColor: PRIMARY_COLOR,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  BottomNavigationBarItem _item({
    required String label,
    required String iconPath,
    required String activeIconPath,
  }) {
    Widget svg(String path) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SvgPicture.asset(path, width: 20, height: 20),
    );

    return BottomNavigationBarItem(
      icon: svg(iconPath),
      activeIcon: svg(activeIconPath),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ mantiene el estado de cada pantalla al cambiar tabs
      body: IndexedStack(index: _selectedIndex, children: _screens),

      bottomNavigationBar: Theme(
        // ✅ quita el splash/highlight feo al tocar
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          color: _navBg,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 90,
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                type: BottomNavigationBarType.fixed,
                backgroundColor: _navBg,
                elevation: 0,

                selectedItemColor: WHITE,
                unselectedItemColor: SECONDARY_COLOR,

                showSelectedLabels: true,
                showUnselectedLabels: true,

                selectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),

                enableFeedback: true,

                onTap: (index) => setState(() => _selectedIndex = index),

                items: [
                  _item(
                    label: 'Inicio',
                    iconPath: 'assets/icons/Inicio gris.svg',
                    activeIconPath: 'assets/icons/Inicio Blanco.svg',
                  ),
                  _item(
                    label: 'Reservas',
                    iconPath: 'assets/icons/Reservas gris.svg',
                    activeIconPath: 'assets/icons/Reservas Blanco.svg',
                  ),
                  _item(
                    label: 'Progreso',
                    iconPath: 'assets/icons/Progreso Gris.svg',
                    activeIconPath: 'assets/icons/Progreso Blanco.svg',
                  ),
                  _item(
                    label: 'Perfil',
                    iconPath: 'assets/icons/Perfil Gris.svg',
                    activeIconPath: 'assets/icons/Perfil Blanco.svg',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
