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

  testWidgets('editor remains usable on a narrow mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HolyGroundEditorScreen(countryCode: 'pt', defaultLanguage: 'pt'),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
