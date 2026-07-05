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
}
