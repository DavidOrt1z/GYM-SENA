import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 80),

              // Contenido centrado arriba
              Column(
                children: [
                  // Título con wave emoji
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: isEnglish
                              ? 'See you soon, trainee! '
                              : '¡Hasta pronto, aprendiz! ',
                          style: const TextStyle(
                            color: WHITE,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(text: '👋', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  Text(
                    isEnglish
                        ? 'You have been signed out successfully'
                        : 'Tu sesión se ha cerrado correctamente',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SECONDARY_COLOR,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Botón Continuar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PRIMARY_COLOR,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEnglish ? 'Continue' : 'Continuar',
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
      ),
    );
  }
}
