import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/settings/local_store.dart';

enum SongLibraryView { all, favorites, recent }

enum SongSort { catalogue, alphabetical, page }

class SongLibraryState {
  const SongLibraryState({
    this.favoriteIds = const <String>{},
    this.recentIds = const <String>[],
  });

  final Set<String> favoriteIds;
  final List<String> recentIds;
}

class SongLibraryPreferences {
  SongLibraryPreferences({required this.countryCode});

  final String countryCode;

  String get _favoritesKey => 'songs.$countryCode.favorites.v1';
  String get _recentKey => 'songs.$countryCode.recent.v1';

  Future<SongLibraryState> load() async {
    final favorites = await LocalStore.getStringList(_favoritesKey) ?? const [];
    final recent = await LocalStore.getStringList(_recentKey) ?? const [];
    return SongLibraryState(favoriteIds: favorites.toSet(), recentIds: recent);
  }

  Future<void> saveFavorites(Set<String> ids) {
    final sorted = ids.toList()..sort();
    return LocalStore.setStringList(_favoritesKey, sorted);
  }

  Future<List<String>> markRecent(String id, List<String> current) async {
    final updated = <String>[
      id,
      ...current.where((item) => item != id),
    ].take(20).toList(growable: false);
    await LocalStore.setStringList(_recentKey, updated);
    return updated;
  }
}

List<SongDocument> filterAndSortSongs({
  required Iterable<SongDocument> songs,
  required String query,
  required SongLibraryView view,
  required SongSort sort,
  SongCategory? category,
  bool onlyWithAudio = false,
  Set<String> favoriteIds = const <String>{},
  List<String> recentIds = const <String>[],
}) {
  final normalizedQuery = normalizeSongSearch(query.trim());
  final recentPositions = <String, int>{
    for (var index = 0; index < recentIds.length; index++)
      recentIds[index]: index,
  };
  final filtered = songs.where((song) {
    final searchableText = normalizeSongSearch(
      [song.title, song.page, song.category.value, ...song.lyrics].join(' '),
    );
    final matchesSearch =
        normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
    final matchesCategory = category == null || song.category == category;
    final matchesAudio =
        !onlyWithAudio || song.audioTracks.any((track) => track.enabled);
    final matchesView = switch (view) {
      SongLibraryView.all => true,
      SongLibraryView.favorites => favoriteIds.contains(song.id),
      SongLibraryView.recent => recentPositions.containsKey(song.id),
    };
    return matchesSearch && matchesCategory && matchesAudio && matchesView;
  }).toList();

  int compare(SongDocument left, SongDocument right) {
    if (view == SongLibraryView.recent && sort == SongSort.catalogue) {
      return (recentPositions[left.id] ?? 999).compareTo(
        recentPositions[right.id] ?? 999,
      );
    }
    return switch (sort) {
      SongSort.catalogue => left.sortOrder.compareTo(right.sortOrder),
      SongSort.alphabetical => normalizeSongSearch(
        left.title,
      ).compareTo(normalizeSongSearch(right.title)),
      SongSort.page => _pageNumber(
        left.page,
      ).compareTo(_pageNumber(right.page)),
    };
  }

  filtered.sort(compare);
  return filtered;
}

String normalizeSongSearch(String value) {
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'õ': 'o',
    'ô': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  final buffer = StringBuffer();
  for (final codeUnit in value.toLowerCase().codeUnits) {
    final character = String.fromCharCode(codeUnit);
    buffer.write(replacements[character] ?? character);
  }
  return buffer.toString();
}

int _pageNumber(String value) {
  final match = RegExp(r'\d+').firstMatch(value);
  return int.tryParse(match?.group(0) ?? '') ?? (1 << 30);
}
