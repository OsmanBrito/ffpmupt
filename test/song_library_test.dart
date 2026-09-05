import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/services/song_library_preferences.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/reading_song_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final songs = [
    _song(id: 'peace', title: 'Á Paz', page: '42', sortOrder: 2),
    _song(id: 'family', title: 'Blessed Family', page: '7', sortOrder: 1),
    _song(id: 'grace', title: 'Grace', page: '105', sortOrder: 3),
  ];

  test('song search finds an exact page number', () {
    final result = filterAndSortSongs(
      songs: songs,
      query: '42',
      view: SongLibraryView.all,
      sort: SongSort.catalogue,
    );

    expect(result.map((song) => song.id), ['peace']);
  });

  test('favorites and recent views use local song ids', () {
    final favorites = filterAndSortSongs(
      songs: songs,
      query: '',
      view: SongLibraryView.favorites,
      sort: SongSort.catalogue,
      favoriteIds: const {'grace'},
    );
    final recent = filterAndSortSongs(
      songs: songs,
      query: '',
      view: SongLibraryView.recent,
      sort: SongSort.catalogue,
      recentIds: const ['peace', 'family'],
    );

    expect(favorites.map((song) => song.id), ['grace']);
    expect(recent.map((song) => song.id), ['peace', 'family']);
  });

  test('songs sort alphabetically without accents or by numeric page', () {
    final alphabetical = filterAndSortSongs(
      songs: songs,
      query: '',
      view: SongLibraryView.all,
      sort: SongSort.alphabetical,
    );
    final byPage = filterAndSortSongs(
      songs: songs,
      query: '',
      view: SongLibraryView.all,
      sort: SongSort.page,
    );

    expect(alphabetical.map((song) => song.id), ['peace', 'family', 'grace']);
    expect(byPage.map((song) => song.id), ['family', 'peace', 'grace']);
  });

  test('reading and song strings cover every supported language', () {
    for (final language in AppLanguage.values) {
      final strings = ReadingSongStrings.of(language);
      for (final key in ReadingSongText.values) {
        expect(strings[key].trim(), isNotEmpty, reason: '$language / $key');
        expect(strings[key], isNot(key.name), reason: '$language / $key');
      }
    }
  });
}

SongDocument _song({
  required String id,
  required String title,
  required String page,
  required int sortOrder,
}) {
  return SongDocument(
    id: id,
    title: title,
    page: page,
    category: SongCategory.holy,
    languageCode: 'pt',
    lyrics: const ['Sample lyric'],
    chorusMode: ChorusMode.none,
    enabled: true,
    sortOrder: sortOrder,
    audioTracks: const [],
    videoLinks: const [],
  );
}
