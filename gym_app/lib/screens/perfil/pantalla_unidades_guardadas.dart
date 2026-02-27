import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class UnitsSavedScreen extends StatelessWidget {
  const UnitsSavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DARKER_BG,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // AppBar simulado con botón atrás
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: WHITE),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Contenido centrado arriba
              Column(
                children: [
                  // Título sin checkmark
                  const Text(
                    'Medidad guardado\ncorrectamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: WHITE,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Descripción
                  const Text(
                    'Los cambios se aplicarán en todas tus\nestadísticas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PRIMARY_COLOR,
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
            ],
          ),
        ),
      ),
    );
  }
}
