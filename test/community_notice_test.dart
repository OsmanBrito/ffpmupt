import 'package:ffpmupt/models/community_notice.dart';
import 'package:ffpmupt/screens/community_notices_screen.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('community notice round-trips through Firestore data', () {
    const notice = CommunityNotice(
      id: 'leaders-workshop',
      countryCode: 'pt',
      title: 'Workshop para líderes',
      body: 'Preparação para o próximo encontro.',
      category: NoticeCategory.workshop,
      date: '2026-09-12',
      location: 'Lisboa',
      linkUrl: 'https://connect.ffpmu.pt',
      languageCode: 'pt',
      enabled: true,
      pinned: true,
      sortOrder: 2,
    );

    final decoded = CommunityNotice.fromMap(id: notice.id, map: notice.toMap());

    expect(decoded?.title, notice.title);
    expect(decoded?.category, NoticeCategory.workshop);
    expect(decoded?.parsedDate, DateTime(2026, 9, 12));
    expect(decoded?.pinned, isTrue);
  });

  test('community notice rejects missing content or invalid dates', () {
    expect(
      CommunityNotice.fromMap(
        id: 'missing',
        map: const {'countryCode': 'pt', 'title': 'Only title'},
      ),
      isNull,
    );
    expect(
      CommunityNotice.fromMap(
        id: 'invalid-date',
        map: const {
          'countryCode': 'pt',
          'title': 'Title',
          'body': 'Body',
          'date': 'tomorrow',
        },
      ),
      isNull,
    );
  });

  test('pinned notices sort before regular notices', () {
    CommunityNotice notice(String id, {required bool pinned}) {
      return CommunityNotice(
        id: id,
        countryCode: 'pt',
        title: id,
        body: 'Body',
        category: NoticeCategory.general,
        date: '',
        location: '',
        linkUrl: '',
        languageCode: 'pt',
        enabled: true,
        pinned: pinned,
        sortOrder: 0,
      );
    }

    final notices = [
      notice('regular', pinned: false),
      notice('pinned', pinned: true),
    ]..sort(CommunityNotice.compare);

    expect(notices.first.id, 'pinned');
  });

  test('notice interface copy covers every language and category', () {
    for (final language in AppLanguage.values) {
      final copy = CommunityNoticeCopy.of(language);
      expect(copy.title, isNotEmpty);
      for (final category in NoticeCategory.values) {
        expect(copy.categoryLabel(category), isNotEmpty);
      }
    }
  });
}
