import 'package:ffpmupt/content/family_promise.dart';
import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/family_promise.dart';
import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/songs/bundled_song_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('country model round-trips through Firestore data', () {
    final decoded = CountryModel.fromMap(CountryModel.portugal.toMap());

    expect(decoded?.code, 'pt');
    expect(decoded?.name, 'Portugal');
    expect(decoded?.defaultLanguage, 'pt');
    expect(decoded?.timezone, 'Europe/Lisbon');
    expect(decoded?.enabled, isTrue);
  });

  test('song model round-trips through Firestore data', () {
    const song = SongDocument(
      id: 'a-morada-do-pai',
      title: 'A Morada do Pai',
      page: '1',
      category: SongCategory.holy,
      languageCode: 'pt',
      lyrics: ['Primeira estrofe', 'Segunda estrofe'],
      chorusMode: ChorusMode.none,
      enabled: true,
      sortOrder: 1,
      audioTracks: [
        SongAudioTrack(
          id: 'principal',
          label: 'Principal',
          url: 'https://example.com/audio.mp3',
          storagePath: 'countries/pt/songs/a-morada-do-pai/principal.mp3',
          verseStartSeconds: [0, 75],
          verseChangeSeconds: [75],
          enabled: true,
          sortOrder: 0,
        ),
      ],
      videoLinks: [
        SongVideoLink(
          id: 'youtube',
          provider: SongVideoProvider.youtube,
          label: 'YouTube',
          watchUrl: 'https://www.youtube.com/watch?v=example',
          embedUrl: 'https://www.youtube-nocookie.com/embed/example',
          enabled: true,
          sortOrder: 0,
        ),
      ],
    );

    final decoded = SongDocument.fromMap(id: song.id, map: song.toMap());

    expect(decoded?.id, song.id);
    expect(decoded?.title, song.title);
    expect(decoded?.category, SongCategory.holy);
    expect(decoded?.lyrics, hasLength(2));
    expect(decoded?.audioTracks.single.verseStartSeconds, [0, 75]);
    expect(decoded?.audioTracks.single.verseChangeSeconds, [75]);
    expect(decoded?.videoLinks.single.provider, SongVideoProvider.youtube);
  });

  test('song model rejects incomplete Firestore data', () {
    final decoded = SongDocument.fromMap(
      id: 'invalid',
      map: const {'title': 'Missing fields'},
    );

    expect(decoded, isNull);
  });

  test('bundled catalog converts every legacy song without data loss', () {
    expect(bundledSongCatalog, hasLength(129));
    for (final song in bundledSongCatalog) {
      final decoded = SongDocument.fromMap(id: song.id, map: song.toMap());
      expect(decoded, isNotNull, reason: song.title);
      expect(decoded?.lyrics, song.lyrics, reason: song.title);
    }
  });

  test('family promise model round-trips through Firestore data', () {
    const promise = FamilyPromiseDocument(
      languageCode: 'pt',
      title: 'Promessa da Família',
      verses: ['Um', 'Dois'],
      enabled: true,
      sortOrder: 0,
    );

    final decoded = FamilyPromiseDocument.fromMap(promise.toMap());

    expect(decoded?.languageCode, 'pt');
    expect(decoded?.verses, ['Um', 'Dois']);
  });

  test('country promise defaults remove duplicate languages', () {
    final portugal = bundledFamilyPromisesForCountry(
      countryCode: 'pt',
      defaultLanguage: 'pt',
    );
    final england = bundledFamilyPromisesForCountry(
      countryCode: 'gb',
      defaultLanguage: 'en',
    );
    final spain = bundledFamilyPromisesForCountry(
      countryCode: 'es',
      defaultLanguage: 'es',
    );

    expect(portugal.map((item) => item.languageCode).toSet(), {
      'pt',
      'ko',
      'en',
    });
    expect(england.map((item) => item.languageCode).toSet(), {'ko', 'en'});
    expect(spain.map((item) => item.languageCode).toSet(), {'ko', 'en'});
  });

  test('new countries start with worship songs only', () {
    final portugal = bundledCatalogForCountry('pt');
    final spain = bundledCatalogForCountry('es');

    expect(portugal, hasLength(129));
    expect(spain, isNotEmpty);
    expect(
      spain.every((song) => song.category == SongCategory.worship),
      isTrue,
    );
  });
}
