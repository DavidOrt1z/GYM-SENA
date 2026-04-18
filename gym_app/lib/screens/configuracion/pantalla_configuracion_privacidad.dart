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
        centerTitle: true,
        title: Text(
          isEnglish ? 'Privacy Settings' : 'Configuración de Privacidad',
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
            _buildSectionTitle(
              isEnglish ? 'Account privacy' : 'Privacidad de la cuenta',
            ),
            const SizedBox(height: 12),
            _buildToggleItem(
              title: isEnglish
                  ? 'Profile visibility'
                  : 'Visibilidad del perfil',
              subtitle: isEnglish
                  ? 'Control who can view your profile information and activity within the gym.'
                  : 'Controla quién puede ver la información y la actividad de tu perfil dentro del gimnasio.',
              value: _profileVisibility,
              onChanged: (value) {
                setState(() {
                  _profileVisibility = value;
                });
              },
            ),
            _buildToggleItem(
              title: isEnglish
                  ? 'Personalized content'
                  : 'Contenido personalizado',
              subtitle: isEnglish
                  ? 'Allow your data to be used to provide personalized recommendations based on your progress and routines.'
                  : 'Permite que tus datos se utilicen para ofrecerte recomendaciones personalizadas según tu progreso y rutinas.',
              value: _personalizedContent,
              onChanged: (value) {
                setState(() {
                  _personalizedContent = value;
                });
              },
            ),
            _buildToggleItem(
              title: isEnglish ? 'Share data' : 'Compartir datos',
              subtitle: isEnglish
                  ? 'Enable or disable sharing your training data with authorized instructors or coordinators.'
                  : 'Activa o desactiva el uso compartido de tus datos de entrenamiento con instructores o coordinadores autorizados.',
              value: _shareData,
              onChanged: (value) {
                setState(() {
                  _shareData = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // PREFERENCIAS DE COMUNICACIÓN
            _buildSectionTitle(
              isEnglish
                  ? 'Communication preferences'
                  : 'Preferencias de comunicación',
            ),
            const SizedBox(height: 12),
            _buildToggleItem(
              title: isEnglish
                  ? 'Community notifications'
                  : 'Notificaciones de la comunidad',
              subtitle: isEnglish
                  ? 'Get alerts about events, group classes, or SENA institutional activities.'
                  : 'Obtén alertas sobre eventos, clases grupales o actividades institucionales del SENA.',
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
                  style: const TextStyle(color: SECONDARY_COLOR, fontSize: 12),
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
}
