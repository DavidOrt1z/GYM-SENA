import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
          'Terminos de uso',
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
              '¡Bienvenido a JACEK GYM!',
              style: TextStyle(
                color: WHITE,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Al usar nuestra aplicación, usted acepta los siguientes términos y condiciones. Por favor, léalos cuidadosamente. Si no esta de acuerdo, por favor no use la aplicación. El uso de la aplicación constituye su aceptación de estos términos.',
              style: TextStyle(
                color: SECONDARY_COLOR,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Registro de cuenta',
              'Debes registrarte una cuenta para acceder a ciertas funciones de la aplicación. Aceptas proporcionar información precisa y completa durante el registro y mantener actualizada la información de tu cuenta. Eres responsable de mantener la confidencialidad de las credenciales de tu cuenta y de todas las actividades que ocurran bajo tu cuenta.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '2. Uso de la aplicación',
              'Usted acepta usar la aplicación únicamente con fines legales y de acuerdo con estos términos. No utilizará la aplicación de ninguna manera que pueda dañar, deshabilitar, sobrecargar o deteriorar la aplicación, ni interferir con el uso de la aplicación por parte de cualquier otra persona.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '3. Contenido',
              'La aplicación puede contener contenido proporcionado por JACEK GYM y otros usuarios. Usted es el único responsable de cualquier contenido que publique o comparta a través de términos de que sea objetable de otra manera.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '4. Privacidad',
              'Your privacy is important to us. Please review our Privacy Policy, which explains how we collect, use, and protect your personal information.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '5. Terminación',
              'JACEK GYM puede terminar o suspender su acceso a la aplicación en cualquier momento, con o sin causa, y sin previo aviso. Usted también puede cancelar su cuenta en cualquier momento.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '6. Aviso',
              'La aplicación se proporciona "tal cual" y "según disponibilidad" sin garantías de ningún tipo. JACEK GYM renuncia a todas las garantías, expresas e implícitas, incluidas, entre otras, las garantías de comerciabilidad, idoneidad para un propósito particular e infracción.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '7. Limitación de Responsabilidad',
              'En ningún caso JACEK GYM será responsable de ningún daño directo, indirecto, especial, consecuente o punitivo derivado de o relacionado con su uso de la aplicación.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '8. Cambios en los Términos',
              'JACEK GYM puede modificar estos términos en cualquier momento. Le notificaremos de cualquier cambio publicado los nuevos términos en la aplicación. Su uso continuado de la aplicación después de los cambios constituye su aceptación de los nuevos términos.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '9. Ley Aplicable',
              'Estos términos se regirán e interpretarán de acuerdo con las leyes de la jurisdicción en la que se encuentra JACEK GYM, sin tener en cuenta sus principios de conflicto de leyes.',
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
