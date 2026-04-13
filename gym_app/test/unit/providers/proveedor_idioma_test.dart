import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/providers/proveedor_idioma.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProveedorIdioma Tests', () {
    setUp(() {
      // Configurar SharedPreferences para pruebas
      SharedPreferences.setMockInitialValues({'idioma_app': 'es'});
    });

    test('Idioma inicial es español por defecto', () async {
      final proveedor = ProveedorIdioma();
      await proveedor.inicializar();
      expect(proveedor.idiomaActual, equals('es'));
    });

    test('Cambiar idioma a inglés funciona', () async {
      final proveedor = ProveedorIdioma();
      await proveedor.inicializar();
      await proveedor.cambiarIdioma('en');
      expect(proveedor.idiomaActual, equals('en'));
    });

    test('Cambiar idioma a español funciona', () async {
      final proveedor = ProveedorIdioma();
      await proveedor.inicializar();
      await proveedor.cambiarIdioma('en');
      await proveedor.cambiarIdioma('es');
      expect(proveedor.idiomaActual, equals('es'));
    });

    test('Obtener traducción en español', () {
      final proveedor = ProveedorIdioma();
      final texto = proveedor.texto('iniciar_sesion');
      expect(texto, equals('Iniciar Sesión'));
    });

    test('Obtener traducción en inglés', () async {
      final proveedor = ProveedorIdioma();
      await proveedor.inicializar();
      await proveedor.cambiarIdioma('en');
      final texto = proveedor.texto('iniciar_sesion');
      expect(texto, equals('Sign In'));
    });

    test('Retorna clave si traducción no existe', () {
      final proveedor = ProveedorIdioma();
      final texto = proveedor.texto('clave_inexistente');
      expect(texto, equals('clave_inexistente'));
    });

    test('El cambio de idioma notifica a los listeners', () async {
      final proveedor = ProveedorIdioma();
      await proveedor.inicializar();
      var cambiosNotificados = 0;

      proveedor.addListener(() {
        cambiosNotificados++;
      });

      await proveedor.cambiarIdioma('en');
      expect(cambiosNotificados, equals(1));

      await proveedor.cambiarIdioma('es');
      expect(cambiosNotificados, equals(2));
    });

    test('El idioma se persiste en SharedPreferences', () async {
      final proveedor = ProveedorIdioma();
      await proveedor.inicializar();
      await proveedor.cambiarIdioma('en');

      final prefs = await SharedPreferences.getInstance();
      final idiomaPersistido = prefs.getString('idioma_app');
      expect(idiomaPersistido, equals('en'));
    });
  });
}
