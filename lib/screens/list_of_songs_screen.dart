import 'dart:async';

import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/services/offline_audio_cache.dart';
import 'package:ffpmupt/services/song_repository.dart';
import 'package:ffpmupt/songs/bundled_song_catalog.dart';
import 'package:ffpmupt/widgets/offering_payment_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

String _normalizeSongSearch(String value) {
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

  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final codeUnit in lower.codeUnits) {
    final character = String.fromCharCode(codeUnit);
    buffer.write(replacements[character] ?? character);
  }

  return buffer.toString();
}

class ListOfSongsScreen extends StatefulWidget {
  const ListOfSongsScreen({super.key});

  @override
  State<ListOfSongsScreen> createState() => _ListOfSongsScreenState();
}

class _ListOfSongsScreenState extends State<ListOfSongsScreen> {
  final _controller = TextEditingController();
  final _repository = SongRepository();
  final _offlineAudioCache = const OfflineAudioCache();
  StreamSubscription<SongCatalogState>? _catalogSubscription;
  List<SongDocument> _songs = bundledSongCatalog;
  SongCategory? _selectedCategory;
  bool _showOnlyWithMusic = false;
  String _searchQuery = '';

  List<SongDocument> get _filteredSongs {
    final query = _normalizeSongSearch(_searchQuery.trim());

    return _songs.where((song) {
      final searchableText = _normalizeSongSearch(
        [song.title, song.page, song.category.value, ...song.lyrics].join(' '),
      );
      final matchesSearch = query.isEmpty || searchableText.contains(query);
      final matchesCategory =
          _selectedCategory == null || song.category == _selectedCategory;
      final matchesMusic =
          !_showOnlyWithMusic || song.audioTracks.any((track) => track.enabled);

      return matchesSearch && matchesCategory && matchesMusic;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _cacheAudio(_songs);
    _catalogSubscription = _repository.watchCatalog().listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _songs = state.songs;
      });
      _cacheAudio(state.songs);
    });
  }

  void _cacheAudio(List<SongDocument> catalog) {
    _offlineAudioCache.cacheAll(
      catalog.expand(
        (song) => song.audioTracks
            .where((track) => track.enabled)
            .map((track) => track.url),
      ),
    );
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

  void _showAllSongs() {
    setState(() {
      _selectedCategory = null;
      _showOnlyWithMusic = false;
    });
  }

  void _clearSearch() {
    _controller.clear();
    _filterSong('');
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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
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
                      child: Column(
                        children: [
                          TextField(
                            controller: _controller,
                            onChanged: _filterSong,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: strings.searchSongHint,
                              suffixIcon: _searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: strings.clearSearch,
                                      icon: const Icon(Icons.close),
                                      onPressed: _clearSearch,
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: Text(strings.all),
                                selected:
                                    _selectedCategory == null &&
                                    !_showOnlyWithMusic,
                                onSelected: (_) => _showAllSongs(),
                              ),
                              FilterChip(
                                avatar: const Icon(Icons.music_note, size: 18),
                                label: Text(strings.withMusic),
                                selected: _showOnlyWithMusic,
                                onSelected: (_) => _toggleMusicFilter(),
                              ),
                              for (final category in SongCategory.values.where(
                                (category) => _songs.any(
                                  (song) => song.category == category,
                                ),
                              ))
                                FilterChip(
                                  label: Text(_labelBy(category, strings)),
                                  selected: _selectedCategory == category,
                                  selectedColor: _colorBy(
                                    category,
                                  ).withValues(alpha: 0.18),
                                  checkmarkColor: _colorBy(category),
                                  onSelected: (_) => _showSongsBy(category),
                                ),
                            ],
                          ),
                        ],
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
                        Text(
                          '${filteredSongs.length} ${strings.songCountSuffix} • ${strings.searchByTitlePageLyrics}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xff56635f),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredSongs.isEmpty
                        ? Center(
                            child: Text(
                              strings.noSongsFound,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: const Color(0xff56635f)),
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
                                    '${_labelBy(song.category, strings)} • ${strings.page} ${song.page}',
                                  ),
                                  isThreeLine: false,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SongScreen(song: song),
                                    ),
                                  ),
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

  const SongScreen({super.key, required this.song});

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  late int _currentIndex = 0;
  late double _lyricFontSize = kIsWeb ? 46 : 25;
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

  Widget _buildLyricCard({required Color color, required TextTheme textTheme}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        child: Column(
          children: [
            Text(
              '${_currentIndex + 1} / ${widget.song.lyrics.length}',
              style: textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.song.lyrics[_currentIndex],
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: _lyricFontSize,
                height: 1.28,
                color: _getColorByChorus(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongControls(AppStrings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          tooltip: strings.previousLyric,
          onPressed: _currentIndex == 0 ? null : _showPreviousLyric,
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: strings.decreaseTextSize,
          onPressed: _lyricFontSize <= 22 ? null : _decreaseLyricSize,
          icon: const Icon(Icons.text_decrease),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: strings.increaseTextSize,
          onPressed: _lyricFontSize >= 72 ? null : _increaseLyricSize,
          icon: const Icon(Icons.text_increase),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: strings.nextLyric,
          onPressed: _currentIndex == widget.song.lyrics.length - 1
              ? null
              : _showNextLyric,
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
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
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
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
                    Chip(
                      avatar: const Icon(Icons.description, size: 18),
                      label: Text('${strings.page} ${widget.song.page}'),
                    ),
                    if (_hasAudio)
                      Chip(
                        avatar: const Icon(Icons.music_note, size: 18),
                        label: Text(strings.audioAvailable),
                      ),
                    if (_isOfferingSong)
                      Chip(
                        avatar: const Icon(Icons.volunteer_activism, size: 18),
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
                    final lyricAndControls = Column(
                      children: [
                        _buildAudioPanel(strings),
                        if (_hasAudio) const SizedBox(height: 14),
                        _buildSongControls(strings),
                        const SizedBox(height: 14),
                        _buildLyricCard(color: color, textTheme: textTheme),
                        const SizedBox(height: 14),
                        _buildLyricNavigator(color, strings),
                      ],
                    );

                    if (!_isOfferingSong || constraints.maxWidth < 920) {
                      return Column(
                        children: [
                          lyricAndControls,
                          if (_isOfferingSong) ...[
                            const SizedBox(height: 20),
                            OfferingPaymentPanel(
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
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.song.title} | ${strings.page} ${widget.song.page}',
        ),
        backgroundColor: _getColorBy(widget.song.category),
        foregroundColor: Colors.white,
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
