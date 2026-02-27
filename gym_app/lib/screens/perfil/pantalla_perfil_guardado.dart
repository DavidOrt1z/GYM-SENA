import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ProfileSavedScreen extends StatelessWidget {
  const ProfileSavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 80),
              
              // Título sin checkmark
              Text(
                'Perfil guardado\ncorrectamente',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: WHITE,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Descripción
              Text(
                'Tus datos se han actualizado exitosamente.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SECONDARY_COLOR,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              const Spacer(),
              
              // Botón Continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop ProfileSavedScreen
                    Navigator.of(context).pop();
                    // Pop EditProfileScreen
                    Navigator.of(context).pop();
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
