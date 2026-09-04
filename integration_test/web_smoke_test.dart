import 'package:ffpmupt/models/access_request_country.dart';
import 'package:ffpmupt/screens/access_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('web access-request flow prepares a mailto message', (
    tester,
  ) async {
    Uri? capturedUri;
    await tester.pumpWidget(
      MaterialApp(
        home: AccessRequestScreen(
          countries: const [AccessRequestCountry(code: 'es', name: 'Spain')],
          initialCountryCode: 'es',
          emailLauncher: (uri) async {
            capturedUri = uri;
            return true;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Web Leader');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'leader@example.com',
    );
    await tester.tap(find.text('Open email to send request'));
    await tester.pumpAndSettle();

    expect(capturedUri?.scheme, 'mailto');
    expect(capturedUri?.path, 'osman.gimenes@gmail.com');
    expect(capturedUri?.queryParameters['subject'], contains('Spain'));
    expect(find.text('Email draft prepared'), findsOneWidget);
  });
}
