import 'dart:convert';

import 'package:ffpmupt/models/sunday_mode.dart';
import 'package:ffpmupt/settings/local_store.dart';

class SundayModeRepository {
  SundayModeRepository({required this.countryCode});

  final String countryCode;

  String get _planKey => 'sundayMode.$countryCode.plan.v1';
  String get _reportsKey => 'sundayMode.$countryCode.reports.v1';
  String get _activeSessionKey => 'sundayMode.$countryCode.active.v1';

  static const defaultPlan = [
    SundayPlanItem(module: SundayModule.songs, enabled: true),
    SundayPlanItem(module: SundayModule.familyPromise, enabled: true),
    SundayPlanItem(module: SundayModule.motto, enabled: true),
    SundayPlanItem(module: SundayModule.offerings, enabled: true),
    SundayPlanItem(module: SundayModule.videos, enabled: true),
    SundayPlanItem(module: SundayModule.notices, enabled: true),
  ];

  Future<List<SundayPlanItem>> loadPlan() async {
    final stored = await LocalStore.getStringList(_planKey);
    if (stored == null || stored.isEmpty) {
      return List.of(defaultPlan);
    }
    final decoded = <SundayPlanItem>[];
    for (final value in stored) {
      final parts = value.split(':');
      final module = SundayModule.values
          .where((candidate) => candidate.name == parts.first)
          .firstOrNull;
      if (module != null) {
        decoded.add(
          SundayPlanItem(
            module: module,
            enabled: parts.length < 2 || parts[1] != '0',
          ),
        );
      }
    }
    for (final item in defaultPlan) {
      if (!decoded.any((saved) => saved.module == item.module)) {
        decoded.add(item);
      }
    }
    return decoded;
  }

  Future<void> savePlan(List<SundayPlanItem> plan) {
    return LocalStore.setStringList(
      _planKey,
      plan
          .map((item) => '${item.module.name}:${item.enabled ? '1' : '0'}')
          .toList(),
    );
  }

  Future<List<SundaySessionReport>> loadReports() async {
    final stored = await LocalStore.getString(_reportsKey);
    if (stored == null || stored.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map(
            (value) =>
                SundaySessionReport.fromMap(Map<String, Object?>.from(value)),
          )
          .whereType<SundaySessionReport>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<List<SundaySessionReport>> addReport(
    SundaySessionReport report,
  ) async {
    final reports = await loadReports();
    final updated = [report, ...reports].take(12).toList();
    await LocalStore.setString(
      _reportsKey,
      jsonEncode(updated.map((item) => item.toMap()).toList()),
    );
    return updated;
  }

  Future<SundaySessionState?> loadActiveSession() async {
    final stored = await LocalStore.getString(_activeSessionKey);
    if (stored == null || stored.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map) {
        return null;
      }
      return SundaySessionState.fromMap(Map<String, Object?>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> saveActiveSession(SundaySessionState session) {
    return LocalStore.setString(_activeSessionKey, jsonEncode(session.toMap()));
  }

  Future<void> clearActiveSession() {
    return LocalStore.remove(_activeSessionKey);
  }
}
