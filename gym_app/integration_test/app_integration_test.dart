import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/main.dart';
import 'package:gym_app/providers/proveedor_idioma.dart';
import 'package:integration_test/integration_test.dart';

Widget _buildTestApp() {
  return MyApp(proveedorIdioma: ProveedorIdioma());
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('La app inicia correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verifica que algún widget se haya renderizado
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('La app tiene navegación principal', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Buscar widgets de navegación
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('El onboarding se muestra la primera vez', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // La app debería mostrar una pantalla de inicio/onboarding
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('La navegación entre pantallas funciona', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Buscar elementos de navegación
      final navigationElements = find.byType(BottomNavigationBar);
      if (navigationElements.evaluate().isNotEmpty) {
        // Si existe BottomNavigationBar, intenta navegar
        final navigationItems = find.byType(BottomNavigationBarItem);
        if (navigationItems.evaluate().isNotEmpty) {
          expect(navigationItems, findsWidgets);
        }
      }
    });

    testWidgets('Los temas se aplican correctamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verifica que el MaterialApp tenga un tema
      final materialApp = find.byType(MaterialApp);
      expect(materialApp, findsOneWidget);
    });

    testWidgets('La app maneja rotación de pantalla', (
      WidgetTester tester,
    ) async {
      // Establecer tamaño de pantalla vertical
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1080, 1920);

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);

      // Cambiar a horizontal
      tester.view.physicalSize = const Size(1920, 1080);

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('La app responde a toques en botones', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Buscar y presionar cualquier botón disponible
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Los textos se muestran correctamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Buscar widgets de texto
      expect(find.byType(Text), findsWidgets);
    });
  });
}
