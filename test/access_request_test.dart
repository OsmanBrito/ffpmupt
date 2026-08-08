import 'package:ffpmupt/models/access_request.dart';
import 'package:ffpmupt/models/access_request_country.dart';
import 'package:ffpmupt/screens/access_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('access request round-trips through Firestore data', () {
    const request = AccessRequest(
      countryCode: 'es',
      countryName: 'Spain',
      displayName: 'Country leader',
      email: 'leader@example.com',
      role: AccessRequestRole.countryLeader,
      message: 'Please include our local admin team.',
    );

    final decoded = AccessRequest.fromMap(request.toMap());

    expect(decoded?.countryCode, 'es');
    expect(decoded?.email, 'leader@example.com');
    expect(decoded?.role, AccessRequestRole.countryLeader);
    expect(decoded?.message, contains('local admin'));
  });

  test('access request rejects an unknown role', () {
    final decoded = AccessRequest.fromMap({
      'countryCode': 'es',
      'countryName': 'Spain',
      'displayName': 'Leader',
      'email': 'leader@example.com',
      'role': 'owner',
      'message': '',
    });

    expect(decoded, isNull);
  });

  testWidgets('access request screen explains the review flow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AccessRequestScreen(
          countries: [
            AccessRequestCountry(code: 'pt', name: 'Portugal'),
          ],
        ),
      ),
    );

    expect(find.text('Request administrator access'), findsNWidgets(2));
    expect(find.text('Open email to send request'), findsOneWidget);
    expect(
      find.textContaining('does not grant access automatically'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  test('European request list includes countries not configured in Firestore', () {
    expect(
      europeanAccessRequestCountries.any((country) => country.code == 'es'),
      isTrue,
    );
    expect(
      europeanAccessRequestCountries.any((country) => country.code == 'pt'),
      isTrue,
    );
  });

  testWidgets('request opens a prepared email without Firebase', (tester) async {
    Uri? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: AccessRequestScreen(
          countries: const [
            AccessRequestCountry(code: 'pt', name: 'Portugal'),
          ],
          initialCountryCode: 'pt',
          emailLauncher: (uri) async {
            captured = uri;
            return true;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Leader');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'ana@example.com',
    );
    final submitButton = find.text('Open email to send request');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(captured?.scheme, 'mailto');
    expect(captured?.path, 'osman.gimenes@gmail.com');
    expect(captured?.queryParameters['subject'], contains('Portugal'));
    expect(find.text('Email draft prepared'), findsOneWidget);
  });
}
