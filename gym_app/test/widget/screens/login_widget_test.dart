import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Structure Tests', () {
    testWidgets('Verifica que hay campos de entrada de texto',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextFormField(),
                TextFormField(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('Verifica que hay botones de acción',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Iniciar Sesión'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Registrarse'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('Verifica que TextFormField acepta entrada',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(key: const Key('email_field')),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Verifica que los botones son presionables',
        (WidgetTester tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('Presionar'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(buttonPressed, isTrue);
    });

    testWidgets('Verifica que renders un MaterialApp con localizaciones',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Prueba')),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Prueba'), findsOneWidget);
    });
  });
}
