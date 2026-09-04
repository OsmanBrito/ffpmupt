import 'package:ffpmupt/models/access_request_country.dart';
import 'package:ffpmupt/screens/access_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('access request screen explains the review flow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AccessRequestScreen(
          countries: [AccessRequestCountry(code: 'pt', name: 'Portugal')],
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

  test(
    'European request list includes countries not configured in Firestore',
    () {
      expect(
        europeanAccessRequestCountries.any((country) => country.code == 'es'),
        isTrue,
      );
      expect(
        europeanAccessRequestCountries.any((country) => country.code == 'pt'),
        isTrue,
      );
    },
  );

  testWidgets('request opens a prepared email without Firebase', (
    tester,
  ) async {
    Uri? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: AccessRequestScreen(
          countries: const [
            AccessRequestCountry(code: 'va', name: 'Vatican City'),
          ],
          initialCountryCode: 'va',
          emailLauncher: (uri) async {
            captured = uri;
            return true;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Un Hee Schiefelbein Brito',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'peace.unhee@gmail.com',
    );
    await tester.tap(find.text('Country leader'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Country administrator').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), 'Message');
    final submitButton = find.text('Open email to send request');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(captured?.scheme, 'mailto');
    expect(captured?.path, 'osman.gimenes@gmail.com');
    expect(
      captured?.queryParameters['subject'],
      'FFPMU Connect — Administrator access request — Vatican City',
    );
    expect(
      captured?.queryParameters['body'],
      [
        'Hello Osman,',
        '',
        'I would like to request administrator access to FFPMU Connect.',
        '',
        'Country: Vatican City (VA)',
        'Name: Un Hee Schiefelbein Brito',
        'Role: Country administrator',
        'Email for the invitation: peace.unhee@gmail.com',
        '',
        'Message:',
        'Message',
        '',
        'Thank you.',
      ].join('\n'),
    );
    final rawMailto = captured.toString();
    expect(rawMailto, isNot(contains('+')));
    expect(rawMailto, isNot(contains(r'\')));
    expect(rawMailto, contains('%20'));
    expect(rawMailto, contains('%0A%0A'));
    expect(rawMailto, contains('peace.unhee%40gmail.com'));
    expect(find.text('Email draft prepared'), findsOneWidget);
  });

  testWidgets('request offers a manual copy fallback when no email app opens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccessRequestScreen(
          countries: const [AccessRequestCountry(code: 'pt', name: 'Portugal')],
          initialCountryCode: 'pt',
          emailLauncher: (_) async => false,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Test Leader');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'test@example.com',
    );
    final submitButton = find.text('Open email to send request');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('We could not open your email application'),
      findsOneWidget,
    );
    expect(find.text('Copy request text'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });
}
