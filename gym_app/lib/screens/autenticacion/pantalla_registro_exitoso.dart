import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón atrás
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: WHITE),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Título
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '¡Bienvenido a GYM SENA!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WHITE,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Subtítulo
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tu cuenta ha sido creada con éxito. ¡Prepárate para comenzar tu viaje de fitness con nosotros!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SECONDARY_COLOR,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Botón
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PRIMARY_COLOR,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      color: WHITE,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
