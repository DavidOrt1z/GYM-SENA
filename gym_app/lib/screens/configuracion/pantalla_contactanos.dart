import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
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
          'Contáctenos',
          style: TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // TEXTO INTRODUCTORIO
              const Text(
                'Estamos aquí para ayudar',
                style: TextStyle(
                  color: WHITE,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Si tiene alguna pregunta o necesita asistencia, por favor contáctenos utilizando la información de contacto que se encuentra a continuación.',
                style: TextStyle(
                  color: SECONDARY_COLOR,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // INFORMACIÓN DE CONTACTO
              const Text(
                'Información de contacto',
                style: TextStyle(
                  color: WHITE,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // EMAIL
              _buildSimpleContactItem(
                icon: Icons.mail_outline,
                label: 'Email',
                value: 'support@gymsena.com',
              ),
              const SizedBox(height: 16),

              // TELÉFONO
              _buildSimpleContactItem(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: '+57 3123456781',
              ),

              const SizedBox(height: 40),

              // SÍGUENOS
              const Text(
                'Síguenos',
                style: TextStyle(
                  color: WHITE,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // REDES SOCIALES EN COLUMNA
              _buildSimpleContactItem(
                icon: Icons.camera_alt_outlined,
                label: 'Instagram',
                value: '',
              ),
              const SizedBox(height: 16),
              _buildSimpleContactItem(
                icon: Icons.facebook,
                label: 'Facebook',
                value: '',
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DARK_BG,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: WHITE,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: WHITE,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: SECONDARY_COLOR,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
