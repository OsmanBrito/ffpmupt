import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/screens/admin/country_admin_screen.dart';
import 'package:ffpmupt/services/country_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCountryRepository extends CountryRepository {
  _FakeCountryRepository(this.country);

  final CountryModel country;

  @override
  Future<CountryModel?> load(String countryCode) async => country;
}

Widget _testApp({required bool isSuperAdmin}) {
  final languageController = AppLanguageController(loadStoredLanguage: false);
  return MaterialApp(
    home: AppLanguageScope(
      controller: languageController,
      child: CountryAdminScreen(
        countryCode: 'es',
        isSuperAdmin: isSuperAdmin,
        repository: _FakeCountryRepository(
          const CountryModel(
            code: 'es',
            name: 'Spain',
            defaultLanguage: 'es',
            timezone: 'Europe/Madrid',
            enabled: true,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('country administrators cannot change country availability', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(isSuperAdmin: false));
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.onChanged, isNull);
  });

  testWidgets('superadmins can change country availability', (tester) async {
    await tester.pumpWidget(_testApp(isSuperAdmin: true));
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.onChanged, isNotNull);
  });
}
