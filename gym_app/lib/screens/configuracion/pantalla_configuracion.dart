import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../providers/proveedor_idioma.dart';
import 'pantalla_idioma.dart';
import 'pantalla_configuracion_privacidad.dart';
import 'pantalla_centro_ayuda.dart';
import 'pantalla_contactanos.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

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
        centerTitle: true,
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // PREFERENCIAS DE LA APLICACIÓN
            _buildSectionTitle('Preferencias de la aplicación'),
            const SizedBox(height: 12),
            Consumer<ProveedorIdioma>(
              builder: (context, proveedorIdioma, _) {
                final idiomaNombre = proveedorIdioma.locale.languageCode == 'es'
                    ? 'Español'
                    : 'English';

                return _buildSettingItem(
                  iconPath: 'assets/icons/Lenguaje.svg',
                  title: 'Lenguaje',
                  subtitle: idiomaNombre,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageScreen(),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // NOTIFICACIONES
            _buildSectionTitle('Notificaciones'),
            const SizedBox(height: 12),
            _buildToggleSetting(
              iconPath: 'assets/icons/Notificacion.svg',
              title: 'Notificaciones de la aplicación',
              subtitle: 'Recibe notificaciones sobre nuevas funciones, actualizaciones .',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // PRIVACIDAD
            _buildSectionTitle('Privacidad'),
            const SizedBox(height: 12),
            _buildSettingItem(
              iconPath: 'assets/icons/Privacidad.svg',
              title: 'Configuracion de Ajustes',
              subtitle: 'Administra la configuración de privacidad de tu cuenta.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // SOPORTE
            _buildSectionTitle('Soporte'),
            const SizedBox(height: 12),
            _buildSettingItem(
              iconPath: 'assets/icons/Centro de ayuda.svg',
              title: 'Centro de Ayuda...',
              iconSize: 18,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpCenterScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              iconPath: 'assets/icons/Contactenos.svg',
              title: 'Contáctenos',
              iconSize: 14,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactUsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: WHITE,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String iconPath,
    required String title,
    String? subtitle,
    double iconSize = 16,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  iconPath,
                  width: iconSize,
                  height: iconSize,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: WHITE,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: SECONDARY_COLOR,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
    );
  }

  Widget _buildToggleSetting({
    required String iconPath,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                iconPath,
                width: 16,
                height: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: WHITE,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SECONDARY_COLOR,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: PRIMARY_COLOR,
          ),
        ],
      ),
    );
  }
}
