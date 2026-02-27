import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
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
          'Centro de Ayuda',
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
            _buildSectionTitle('Preguntas Frecuentes'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildQuestionBox(
                    title: '¿Cómo restablezco mi contraseña?',
                    onTap: () {
                      _showHelpDetail(
                        title: 'Restablezco mi contraseña',
                        content: 'Si olvidaste tu contraseña, sigue estos pasos:\n\n1. En la pantalla de inicio de sesión, selecciona "Olvide mi contraseña".\n\n2. Ingresa el correo electrónico asociado a tu cuenta del SENA.\n\n3. Revisa tu correo electrónico y sigue el enlace para crear una nueva contraseña.\n\n4. Una vez completado, podrás iniciar sesión nuevamente con tu nueva clave.\n\nNota:\nSi no recibes el correo en unos minutos, revisa tu bandeja de spam o comunícate con soporte',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuestionBox(
                    title: '¿Cuáles son los horarios de apertura del gym?',
                    onTap: () {
                      _showHelpDetail(
                        title: 'Horario de apertura',
                        content: 'Días de la semana\n\nMañana\nLunes a Viernes: 6:30 AM hasta las 10:00 AM\n\nTarde\nLunes a Viernes: 3:00 PM hasta las 5:00 PM',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuestionBox(
                    title: '¿Cómo puedo actualizar la información de mi perfil?',
                    onTap: () {
                      _showHelpDetail(
                        title: 'Actualizar la información de mi perfil',
                        content: 'Si olvidaste tu contraseña, sigue estos pasos:\n\n1. En el menú inferior, selecciona "Perfil"\n\n2. Toca el icono o botón de "Editar perfil".\n\n3. Actualiza los campos que desees (nombre, apellido, años, etc.).\n\n4. Pulsa "Guardar cambios" para confirmar.\n\nConsejo:\nMantén tu información actualizada para recibir notificaciones y recordatorios correctamente.',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // INFORMAR UN PROBLEMA
            _buildSectionTitle('Informar un problema o proporcionar comentarios'),
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
                      hintText: 'Cuéntanos lo que piensas...',
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
                        borderSide: const BorderSide(color: PRIMARY_COLOR, width: 2),
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
                      child: const Text(
                        'Enviar',
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

  Widget _buildHelpItem({
    required String title,
    required VoidCallback onTap,
  }) {
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

  Widget _buildQuestionBox({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: SECONDARY_COLOR.withOpacity(0.3),
            width: 1,
          ),
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
            const Icon(
              Icons.chevron_right,
              color: SECONDARY_COLOR,
              size: 20,
            ),
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
            Icon(
              icon,
              color: PRIMARY_COLOR,
              size: 24,
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

  void _showHelpDetail({
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: DARK_BG,
          title: Text(
            title,
            style: const TextStyle(
              color: WHITE,
              fontWeight: FontWeight.bold,
            ),
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
              child: const Text(
                'Cerrar',
                style: TextStyle(color: PRIMARY_COLOR),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendFeedback() async {
    if (_feedbackController.text.isEmpty) {
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor inicia sesión para enviar feedback'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await Supabase.instance.client.from('feedback').insert({
        'user_id': user.id,
        'email': user.email,
        'message': _feedbackController.text,
      });

      if (mounted) {
        _feedbackController.clear();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const FeedbackThanksScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar el comentario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
