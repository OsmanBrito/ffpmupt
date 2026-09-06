import 'dart:async';

import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/services/song_library_preferences.dart';
import 'package:ffpmupt/services/song_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/settings/reading_song_strings.dart';
import 'package:ffpmupt/songs/bundled_song_catalog.dart';
import 'package:ffpmupt/theme/app_theme.dart';
import 'package:ffpmupt/widgets/offering_payment_panel.dart';
import 'package:ffpmupt/widgets/reading_mode_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class ListOfSongsScreen extends StatefulWidget {
  const ListOfSongsScreen({
    super.key,
    required this.countryCode,
    this.enableLocalLibrary = true,
    this.watchCatalog = true,
  });

  final String countryCode;

  @visibleForTesting
  final bool enableLocalLibrary;

  @visibleForTesting
  final bool watchCatalog;

  @override
  State<ListOfSongsScreen> createState() => _ListOfSongsScreenState();
}

class _ListOfSongsScreenState extends State<ListOfSongsScreen> {
  final _controller = TextEditingController();
  late final SongRepository _repository;
  late final SongLibraryPreferences _libraryPreferences;
  StreamSubscription<SongCatalogState>? _catalogSubscription;
  late List<SongDocument> _songs;
  SongCategory? _selectedCategory;
  bool _showOnlyWithMusic = false;
  Set<String> _favoriteIds = <String>{};
  List<String> _recentIds = <String>[];
  SongLibraryView _libraryView = SongLibraryView.all;
  SongSort _sort = SongSort.catalogue;
  String _searchQuery = '';

  List<SongDocument> get _filteredSongs {
    return filterAndSortSongs(
      songs: _songs,
      query: _searchQuery,
      view: _libraryView,
      sort: _sort,
      category: _selectedCategory,
      onlyWithAudio: _showOnlyWithMusic,
      favoriteIds: _favoriteIds,
      recentIds: _recentIds,
    );
  }

  @override
  void initState() {
    super.initState();
    _repository = SongRepository(countryCode: widget.countryCode);
    _libraryPreferences = SongLibraryPreferences(
      countryCode: widget.countryCode,
    );
    _songs = bundledCatalogForCountry(widget.countryCode);
    if (widget.enableLocalLibrary) {
      unawaited(_loadLibraryState());
    }
    if (widget.watchCatalog) {
      _catalogSubscription = _repository.watchCatalog().listen((state) {
        if (!mounted) {
          return;
        }
        setState(() {
          _songs = state.songs;
        });
      });
    }
  }

  Future<void> _loadLibraryState() async {
    final state = await _libraryPreferences.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _favoriteIds = state.favoriteIds;
      _recentIds = state.recentIds;
    });
  }

  void _filterSong(String searchString) {
    setState(() {
      _searchQuery = searchString;
    });
  }

  void _showSongsBy(SongCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _toggleMusicFilter() {
    setState(() {
      _showOnlyWithMusic = !_showOnlyWithMusic;
    });
  }

  Future<void> _toggleFavorite(SongDocument song) async {
    final updated = {..._favoriteIds};
    if (!updated.add(song.id)) {
      updated.remove(song.id);
    }
    setState(() => _favoriteIds = updated);
    await _libraryPreferences.saveFavorites(updated);
  }

  Future<void> _openSong(SongDocument song) async {
    final recent = await _libraryPreferences.markRecent(song.id, _recentIds);
    if (mounted) {
      setState(() => _recentIds = recent);
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SongScreen(
          song: song,
          countryCode: widget.countryCode,
          initiallyFavorite: _favoriteIds.contains(song.id),
          onFavoriteChanged: (favorite) {
            final updated = {..._favoriteIds};
            favorite ? updated.add(song.id) : updated.remove(song.id);
            if (mounted) {
              setState(() => _favoriteIds = updated);
            }
            unawaited(_libraryPreferences.saveFavorites(updated));
          },
        ),
      ),
    );
  }

  void _clearSearch() {
    _controller.clear();
    _filterSong('');
  }

  void _clearSearchAndFilters() {
    _controller.clear();
    setState(() {
      _searchQuery = '';
      _libraryView = SongLibraryView.all;
      _selectedCategory = null;
      _showOnlyWithMusic = false;
    });
  }

  @override
  void dispose() {
    _catalogSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _colorBy(SongCategory category) {
    switch (category) {
      case SongCategory.holy:
        return const Color(0xff1f3f76);
      case SongCategory.fellowship:
        return const Color(0xff3f7c4e);
      case SongCategory.english:
        return const Color(0xff8b6f1d);
      case SongCategory.worship:
        return const Color(0xff7d2f3a);
      case SongCategory.international:
        return const Color(0xff65508e);
    }
  }

  String _labelBy(SongCategory category, AppStrings strings) {
    switch (category) {
      case SongCategory.holy:
        return strings.holySongs;
      case SongCategory.fellowship:
        return strings.convivialSongs;
      case SongCategory.english:
        return strings.englishSongs;
      case SongCategory.worship:
        return strings.worshipSongs;
      case SongCategory.international:
        return strings.internationalSongs;
    }
  }

  String _sortLabel(SongSort sort, ReadingSongStrings copy) {
    return copy[switch (sort) {
      SongSort.catalogue => ReadingSongText.catalogueOrder,
      SongSort.alphabetical => ReadingSongText.alphabeticalOrder,
      SongSort.page => ReadingSongText.pageOrder,
    }];
  }

  int get _activeFilterCount =>
      (_selectedCategory == null ? 0 : 1) + (_showOnlyWithMusic ? 1 : 0);

  Widget _buildCategoryFilters(AppStrings strings) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          avatar: const Icon(Icons.music_note, size: 18),
          label: Text(strings.withMusic),
          selected: _showOnlyWithMusic,
          onSelected: (_) => _toggleMusicFilter(),
        ),
        for (final category in SongCategory.values.where(
          (category) => _songs.any((song) => song.category == category),
        ))
          FilterChip(
            label: Text(_labelBy(category, strings)),
            selected: _selectedCategory == category,
            selectedColor: _colorBy(category).withValues(alpha: 0.18),
            checkmarkColor: _colorBy(category),
            onSelected: (_) =>
                _showSongsBy(_selectedCategory == category ? null : category),
          ),
      ],
    );
  }

  Future<void> _showMobileFilters(AppStrings strings, ReadingSongStrings copy) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: StatefulBuilder(
              builder: (context, setModalState) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    copy[ReadingSongText.filters],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            avatar: const Icon(Icons.music_note, size: 18),
                            label: Text(strings.withMusic),
                            selected: _showOnlyWithMusic,
                            onSelected: (_) {
                              _toggleMusicFilter();
                              setModalState(() {});
                            },
                          ),
                          for (final category in SongCategory.values.where(
                            (category) =>
                                _songs.any((song) => song.category == category),
                          ))
                            FilterChip(
                              label: Text(_labelBy(category, strings)),
                              selected: _selectedCategory == category,
                              selectedColor: _colorBy(
                                category,
                              ).withValues(alpha: 0.18),
                              onSelected: (_) {
                                _showSongsBy(
                                  _selectedCategory == category
                                      ? null
                                      : category,
                                );
                                setModalState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      MaterialLocalizations.of(context).closeButtonLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageScope.watch(context).language;
    final strings = AppStrings.of(language);
    final copy = ReadingSongStrings.of(language);
    final filteredSongs = _filteredSongs;

    return Scaffold(
      appBar: AppBar(title: Text(strings.songs)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 640;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _controller,
                                onChanged: _filterSong,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: copy[ReadingSongText.searchSong],
                                  suffixIcon: _searchQuery.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: strings.clearSearch,
                                          icon: const Icon(Icons.close),
                                          onPressed: _clearSearch,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          ChoiceChip(
                                            label: Text(strings.all),
                                            selected:
                                                _libraryView ==
                                                SongLibraryView.all,
                                            onSelected: (_) => setState(
                                              () => _libraryView =
                                                  SongLibraryView.all,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            avatar: const Icon(
                                              Icons.favorite_outline,
                                              size: 18,
                                            ),
                                            label: Text(
                                              copy[ReadingSongText.favorites],
                                            ),
                                            selected:
                                                _libraryView ==
                                                SongLibraryView.favorites,
                                            onSelected: (_) => setState(
                                              () => _libraryView =
                                                  SongLibraryView.favorites,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            avatar: const Icon(
                                              Icons.history,
                                              size: 18,
                                            ),
                                            label: Text(
                                              copy[ReadingSongText.recent],
                                            ),
                                            selected:
                                                _libraryView ==
                                                SongLibraryView.recent,
                                            onSelected: (_) => setState(
                                              () => _libraryView =
                                                  SongLibraryView.recent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<SongSort>(
                                    tooltip: copy[ReadingSongText.sortBy],
                                    initialValue: _sort,
                                    onSelected: (value) =>
                                        setState(() => _sort = value),
                                    itemBuilder: (context) => [
                                      for (final sort in SongSort.values)
                                        PopupMenuItem(
                                          value: sort,
                                          child: Row(
                                            children: [
                                              if (_sort == sort)
                                                const Icon(
                                                  Icons.check,
                                                  size: 18,
                                                )
                                              else
                                                const SizedBox(width: 18),
                                              const SizedBox(width: 10),
                                              Text(_sortLabel(sort, copy)),
                                            ],
                                          ),
                                        ),
                                    ],
                                    icon: const Icon(Icons.sort),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (compact)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showMobileFilters(strings, copy),
                                    icon: Icon(
                                      _activeFilterCount == 0
                                          ? Icons.filter_list
                                          : Icons.filter_list_alt,
                                    ),
                                    label: Text(
                                      _activeFilterCount == 0
                                          ? copy[ReadingSongText.filters]
                                          : '${copy[ReadingSongText.filters]} ($_activeFilterCount)',
                                    ),
                                  ),
                                )
                              else
                                _buildCategoryFilters(strings),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${filteredSongs.length} ${strings.songCountSuffix} · ${_sortLabel(_sort, copy)}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredSongs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_outlined, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  strings.noSongsFound,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: const Color(0xff56635f),
                                      ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton.tonalIcon(
                                  onPressed: _clearSearchAndFilters,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(strings.clearSearch),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: filteredSongs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final song = filteredSongs[index];
                              final color = _colorBy(song.category);

                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: color.withValues(
                                      alpha: 0.14,
                                    ),
                                    foregroundColor: color,
                                    child:
                                        song.audioTracks.any(
                                          (track) => track.enabled,
                                        )
                                        ? const Icon(Icons.music_note)
                                        : const Icon(Icons.lyrics),
                                  ),
                                  title: Text(
                                    song.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      _labelBy(song.category, strings),
                                      if (song.page.trim().isNotEmpty &&
                                          song.page.trim() != '0')
                                        '${strings.page} ${song.page}',
                                      if (song.audioTracks.any(
                                        (track) => track.enabled,
                                      ))
                                        '♪ ${copy[ReadingSongText.audio]}',
                                      if (song.hasChords)
                                        '♯ ${copy[ReadingSongText.chords]}',
                                    ].join(' · '),
                                  ),
                                  trailing: IconButton(
                                    tooltip:
                                        copy[_favoriteIds.contains(song.id)
                                            ? ReadingSongText.removeFavorite
                                            : ReadingSongText.favorite],
                                    onPressed: () => _toggleFavorite(song),
                                    icon: Icon(
                                      _favoriteIds.contains(song.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _favoriteIds.contains(song.id)
                                          ? AppColors.berry
                                          : null,
                                    ),
                                  ),
                                  onTap: () => _openSong(song),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SongScreen extends StatefulWidget {
  final SongDocument song;
  final String countryCode;
  final bool initiallyFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const SongScreen({
    super.key,
    required this.song,
    required this.countryCode,
    this.initiallyFavorite = false,
    this.onFavoriteChanged,
  });

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  late int _currentIndex = 0;
  late double _lyricFontSize = kIsWeb ? 30 : 25;
  late bool _isFavorite = widget.initiallyFavorite;
  bool _isPresentation = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  SongAudioTrack? get _audioTrack {
    final tracks =
        widget.song.audioTracks
            .where((track) => track.enabled && track.url.trim().isNotEmpty)
            .toList()
          ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return tracks.firstOrNull;
  }

  bool get _hasAudio => _audioTrack != null;

  bool get _isOfferingSong => widget.song.page.trim() == '7';

  @override
  void initState() {
    super.initState();
    if (_hasAudio) {
      unawaited(_loadAudio(_audioTrack!.url));
      _positionSubscription = _audioPlayer.positionStream.listen(
        _handleAudioPosition,
      );
      _durationSubscription = _audioPlayer.durationStream.listen(
        _handleAudioDuration,
      );
    }
  }

  Future<void> _loadAudio(String source) async {
    try {
      if (source.startsWith('assets/')) {
        await _audioPlayer.setAsset(source);
      } else {
        await _audioPlayer.setUrl(source);
      }
    } on PlayerException catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to load audio: $error');
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleAudioDuration(Duration? duration) {
    if (!mounted) {
      return;
    }

    setState(() {
      _audioDuration = duration ?? Duration.zero;
    });
  }

  void _handleAudioPosition(Duration position) {
    if (!mounted) {
      return;
    }

    var nextIndex = _currentIndex;
    final cannotSyncLyric =
        _audioTrack == null ||
        _audioTrack!.verseChangeSeconds.isEmpty ||
        _currentIndex >= widget.song.lyrics.length - 1 ||
        _currentIndex >= _audioTrack!.verseChangeSeconds.length;

    if (cannotSyncLyric) {
      setState(() {
        _audioPosition = position;
      });
      return;
    }

    if (position.inSeconds >= _audioTrack!.verseChangeSeconds[_currentIndex]) {
      nextIndex = _currentIndex + 1;
    }

    setState(() {
      _audioPosition = position;
      _currentIndex = nextIndex;
    });
  }

  void _showPreviousLyric() {
    if (_currentIndex == 0) {
      return;
    }

    _showLyricAt(_currentIndex - 1);
  }

  void _showNextLyric() {
    if (_currentIndex >= widget.song.lyrics.length - 1) {
      return;
    }

    _showLyricAt(_currentIndex + 1);
  }

  void _showLyricAt(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (_audioTrack != null && _audioTrack!.verseStartSeconds.length > index) {
      unawaited(
        _audioPlayer.seek(
          Duration(seconds: _audioTrack!.verseStartSeconds[index]),
        ),
      );
    }
  }

  void _increaseLyricSize() {
    setState(() {
      _lyricFontSize = (_lyricFontSize + 4).clamp(22, 72);
    });
  }

  void _decreaseLyricSize() {
    setState(() {
      _lyricFontSize = (_lyricFontSize - 4).clamp(22, 72);
    });
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteChanged?.call(_isFavorite);
  }

  void _toggleAudio() {
    if (!_hasAudio) {
      return;
    }

    if (_audioPlayer.playing) {
      unawaited(_audioPlayer.pause());
    } else {
      _playAudio();
    }
  }

  void _playAudio() {
    unawaited(
      _audioPlayer.play().catchError((Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint('Unable to start audio: $error');
        }
      }),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  Widget _playerButton(PlayerState playerState) {
    final processingState = playerState.processingState;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      return Container(
        margin: const EdgeInsets.all(8.0),
        width: 48.0,
        height: 48.0,
        child: const CircularProgressIndicator(),
      );
    } else if (_audioPlayer.playing != true) {
      return IconButton.filled(
        icon: const Icon(Icons.play_arrow),
        iconSize: 40.0,
        onPressed: _playAudio,
      );
    } else if (processingState != ProcessingState.completed) {
      return IconButton.filled(
        icon: const Icon(Icons.pause),
        iconSize: 40.0,
        onPressed: () => unawaited(_audioPlayer.pause()),
      );
    } else {
      return IconButton.filled(
        icon: const Icon(Icons.replay),
        iconSize: 40.0,
        onPressed: () => unawaited(
          _audioPlayer.seek(
            Duration.zero,
            index: _audioPlayer.effectiveIndices.first,
          ),
        ),
      );
    }
  }

  Color _getColorBy(SongCategory category) {
    switch (category) {
      case SongCategory.holy:
        return const Color(0xff1f3f76);
      case SongCategory.fellowship:
        return const Color(0xff3f7c4e);
      case SongCategory.english:
        return const Color(0xff8b6f1d);
      case SongCategory.worship:
        return const Color(0xff7d2f3a);
      case SongCategory.international:
        return const Color(0xff65508e);
    }
  }

  String _getLabelBy(SongCategory category, AppStrings strings) {
    switch (category) {
      case SongCategory.holy:
        return strings.holySongs;
      case SongCategory.fellowship:
        return strings.convivialSongs;
      case SongCategory.english:
        return strings.englishSongs;
      case SongCategory.worship:
        return strings.worshipSongs;
      case SongCategory.international:
        return strings.internationalSongs;
    }
  }

  Color _getColorByChorus() {
    if (_currentIndex % 2 == 0 && widget.song.chorusMode == ChorusMode.first) {
      return const Color(0xff1f3f76);
    } else if (_currentIndex % 2 != 0 &&
        widget.song.chorusMode == ChorusMode.second) {
      return const Color(0xff1f3f76);
    } else {
      return const Color(0xff293833);
    }
  }

  Widget _buildLyricCard({
    required Color color,
    required TextTheme textTheme,
    required ReadingSongStrings copy,
  }) {
    final displayedFontSize = _isPresentation && _lyricFontSize < 48
        ? 48.0
        : _lyricFontSize;
    final chords = widget.song.chordsForVerse(_currentIndex);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_currentIndex + 1} / ${widget.song.lyrics.length}',
              style: textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            if (chords.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.piano_outlined, size: 18, color: color),
                        const SizedBox(width: 7),
                        Text(
                          copy[ReadingSongText.chords],
                          style: textTheme.labelLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      chords,
                      style: textTheme.titleLarge?.copyWith(
                        color: color,
                        fontFamily: 'monospace',
                        fontSize: (displayedFontSize * 0.72).clamp(18, 40),
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              widget.song.lyrics[_currentIndex],
              textAlign: _isPresentation ? TextAlign.center : TextAlign.start,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: displayedFontSize,
                height: _isPresentation ? 1.28 : 1.5,
                color: _getColorByChorus(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongControls(ReadingSongStrings copy) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabels = constraints.maxWidth >= 620;
        final controls =
            <({String label, IconData icon, VoidCallback? onPressed})>[
              (
                label: copy[ReadingSongText.previous],
                icon: Icons.arrow_back,
                onPressed: _currentIndex == 0 ? null : _showPreviousLyric,
              ),
              (
                label: copy[ReadingSongText.smallerText],
                icon: Icons.text_decrease,
                onPressed: _lyricFontSize <= 22 ? null : _decreaseLyricSize,
              ),
              (
                label: copy[ReadingSongText.largerText],
                icon: Icons.text_increase,
                onPressed: _lyricFontSize >= 72 ? null : _increaseLyricSize,
              ),
              (
                label: copy[ReadingSongText.next],
                icon: Icons.arrow_forward,
                onPressed: _currentIndex == widget.song.lyrics.length - 1
                    ? null
                    : _showNextLyric,
              ),
            ];
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final control in controls)
              if (showLabels)
                FilledButton.tonalIcon(
                  onPressed: control.onPressed,
                  icon: Icon(control.icon),
                  label: Text(control.label),
                )
              else
                IconButton.filledTonal(
                  tooltip: control.label,
                  onPressed: control.onPressed,
                  icon: Icon(control.icon),
                ),
          ],
        );
      },
    );
  }

  Widget _buildAudioPanel(AppStrings strings) {
    if (!_hasAudio) {
      return const SizedBox.shrink();
    }

    final duration = _audioDuration;
    final maxMilliseconds = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final positionMilliseconds = _audioPosition.inMilliseconds.clamp(
      0,
      maxMilliseconds.toInt(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                if (playerState == null) {
                  return Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 40.0,
                    height: 40.0,
                    child: const CircularProgressIndicator(),
                  );
                }

                return _playerButton(playerState);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        strings.audioAvailable,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_formatDuration(_audioPosition)} / ${_formatDuration(duration)}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xff56635f),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: positionMilliseconds.toDouble(),
                    max: maxMilliseconds,
                    onChanged: (value) => unawaited(
                      _audioPlayer.seek(Duration(milliseconds: value.round())),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricNavigator(Color color, AppStrings strings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < widget.song.lyrics.length; index++)
              Tooltip(
                message: '${strings.verse} ${index + 1}',
                child: ChoiceChip(
                  label: Text('${index + 1}'),
                  selected: _currentIndex == index,
                  selectedColor: color.withValues(alpha: 0.18),
                  checkmarkColor: color,
                  onSelected: (_) => _showLyricAt(index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongWidget() {
    final color = _getColorBy(widget.song.category);
    final language = AppLanguageScope.watch(context).language;
    final strings = AppStrings.of(language);
    final copy = ReadingSongStrings.of(language);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                if (!_isPresentation)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.menu_book, size: 18),
                        label: Text(_getLabelBy(widget.song.category, strings)),
                        backgroundColor: color.withValues(alpha: 0.14),
                        side: BorderSide(color: color.withValues(alpha: 0.2)),
                      ),
                      if (widget.song.page.trim().isNotEmpty &&
                          widget.song.page.trim() != '0')
                        Chip(
                          avatar: const Icon(Icons.description, size: 18),
                          label: Text('${strings.page} ${widget.song.page}'),
                        ),
                      if (_hasAudio)
                        Chip(
                          avatar: const Icon(Icons.music_note, size: 18),
                          label: Text(strings.audioAvailable),
                        ),
                      if (widget.song.hasChords)
                        Chip(
                          avatar: const Icon(Icons.piano_outlined, size: 18),
                          label: Text(copy[ReadingSongText.chords]),
                        ),
                      if (_isOfferingSong)
                        Chip(
                          avatar: const Icon(
                            Icons.volunteer_activism,
                            size: 18,
                          ),
                          label: Text(strings.offerings),
                          backgroundColor: const Color(
                            0xff2f6b4f,
                          ).withValues(alpha: 0.14),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final lyricAndControls = ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _isPresentation
                            ? AppTypography.presentationWidth
                            : AppTypography.readingWidth,
                      ),
                      child: Column(
                        children: [
                          if (!_isPresentation) _buildAudioPanel(strings),
                          if (_hasAudio && !_isPresentation)
                            const SizedBox(height: 14),
                          _buildSongControls(copy),
                          const SizedBox(height: 14),
                          _buildLyricCard(
                            color: color,
                            textTheme: textTheme,
                            copy: copy,
                          ),
                          if (!_isPresentation) ...[
                            const SizedBox(height: 14),
                            _buildLyricNavigator(color, strings),
                          ],
                        ],
                      ),
                    );

                    if (!_isOfferingSong || constraints.maxWidth < 920) {
                      return Column(
                        children: [
                          lyricAndControls,
                          if (_isOfferingSong) ...[
                            const SizedBox(height: 20),
                            OfferingPaymentPanel(
                              countryCode: widget.countryCode,
                              strings: strings,
                              compact: true,
                              showNote: false,
                            ),
                          ],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: lyricAndControls),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 360,
                          child: OfferingPaymentPanel(
                            countryCode: widget.countryCode,
                            strings: strings,
                            compact: true,
                            showNote: false,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageScope.watch(context).language;
    final strings = AppStrings.of(language);
    final copy = ReadingSongStrings.of(language);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.song.page.trim().isEmpty || widget.song.page.trim() == '0'
              ? widget.song.title
              : '${widget.song.title} | ${strings.page} ${widget.song.page}',
        ),
        actions: [
          IconButton(
            tooltip:
                copy[_isFavorite
                    ? ReadingSongText.removeFavorite
                    : ReadingSongText.favorite],
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.berry : null,
            ),
          ),
          ReadingModeButton(
            isPresentation: _isPresentation,
            onPressed: () => setState(() => _isPresentation = !_isPresentation),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: KeyboardListener(
        autofocus: true,
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is! KeyDownEvent) {
            return;
          }

          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _showNextLyric();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _showPreviousLyric();
          } else if (event.logicalKey == LogicalKeyboardKey.space) {
            _toggleAudio();
          } else if (event.logicalKey == LogicalKeyboardKey.equal ||
              event.logicalKey == LogicalKeyboardKey.add) {
            _increaseLyricSize();
          } else if (event.logicalKey == LogicalKeyboardKey.minus ||
              event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
            _decreaseLyricSize();
          }
        },
        child: _buildSongWidget(),
      ),
    );
  }
}
