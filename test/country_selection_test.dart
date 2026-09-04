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
}

void _ignoreCountry(CountryModel _) {}
