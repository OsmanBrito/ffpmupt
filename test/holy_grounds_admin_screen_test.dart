import 'package:ffpmupt/screens/admin/holy_grounds_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('holy ground editor offers image upload instead of a URL field', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HolyGroundEditorScreen(countryCode: 'pt', defaultLanguage: 'pt'),
      ),
    );

    expect(find.text('Selecionar fotografia'), findsOneWidget);
    expect(find.text('JPG, PNG ou WebP, até 5 MB.'), findsOneWidget);
    expect(find.text('URL da fotografia (opcional)'), findsNothing);
    expect(find.byIcon(Icons.upload_file_outlined), findsOneWidget);
  });

  testWidgets('accepts coordinates with commas and cardinal directions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HolyGroundEditorScreen(countryCode: 'pt', defaultLanguage: 'pt'),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Latitude (opcional)'),
      '38,73072° N.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Longitude (opcional)'),
      '9,15279° W',
    );
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pump();

    expect(find.text('Coordenada inválida'), findsNothing);
  });
}
