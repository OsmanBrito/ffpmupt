import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/operational_crm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local church round-trips through Firestore data', () {
    const church = LocalChurch(
      id: 'lisbon',
      name: 'Lisbon Family Church',
      city: 'Lisbon',
      address: 'Example address',
      timezone: 'Europe/Lisbon',
      contactName: 'Local admin',
      contactEmail: 'admin@example.com',
      enabled: true,
    );

    final decoded = LocalChurch.fromMap(id: church.id, map: church.toMap());
    expect(decoded?.name, church.name);
    expect(decoded?.contactEmail, church.contactEmail);
    expect(decoded?.enabled, isTrue);
  });

  test('admin profile preserves access to multiple countries', () {
    const profile = AdminProfile(
      uid: 'uid-1',
      email: 'admin@example.com',
      displayName: 'Admin',
      role: 'admin',
      enabled: true,
      countryCodes: ['br', 'pt'],
    );

    final decoded = AdminProfile.fromMap(
      uid: profile.uid,
      map: profile.toMap(),
    );
    expect(decoded?.countryCodes, ['br', 'pt']);
  });

  test('country readiness reflects seven operational requirements', () {
    const summary = CountryOperationalSummary(
      country: CountryModel(
        code: 'br',
        name: 'Brasil',
        defaultLanguage: 'pt',
        timezone: 'America/Sao_Paulo',
        enabled: true,
      ),
      churchCount: 1,
      adminCount: 1,
      promiseLanguageCount: 3,
      songCount: 62,
      hasPayments: true,
      hasWeeklyVideos: true,
    );

    expect(summary.expectedPromiseLanguages, 3);
    expect(summary.completedSteps, 7);
    expect(summary.progress, 1);
    expect(summary.isReady, isTrue);
  });

  test('admin invite round-trips and reports its state', () {
    final invite = AdminInvite(
      id: 'invite-1',
      email: 'admin@example.com',
      displayName: 'Country admin',
      countryCodes: const ['br'],
      createdBy: 'superadmin-uid',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      enabled: true,
      acceptedBy: '',
    );

    final decoded = AdminInvite.fromMap(id: invite.id, map: invite.toMap());
    expect(decoded?.email, invite.email);
    expect(decoded?.countryCodes, ['br']);
    expect(decoded?.isPending, isTrue);
    expect(decoded?.isAccepted, isFalse);
  });
}
