import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const Text(
          'Politica de Privacidad',
          style: TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de Privacidad de GYM SENA',
              style: TextStyle(
                color: WHITE,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'En GYM SENA, estamos comprometidos con la protección de su privacidad. Esta Política de Privacidad explica cómo recopilamos, utilizamos y compartimos su información personal cuando utiliza nuestra aplicación. Al usar GYM SENA, usted acepta los términos de esta política.',
              style: TextStyle(
                color: SECONDARY_COLOR,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Información que recopilamos',
              'Recopilamos información que usted proporciona directamente, como su nombre, dirección de correo electrónico y objetivos de fitness. También recopilamos datos de manera automática, incluyendo el uso de la aplicación y la información del dispositivo.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Cómo utilizamos su información',
              'Usamos su información para proporcionar y mejorar nuestros servicios, personalizar su experiencia y comunicarle sobre actualizaciones y promociones. También podemos utilizar sus datos para investigación y análisis.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Compartiendo tu información',
              'Podemos compartir su información con proveedores de servicios que nos ayudan a operar la aplicación. No venderemos su información personal a terceros. También podemos revelar información si la ley lo requiere.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Tus Derechos',
              'Usted tiene derecho a acceder, corregir o eliminar su información personal. También puede optar por no recibir comunicaciones promocionales. Por favor, contáctenos si tiene alguna pregunta o inquietud sobre sus datos.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Seguridad',
              'Implementamos medidas de seguridad técnicas, administrativas y físicas para proteger su información personal contra acceso no autorizado, alteración, divulgación o destrucción.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Cambios en esta Política',
              'GYM SENA puede actualizar esta Política de Privacidad de vez en cuando. Le notificaremos de cambios significativos enviándole un aviso o publicando la política actualizada en la aplicación.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Contáctenos',
              'Si tiene preguntas sobre esta Política de Privacidad o nuestras prácticas de privacidad, póngase en contacto con nosotros en support@gymsena.com.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
                    color: WHITE,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: WHITE,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: SECONDARY_COLOR,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
