import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _profileVisibility = false;
  bool _personalizedContent = true;
  bool _shareData = true;
  bool _communityNotifications = true;

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
          'Configuración de Privacidad',
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

            // PRIVACIDAD DE LA CUENTA
            _buildSectionTitle('Privacidad de la cuenta'),
            const SizedBox(height: 12),
            _buildToggleItem(
              title: 'Visibilidad del perfil',
              subtitle: 'Controla quién puede ver la información y la actividad de tu perfil dentro del gimnasio.',
              value: _profileVisibility,
              onChanged: (value) {
                setState(() {
                  _profileVisibility = value;
                });
              },
            ),
            _buildToggleItem(
              title: 'Contenido personalizado',
              subtitle: 'Permite que tus datos se utilicen para ofrecerte recomendaciones personalizadas según tu progreso y rutinas.',
              value: _personalizedContent,
              onChanged: (value) {
                setState(() {
                  _personalizedContent = value;
                });
              },
            ),
            _buildToggleItem(
              title: 'Compartir datos',
              subtitle: 'Activa o desactiva el uso compartido de tus datos de entrenamiento con instructores o coordinadores autorizados.',
              value: _shareData,
              onChanged: (value) {
                setState(() {
                  _shareData = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // PREFERENCIAS DE COMUNICACIÓN
            _buildSectionTitle('Preferencias de comunicación'),
            const SizedBox(height: 12),
            _buildToggleItem(
              title: 'Notificaciones de la comunidad',
              subtitle: 'Obtén alertas sobre eventos, clases grupales o actividades institucionales del SENA.',
              value: _communityNotifications,
              onChanged: (value) {
                setState(() {
                  _communityNotifications = value;
                });
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

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
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
                const SizedBox(height: 4),
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
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: PRIMARY_COLOR,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? ERROR_COLOR : WHITE,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? ERROR_COLOR : SECONDARY_COLOR,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: DARK_BG,
          title: const Text(
            '¿Eliminar cuenta?',
            style: TextStyle(color: WHITE),
          ),
          content: const Text(
            'Esta acción no se puede deshacer. Se eliminarán permanentemente tu cuenta y todos tus datos.',
            style: TextStyle(color: SECONDARY_COLOR),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: PRIMARY_COLOR),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función en desarrollo')),
                );
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: ERROR_COLOR),
              ),
            ),
          ],
        );
      },
    );
  }
}
