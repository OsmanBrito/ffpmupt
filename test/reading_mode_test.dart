import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/screens/list_of_songs_screen.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('song switches between individual reading and presentation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());

    var lyric = tester.widget<Text>(find.text(_lyric));
    expect(lyric.textAlign, TextAlign.start);
    expect(find.text('Texto menor'), findsOneWidget);
    expect(find.text('Texto maior'), findsOneWidget);

    await tester.tap(find.byTooltip('Modo de apresentação'));
    await tester.pump();

    lyric = tester.widget<Text>(find.text(_lyric));
    expect(lyric.textAlign, TextAlign.center);
    expect(lyric.style?.fontSize, 48);
    expect(find.byTooltip('Modo de leitura'), findsOneWidget);
  });

  testWidgets('song controls remain compact on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());

    expect(find.text('Texto menor'), findsNothing);
    expect(find.byTooltip('Texto menor'), findsOneWidget);
    expect(find.byTooltip('Texto maior'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('song shows chords only on verses that provide them', (
    tester,
  ) async {
    await tester.pumpWidget(_app(chords: const ['D   A   Bm   G']));

    expect(find.text('Cifra'), findsNWidgets(2));
    expect(find.text('D   A   Bm   G'), findsOneWidget);

    await tester.tap(find.text('Seguinte'));
    await tester.pump();

    expect(find.text('D   A   Bm   G'), findsNothing);
    expect(find.text('Segunda estrofe.'), findsOneWidget);
  });

  testWidgets('song without chords keeps the regular lyric layout', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.text('Cifra'), findsNothing);
    expect(find.byIcon(Icons.piano_outlined), findsNothing);
  });

  testWidgets('song filters move into a mobile sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_songListApp());
    await tester.pumpAndSettle();

    expect(find.text('Título, número da página ou letra'), findsOneWidget);
    expect(find.text('Favoritas'), findsOneWidget);
    expect(find.text('Recentes'), findsOneWidget);
    expect(find.text('Filtrar'), findsOneWidget);

    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();

    expect(find.text('Filtrar'), findsNWidgets(2));
    expect(find.text('Com música'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _lyric = 'Uma linha de letra para leitura individual.';

Widget _app({List<String> chords = const []}) {
  return AppLanguageScope(
    controller: AppLanguageController(loadStoredLanguage: false),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: SongScreen(
        countryCode: 'pt',
        song: SongDocument(
          id: 'sample',
          title: 'Canção de teste',
          page: '42',
          category: SongCategory.holy,
          languageCode: 'pt',
          lyrics: const [_lyric, 'Segunda estrofe.'],
          chords: chords,
          chorusMode: ChorusMode.none,
          enabled: true,
          sortOrder: 0,
          audioTracks: const [],
          videoLinks: const [],
        ),
      ),
    ),
  );
}

Widget _songListApp() {
  return AppLanguageScope(
    controller: AppLanguageController(loadStoredLanguage: false),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const ListOfSongsScreen(
        countryCode: 'pt',
        enableLocalLibrary: false,
        watchCatalog: false,
      ),
    ),
  );
}
