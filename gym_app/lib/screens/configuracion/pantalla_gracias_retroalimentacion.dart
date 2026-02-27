import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class FeedbackThanksScreen extends StatelessWidget {
  const FeedbackThanksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícono de éxito
              const Icon(
                Icons.check_circle_outline,
                color: PRIMARY_COLOR,
                size: 64,
              ),
              const SizedBox(height: 32),
              // Título
              const Text(
                '¡Gracias por tu mensaje!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WHITE,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Descripción
              Text(
                'Tu comentario ha sido enviado correctamente. Nuestro equipo revisará la información y te contactará si es necesario.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SECONDARY_COLOR,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        color: DARKER_BG,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PRIMARY_COLOR,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(
                color: WHITE,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
