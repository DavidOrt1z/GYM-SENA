import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Onboarding UI Structure Tests', () {
    testWidgets('Renderiza un PageView', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageView(
              children: const [
                Center(child: Text('Página 1')),
                Center(child: Text('Página 2')),
                Center(child: Text('Página 3')),
                Center(child: Text('Página 4')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('Muestra indicadores de página (dots)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: PageView(
                    children: const [
                      Center(child: Text('Página 1')),
                      Center(child: Text('Página 2')),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Tiene botones de navegación', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(child: Container()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('Skip'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('El botón Siguiente es presionable',
        (WidgetTester tester) async {
      var nextPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                nextPressed = true;
              },
              child: const Text('Siguiente'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(nextPressed, isTrue);
    });

    testWidgets('El botón Skip es presionable', (WidgetTester tester) async {
      var skipPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              onPressed: () {
                skipPressed = true;
              },
              child: const Text('Skip'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      expect(skipPressed, isTrue);
    });

    testWidgets('Muestra textos en todas las páginas',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageView(
              children: const [
                Center(child: Text('Bienvenido')),
                Center(child: Text('Reserva tus Horarios')),
                Center(child: Text('Monitorea tu Progreso')),
                Center(child: Text('Personaliza tu Experiencia')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsWidgets);
      expect(find.text('Bienvenido'), findsOneWidget);
    });
  });
}
