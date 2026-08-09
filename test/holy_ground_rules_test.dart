import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public Holy Ground rules support enabled collection-group reads', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('match /{path=**}/holyGrounds/{holyGroundId}'));
    expect(rules, contains('allow read: if resource.data.enabled == true;'));
  });

  test('country path does not expose hidden Holy Grounds publicly', () {
    final rules = File('firestore.rules').readAsStringSync();
    final countryRule = RegExp(
      r'match /countries/\{countryCode\}/holyGrounds/\{holyGroundId\} \{([\s\S]*?)\n    \}',
    ).firstMatch(rules)?.group(1);

    expect(countryRule, isNotNull);
    expect(countryRule, isNot(contains('allow read: if true')));
    expect(countryRule, contains('resource.data.enabled == true'));
  });

  test('public access request writes stay disabled for the manual email flow', () {
    final rules = File('firestore.rules').readAsStringSync();

    final requestRule = RegExp(
      r'match /accessRequests/\{requestId\} \{([\s\S]*?)\n    \}',
    ).firstMatch(rules)?.group(1);

    expect(requestRule, isNotNull);
    expect(requestRule, contains('allow create: if false;'));
  });

  test('country administrators cannot change country identity or availability', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains("request.resource.data.code == resource.data.code"));
    expect(
      rules,
      contains("request.resource.data.enabled == resource.data.enabled"),
    );
    expect(
      rules,
      contains("'name', 'defaultLanguage', 'timezone', 'updatedAt'"),
    );
  });
}
