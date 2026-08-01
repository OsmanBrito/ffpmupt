import 'package:ffpmupt/models/country_readiness.dart';
import 'package:ffpmupt/models/sunday_mode.dart';
import 'package:ffpmupt/services/sunday_mode_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/p0_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default Sunday plan contains every module exactly once', () {
    final modules = SundayModeRepository.defaultPlan
        .map((item) => item.module)
        .toList();
    expect(modules.toSet().length, SundayModule.values.length);
    expect(modules, SundayModule.values);
    expect(
      SundayModeRepository.defaultPlan.every((item) => item.enabled),
      isTrue,
    );
  });

  test('Sunday report round-trips through local data', () {
    final report = SundaySessionReport(
      startedAt: DateTime.utc(2026, 7, 5, 9),
      finishedAt: DateTime.utc(2026, 7, 5, 10, 30),
      completedModules: 5,
      totalModules: 5,
      withoutPaper: true,
      withoutInterruptions: true,
      rating: 5,
      notes: 'Tudo funcionou.',
    );
    final decoded = SundaySessionReport.fromMap(report.toMap());
    expect(decoded?.duration, const Duration(minutes: 90));
    expect(decoded?.rating, 5);
    expect(decoded?.withoutPaper, isTrue);
  });

  test('country readiness requires every check and no content issues', () {
    final checks = [
      for (final area in ReadinessArea.values)
        ReadinessCheck(area: area, ready: true, detail: ''),
    ];
    final ready = CountryReadiness(checks: checks, issues: const []);
    final withIssue = CountryReadiness(
      checks: checks,
      issues: const [
        ContentIssue(area: ReadinessArea.songs, subject: 'Example'),
      ],
    );
    expect(ready.isReady, isTrue);
    expect(ready.progress, 1);
    expect(withIssue.isReady, isFalse);
  });

  test('P0 product strings cover every supported app language', () {
    for (final language in AppLanguage.values) {
      final strings = P0Strings.of(language);
      for (final key in P0Text.values) {
        expect(strings[key].trim(), isNotEmpty, reason: '$language / $key');
        expect(strings[key], isNot(key.name), reason: '$language / $key');
      }
    }
  });
}
