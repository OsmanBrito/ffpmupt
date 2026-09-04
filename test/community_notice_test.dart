import 'dart:convert';

import 'package:ffpmupt/models/community_notice.dart';
import 'package:ffpmupt/screens/admin/community_notices_admin_screen.dart';
import 'package:ffpmupt/screens/community_notices_screen.dart';
import 'package:ffpmupt/services/community_notice_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingNoticeRepository extends CommunityNoticeRepository {
  _RecordingNoticeRepository() : super(countryCode: 'pt');

  CommunityNotice? savedNotice;

  @override
  String newId() => 'new-notice';

  @override
  Future<void> save(CommunityNotice notice) async {
    savedNotice = notice;
  }
}

Widget _noticeEditorApp(_RecordingNoticeRepository repository) {
  return MaterialApp(
    home: AppLanguageScope(
      controller: AppLanguageController(loadStoredLanguage: false),
      child: CommunityNoticeEditorScreen(
        repository: repository,
        countryCode: 'pt',
        defaultLanguage: 'pt',
      ),
    ),
  );
}

Widget _cropScreenApp() {
  return MaterialApp(
    home: AppLanguageScope(
      controller: AppLanguageController(loadStoredLanguage: false),
      child: NoticeImageCropScreen(
        imageBytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M/wHwAEAQH/69w3mQAAAABJRU5ErkJggg==',
        ),
      ),
    ),
  );
}

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
      imageUrl: 'https://res.cloudinary.com/example/event.jpg',
      languageCode: 'pt',
      enabled: true,
      pinned: true,
      sortOrder: 2,
    );

    final decoded = CommunityNotice.fromMap(id: notice.id, map: notice.toMap());

    expect(decoded?.title, notice.title);
    expect(decoded?.category, NoticeCategory.workshop);
    expect(decoded?.parsedDate, DateTime(2026, 9, 12));
    expect(decoded?.imageUrl, notice.imageUrl);
    expect(decoded?.pinned, isTrue);
  });

  test('legacy notices without an image remain compatible', () {
    final notice = CommunityNotice.fromMap(
      id: 'legacy',
      map: const {
        'countryCode': 'pt',
        'title': 'Aviso antigo',
        'body': 'Conteúdo',
      },
    );

    expect(notice?.imageUrl, isEmpty);
  });

  test('Cloudinary notice images use a smaller WebP delivery URL', () {
    const original =
        'https://res.cloudinary.com/example/image/upload/v1/notice.png';

    expect(
      optimizedNoticeImageUrl(original),
      'https://res.cloudinary.com/example/image/upload/'
      'f_webp,q_auto,w_1200,c_limit/v1/notice.png',
    );
    expect(
      optimizedNoticeImageUrl('https://example.com/notice.png'),
      'https://example.com/notice.png',
    );
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

  testWidgets('admin validates and saves a notice locally', (tester) async {
    final repository = _RecordingNoticeRepository();
    await tester.pumpWidget(_noticeEditorApp(repository));

    await tester.tap(find.byTooltip('Guardar'));
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsNWidgets(2));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Workshop para líderes',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Informação'),
      'Preparação para o próximo encontro.',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ligação HTTPS (opcional)'),
      'http://example.com',
    );
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pump();
    expect(find.text('Use uma ligação HTTPS válida'), findsOneWidget);
    expect(repository.savedNotice, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ligação HTTPS (opcional)'),
      'https://example.com/workshop',
    );
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();

    expect(repository.savedNotice?.id, 'new-notice');
    expect(repository.savedNotice?.countryCode, 'pt');
    expect(repository.savedNotice?.title, 'Workshop para líderes');
    expect(repository.savedNotice?.languageCode, 'pt');
    expect(repository.savedNotice?.enabled, isTrue);
  });

  testWidgets('notice editor offers an optional image upload', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _RecordingNoticeRepository();
    await tester.pumpWidget(_noticeEditorApp(repository));

    expect(find.text('Imagem do aviso (opcional)'), findsOneWidget);
    expect(find.text('Selecionar imagem'), findsOneWidget);
    expect(find.text('JPG, PNG ou WebP · máximo 5 MB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notice image crop screen is optional and mobile friendly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_cropScreenApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Cortar imagem'), findsOneWidget);
    expect(find.text('Aplicar corte'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(
      find.text(
        'Arraste para reposicionar e use o gesto de pinça ou a roda do rato para ampliar.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
