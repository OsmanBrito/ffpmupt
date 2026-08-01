import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/songs/songs.dart' as legacy;

final List<SongDocument> bundledSongCatalog = List.unmodifiable(
  legacy.songs.indexed.map((entry) {
    final index = entry.$1;
    final song = entry.$2;
    final audioTracks = song.musicTrackPath.isEmpty
        ? const <SongAudioTrack>[]
        : [
            SongAudioTrack(
              id: 'principal',
              label: 'Principal',
              url: song.musicTrackPath,
              storagePath: null,
              verseStartSeconds: song.times,
              verseChangeSeconds: song.timesToJump,
              enabled: true,
              sortOrder: 0,
            ),
          ];

    return SongDocument(
      id: 'bundled-${index.toString().padLeft(3, '0')}',
      title: song.title,
      page: song.page,
      category: _categoryFromLegacy(song.songsCategory),
      languageCode: _languageFromLegacy(song.songsCategory),
      lyrics: song.lyrics,
      chorusMode: song.isFirstChorus
          ? ChorusMode.first
          : song.isSecondChorus
          ? ChorusMode.second
          : ChorusMode.none,
      enabled: true,
      sortOrder: index,
      audioTracks: audioTracks,
      videoLinks: const [],
    );
  }),
);

List<SongDocument> bundledCatalogForCountry(String countryCode) {
  final normalized = bundledSongCatalog.map(_normalizeWorship).toList();
  if (countryCode.toLowerCase() == 'pt') {
    return normalized;
  }
  return normalized
      .where((song) => song.category == SongCategory.worship)
      .toList();
}

SongDocument normalizeLegacyWorshipSong(SongDocument song) {
  return _normalizeWorship(song);
}

SongDocument _normalizeWorship(SongDocument song) {
  return song.category == SongCategory.international
      ? song.copyWith(category: SongCategory.worship)
      : song;
}

SongCategory _categoryFromLegacy(legacy.SongsCategory category) {
  return switch (category) {
    legacy.SongsCategory.holy => SongCategory.holy,
    legacy.SongsCategory.convivial => SongCategory.fellowship,
    legacy.SongsCategory.english => SongCategory.english,
    legacy.SongsCategory.international => SongCategory.international,
  };
}

String _languageFromLegacy(legacy.SongsCategory category) {
  return switch (category) {
    legacy.SongsCategory.holy || legacy.SongsCategory.convivial => 'pt',
    legacy.SongsCategory.english => 'en',
    legacy.SongsCategory.international => 'mul',
  };
}
