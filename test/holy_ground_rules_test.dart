import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public Holy Ground rules require an enabled parent country', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('match /{path=**}/holyGrounds/{holyGroundId}'));
    expect(rules, contains('isEnabledCountry(resource.data.countryCode)'));
  });

  test('country path does not expose hidden Holy Grounds publicly', () {
    final rules = File('firestore.rules').readAsStringSync();
    final countryRule = RegExp(
      r'match /countries/\{countryCode\}/holyGrounds/\{holyGroundId\} \{([\s\S]*?)\n    \}',
    ).firstMatch(rules)?.group(1);

    expect(countryRule, isNotNull);
    expect(countryRule, isNot(contains('allow read: if true')));
    expect(countryRule, contains('resource.data.enabled == true'));
    expect(countryRule, contains('isEnabledCountry(countryCode)'));
  });

  test('Holy Ground enabled field supports collection queries', () {
    final config =
        jsonDecode(File('firestore.indexes.json').readAsStringSync())
            as Map<String, dynamic>;
    final overrides = config['fieldOverrides'] as List<dynamic>;
    final enabledOverride = overrides.cast<Map<String, dynamic>>().singleWhere(
      (override) =>
          override['collectionGroup'] == 'holyGrounds' &&
          override['fieldPath'] == 'enabled',
    );
    final indexes = (enabledOverride['indexes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(
      indexes,
      contains(
        predicate<Map<String, dynamic>>(
          (index) =>
              index['order'] == 'ASCENDING' &&
              index['queryScope'] == 'COLLECTION',
        ),
      ),
    );
  });

  test('public country content requires an enabled parent country', () {
    final rules = File('firestore.rules').readAsStringSync();

    for (final path in [
      'settings/weeklyVideos',
      'settings/payments',
      'settings/motto',
      'songs/{songId}',
      'promises/{languageCode}',
      'notices/{noticeId}',
    ]) {
      expect(rules, contains('match /countries/{countryCode}/$path'));
    }
    expect(rules, contains('allow read: if isEnabledCountry(countryCode)'));
  });

  test(
    'country administrators cannot change country identity or availability',
    () {
      final rules = File('firestore.rules').readAsStringSync();

      expect(
        rules,
        contains("request.resource.data.code == resource.data.code"),
      );
      expect(
        rules,
        contains("request.resource.data.enabled == resource.data.enabled"),
      );
      expect(
        rules,
        contains("'name', 'defaultLanguage', 'timezone', 'updatedAt'"),
      );
    },
  );
}
