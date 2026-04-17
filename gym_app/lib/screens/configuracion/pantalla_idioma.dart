import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../providers/proveedor_idioma.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  Future<void> _cambiarIdiomaSeguro(
    BuildContext context,
    ProveedorIdioma proveedorIdioma,
    String codigoIdioma,
  ) async {
    try {
      await proveedorIdioma.cambiarIdioma(codigoIdioma);
    } catch (error) {
      debugPrint('Error al cambiar idioma: $error');
      if (!context.mounted) return;
      final isEnglish = Localizations.localeOf(context).languageCode == 'en';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish
                ? 'Could not change language. Please try again.'
                : 'No se pudo cambiar el idioma. Intenta de nuevo.',
          ),
        ),
      );
    }
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
          isEnglish ? 'Language' : 'Lenguaje',
          style: TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<ProveedorIdioma>(
        builder: (context, proveedorIdioma, _) {
          final lenguajeActual = proveedorIdioma.locale.languageCode;

          return Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isEnglish ? 'Select language' : 'Seleccionar idioma',
                  style: TextStyle(
                    color: WHITE,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Spanish
              _buildLanguageOption(
                language: 'Español',
                selected: lenguajeActual == 'es',
                onTap: () {
                  unawaited(
                    _cambiarIdiomaSeguro(context, proveedorIdioma, 'es'),
                  );
                },
              ),
              // English
              _buildLanguageOption(
                language: 'English',
                selected: lenguajeActual == 'en',
                onTap: () {
                  unawaited(
                    _cambiarIdiomaSeguro(context, proveedorIdioma, 'en'),
                  );
                },
              ),
              const Spacer(),
              // Save Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 32,
                ),
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
                    child: Text(
                      isEnglish ? 'Save' : 'Guardar',
                      style: TextStyle(
                        color: WHITE,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildLanguageOption({
    required String language,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? PRIMARY_COLOR : SECONDARY_COLOR,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language,
                style: const TextStyle(
                  color: WHITE,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? PRIMARY_COLOR : SECONDARY_COLOR,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: PRIMARY_COLOR,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
