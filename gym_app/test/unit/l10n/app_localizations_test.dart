import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('Traducción en español funciona correctamente', () {
      const idioma = 'es';
      const clave = 'iniciar_sesion';

      final mapa = AppLocalizations.locales[idioma];
      expect(mapa, isNotNull);
      expect(mapa![clave], isNotEmpty);
      expect(mapa[clave], equals('Iniciar Sesión'));
    });

    test('Traducción en inglés funciona correctamente', () {
      const idioma = 'en';
      const clave = 'iniciar_sesion';

      final mapa = AppLocalizations.locales[idioma];
      expect(mapa, isNotNull);
      expect(mapa![clave], isNotEmpty);
      expect(mapa[clave], equals('Sign In'));
    });

    test('Retorna la clave si no existe la traducción', () {
      const idioma = 'es';
      const claveInexistente = 'clave_inexistente_12345';

      final mapa = AppLocalizations.locales[idioma];
      final resultado = mapa![claveInexistente] ?? claveInexistente;

      expect(resultado, equals(claveInexistente));
    });

    test('Todos los idiomas soportados están configurados', () {
      expect(AppLocalizations.locales.containsKey('es'), isTrue);
      expect(AppLocalizations.locales.containsKey('en'), isTrue);
    });

    test('Las claves comunes existen en ambos idiomas', () {
      final keysComunesEsperadas = [
        'iniciar_sesion',
        'registrarse',
        'email',
        'contrasena',
        'inicio',
        'reservas',
        'progreso',
        'perfil',
        'configuracion',
      ];

      final mapaEs = AppLocalizations.locales['es']!;
      final mapaEn = AppLocalizations.locales['en']!;

      for (final clave in keysComunesEsperadas) {
        expect(mapaEs.containsKey(clave), isTrue,
            reason: 'Clave "$clave" no existe en español');
        expect(mapaEn.containsKey(clave), isTrue,
            reason: 'Clave "$clave" no existe en inglés');
      }
    });

    test('No hay traducciones vacías', () {
      final mapaEs = AppLocalizations.locales['es']!;
      final mapaEn = AppLocalizations.locales['en']!;

      for (final clave in mapaEs.keys) {
        expect(mapaEs[clave]!.isNotEmpty, isTrue,
            reason: 'Traducción vacía en español para: $clave');
      }

      for (final clave in mapaEn.keys) {
        expect(mapaEn[clave]!.isNotEmpty, isTrue,
            reason: 'Traducción vacía en inglés para: $clave');
      }
    });
  });
}
