import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/screens/country_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('country search accepts the country code', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CountrySelectionScreen(
          countries: const [
            CountryModel(
              code: 'pt',
              name: 'Portugal',
              defaultLanguage: 'pt',
              timezone: 'Europe/Lisbon',
              enabled: true,
            ),
            CountryModel(
              code: 'es',
              name: 'Spain',
              defaultLanguage: 'es',
              timezone: 'Europe/Madrid',
              enabled: true,
            ),
            CountryModel(
              code: 'fr',
              name: 'France',
              defaultLanguage: 'fr',
              timezone: 'Europe/Paris',
              enabled: true,
            ),
            CountryModel(
              code: 'de',
              name: 'Germany',
              defaultLanguage: 'de',
              timezone: 'Europe/Berlin',
              enabled: true,
            ),
            CountryModel(
              code: 'it',
              name: 'Italy',
              defaultLanguage: 'it',
              timezone: 'Europe/Rome',
              enabled: true,
            ),
            CountryModel(
              code: 'gb',
              name: 'United Kingdom',
              defaultLanguage: 'en',
              timezone: 'Europe/London',
              enabled: true,
            ),
            CountryModel(
              code: 'ch',
              name: 'Switzerland',
              defaultLanguage: 'de',
              timezone: 'Europe/Zurich',
              enabled: true,
            ),
          ],
          onSelected: _ignoreCountry,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'pt');
    await tester.pump();

    expect(find.text('Portugal'), findsOneWidget);
    expect(find.text('Spain'), findsNothing);
  });

  testWidgets('country search stays hidden for a short country list', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CountrySelectionScreen(
          countries: const [
            CountryModel(
              code: 'pt',
              name: 'Portugal',
              defaultLanguage: 'pt',
              timezone: 'Europe/Lisbon',
              enabled: true,
            ),
          ],
          onSelected: _ignoreCountry,
        ),
      ),
    );

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Portugal'), findsOneWidget);
  });
}

void _ignoreCountry(CountryModel _) {}
