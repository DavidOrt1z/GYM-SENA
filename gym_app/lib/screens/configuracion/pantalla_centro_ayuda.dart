import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import 'pantalla_gracias_retroalimentacion.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
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
        centerTitle: true,
        title: Text(
          isEnglish ? 'Help Center' : 'Centro de Ayuda',
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

            // PREGUNTAS FRECUENTES
            _buildSectionTitle(
              isEnglish ? 'Frequently Asked Questions' : 'Preguntas Frecuentes',
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildQuestionBox(
                    title: isEnglish
                        ? 'How do I reset my password?'
                        : '¿Cómo restablezco mi contraseña?',
                    onTap: () {
                      _showHelpDetail(
                        title: isEnglish
                            ? 'Reset my password'
                            : 'Restablezco mi contraseña',
                        content: isEnglish
                            ? 'If you forgot your password, follow these steps:\n\n1. On the sign in screen, tap "Forgot my password".\n\n2. Enter the email associated with your SENA account.\n\n3. Check your email and follow the link to create a new password.\n\n4. Once done, you can sign in again with your new password.\n\nNote:\nIf you do not receive the email in a few minutes, check your spam folder or contact support.'
                            : 'Si olvidaste tu contraseña, sigue estos pasos:\n\n1. En la pantalla de inicio de sesión, selecciona "Olvide mi contraseña".\n\n2. Ingresa el correo electrónico asociado a tu cuenta del SENA.\n\n3. Revisa tu correo electrónico y sigue el enlace para crear una nueva contraseña.\n\n4. Una vez completado, podrás iniciar sesión nuevamente con tu nueva clave.\n\nNota:\nSi no recibes el correo en unos minutos, revisa tu bandeja de spam o comunícate con soporte',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuestionBox(
                    title: isEnglish
                        ? 'What are the gym opening hours?'
                        : '¿Cuáles son los horarios de apertura del gym?',
                    onTap: () {
                      _showHelpDetail(
                        title: isEnglish
                            ? 'Opening hours'
                            : 'Horario de apertura',
                        content: isEnglish
                            ? 'Weekdays\n\nMorning\nMonday to Friday: 6:30 AM to 10:00 AM\n\nAfternoon\nMonday to Friday: 3:00 PM to 5:00 PM'
                            : 'Días de la semana\n\nMañana\nLunes a Viernes: 6:30 AM hasta las 10:00 AM\n\nTarde\nLunes a Viernes: 3:00 PM hasta las 5:00 PM',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuestionBox(
                    title: isEnglish
                        ? 'How can I update my profile information?'
                        : '¿Cómo puedo actualizar la información de mi perfil?',
                    onTap: () {
                      _showHelpDetail(
                        title: isEnglish
                            ? 'Update my profile information'
                            : 'Actualizar la información de mi perfil',
                        content: isEnglish
                            ? 'To update your profile, follow these steps:\n\n1. In the bottom menu, select "Profile".\n\n2. Tap the "Edit profile" icon or button.\n\n3. Update the fields you want (first name, last name, age, etc.).\n\n4. Tap "Save changes" to confirm.\n\nTip:\nKeep your information updated to receive notifications and reminders correctly.'
                            : 'Si olvidaste tu contraseña, sigue estos pasos:\n\n1. En el menú inferior, selecciona "Perfil"\n\n2. Toca el icono o botón de "Editar perfil".\n\n3. Actualiza los campos que desees (nombre, apellido, años, etc.).\n\n4. Pulsa "Guardar cambios" para confirmar.\n\nConsejo:\nMantén tu información actualizada para recibir notificaciones y recordatorios correctamente.',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // INFORMAR UN PROBLEMA
            _buildSectionTitle(
              isEnglish
                  ? 'Report a problem or provide feedback'
                  : 'Informar un problema o proporcionar comentarios',
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _feedbackController,
                    maxLines: 5,
                    style: const TextStyle(color: WHITE),
                    decoration: InputDecoration(
                      hintText: isEnglish
                          ? 'Tell us what you think...'
                          : 'Cuéntanos lo que piensas...',
                      hintStyle: const TextStyle(color: SECONDARY_COLOR),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DARK_BG),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DARK_BG, width: 1),
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
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _sendFeedback();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PRIMARY_COLOR,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEnglish ? 'Send' : 'Enviar',
                        style: TextStyle(
                          color: WHITE,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildHelpItem({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: WHITE,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: SECONDARY_COLOR, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBox({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: SECONDARY_COLOR.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: SECONDARY_COLOR,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: SECONDARY_COLOR, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: PRIMARY_COLOR, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: WHITE,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: SECONDARY_COLOR,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: SECONDARY_COLOR, size: 24),
          ],
        ),
      ),
    );
  }

  void _showHelpDetail({required String title, required String content}) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: DARK_BG,
          title: Text(
            title,
            style: const TextStyle(color: WHITE, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(
                color: SECONDARY_COLOR,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isEnglish ? 'Close' : 'Cerrar',
                style: TextStyle(color: PRIMARY_COLOR),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendFeedback() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (_feedbackController.text.isEmpty) {
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEnglish
                    ? 'Please sign in to send feedback'
                    : 'Por favor inicia sesión para enviar feedback',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await Supabase.instance.client.from('comentarios').insert({
        'id_usuario': user.id,
        'correo_electronico': user.email,
        'mensaje': _feedbackController.text,
      });

      if (mounted) {
        _feedbackController.clear();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const FeedbackThanksScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessages.map(
                e,
                fallback: isEnglish
                    ? 'Could not send your comment. Please try again.'
                    : 'No se pudo enviar el comentario. Intenta nuevamente',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
