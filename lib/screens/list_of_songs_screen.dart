import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../songs/songs.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class ListOfSongsScreen extends StatefulWidget {
  const ListOfSongsScreen({super.key});

  @override
  State<ListOfSongsScreen> createState() => _ListOfSongsScreenState();
}

class _ListOfSongsScreenState extends State<ListOfSongsScreen> {
  final _controller = TextEditingController();
  late List<SongsModel> _filteredSongs = songs;

  void _filterSong(String searchString) {
    setState(() {
      if (searchString.isEmpty) {
        _filteredSongs = songs;
        return;
      }
      _filteredSongs = songs
          .where(
              (s) => s.title.toLowerCase().contains(searchString.toLowerCase()))
          .toList();
    });
  }

  void _showSongsBy(SongsCategory? category, {bool? hasMusic}) {
    setState(() {
      if (hasMusic != null && hasMusic) {
        _filteredSongs = songs
            .where((element) => element.musicTrackPath.isNotEmpty)
            .toList();
      } else {
        _filteredSongs = songs
            .where((element) => category != null
                ? element.songsCategory == category &&
                    element.title.toLowerCase().contains(
                          _controller.text.toLowerCase(),
                        )
                : element.title
                    .toLowerCase()
                    .contains(_controller.text.toLowerCase()))
            .toList();
      }
    });
  }

  ButtonStyle _fillBy(SongsCategory category) {
    switch (category) {
      case SongsCategory.holy:
        return ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff1A237E),
        );
      case SongsCategory.convivial:
        return ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4CAF50),
        );
      case SongsCategory.english:
        return ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff90CAF9),
        );
      case SongsCategory.international:
        return ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff6B5B95),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SizedBox(
          height: 50.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: [
              const SizedBox(
                width: 42.0,
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  _showSongsBy(
                    null,
                    hasMusic: true,
                  );
                }),
                child: const Text('COM MUSICA'),
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  _showSongsBy(null);
                }),
                child: const Text('TODOS'),
              ),
              ElevatedButton(
                onPressed: () => _showSongsBy(SongsCategory.holy),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1A237E),
                ),
                child: const Text('CÂNTICOS SAGRADOS'),
              ),
              ElevatedButton(
                onPressed: () => _showSongsBy(SongsCategory.convivial),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4CAF50),
                ),
                child: const Text('CANÇÕES DE CONVÍVIO'),
              ),
              ElevatedButton(
                onPressed: () => _showSongsBy(SongsCategory.english),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff90CAF9),
                ),
                child: const Text('HOLY SONGS'),
              ),
              ElevatedButton(
                onPressed: () => _showSongsBy(SongsCategory.international),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6B5B95),
                ),
                child: const Text('WORSHIP SONGS (International)'),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.all(12.0),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                onChanged: (value) => _filterSong(value),
                textAlign: TextAlign.center,
                decoration:
                    const InputDecoration(hintText: 'Pesquise aqui uma canção'),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: _filteredSongs.length,
                itemBuilder: (context, index) {
                  return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: _fillBy(_filteredSongs[index].songsCategory),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _filteredSongs[index].musicTrackPath.isNotEmpty
                                ? const Icon(Icons.music_note_rounded)
                                : Container(),
                            _filteredSongs[index].musicTrackPath.isNotEmpty
                                ? const Icon(Icons.music_note_rounded)
                                : Container(),
                            Text(
                              '${_filteredSongs[index].title} | Pag ${_filteredSongs[index].page}',
                            ),
                            _filteredSongs[index].musicTrackPath.isNotEmpty
                                ? const Icon(Icons.music_note_rounded)
                                : Container(),
                            _filteredSongs[index].musicTrackPath.isNotEmpty
                                ? const Icon(Icons.music_note_rounded)
                                : Container(),
                          ],
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                SongScreen(song: _filteredSongs[index]),
                          ),
                        ),
                      ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SongScreen extends StatefulWidget {
  final SongsModel song;

  const SongScreen({Key? key, required this.song}) : super(key: key);

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late int _currentIndex = 0;
  bool coe = false;

  @override
  void initState() {
    if (widget.song.musicTrackPath.isNotEmpty) {
      _audioPlayer.setAsset(widget.song.musicTrackPath);
      _audioPlayer.positionStream.listen((event) {
        if (event.inSeconds == widget.song.timesToJump[_currentIndex]) {
          if (coe) {
            coe = false;
          } else {
            setState(() {
              _currentIndex++;
            });
          }
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _playerButton(PlayerState playerState) {
    // 1
    final processingState = playerState.processingState;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      // 2
      return Container(
        margin: const EdgeInsets.all(8.0),
        width: 64.0,
        height: 64.0,
        child: const CircularProgressIndicator(),
      );
    } else if (_audioPlayer.playing != true) {
      // 3
      return IconButton(
        icon: const Icon(Icons.play_arrow),
        iconSize: 64.0,
        onPressed: _audioPlayer.play,
      );
    } else if (processingState != ProcessingState.completed) {
      // 4
      return IconButton(
        icon: const Icon(Icons.pause),
        iconSize: 64.0,
        onPressed: _audioPlayer.pause,
      );
    } else {
      // 5
      return IconButton(
        icon: const Icon(Icons.replay),
        iconSize: 64.0,
        onPressed: () => _audioPlayer.seek(Duration.zero,
            index: _audioPlayer.effectiveIndices?.first),
      );
    }
  }

  Color _getColorBy(SongsCategory category) {
    switch (category) {
      case SongsCategory.holy:
        return const Color(0xff1A237E);
      case SongsCategory.convivial:
        return const Color(0xff4CAF50);
      case SongsCategory.english:
        return const Color(0xff90CAF9);
      case SongsCategory.international:
        return const Color(0xff6B5B95);
    }
  }

  Color _getColorByChorus() {
    if (_currentIndex % 2 == 0 && widget.song.isFirstChorus) {
      return Colors.blue;
    } else if (_currentIndex % 2 != 0 && widget.song.isSecondChorus) {
      return Colors.blue;
    } else {
      return Colors.black;
    }
  }

  Widget _buildSongWidget() {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(left: 48.0, right: 48.0),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _currentIndex > 0
                      ? ElevatedButton(
                          onPressed: () => setState(() {
                            coe = true;
                            _currentIndex--;
                            _audioPlayer.seek(Duration(
                                seconds: widget.song.times[_currentIndex]));
                          }),
                          child: const Text('<-'),
                        )
                      : Container(),
                  _currentIndex < widget.song.lyrics.length - 1
                      ? ElevatedButton(
                          onPressed: () => setState(
                            () {
                              coe = true;
                              _currentIndex++;
                              if (widget.song.times.isNotEmpty) {
                                _audioPlayer.seek(Duration(
                                    seconds: widget.song.times[_currentIndex]));
                              }
                            },
                          ),
                          child: const Text('->'),
                        )
                      : Container(),
                ],
              ),
            ),
            widget.song.musicTrackPath.isNotEmpty
                ? StreamBuilder<PlayerState>(
                    stream: _audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      return _playerButton(playerState!);
                    },
                  )
                : Container(),
            Text('${_currentIndex + 1}'),
            Text(
              widget.song.lyrics[_currentIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: kIsWeb ? 48 : 24,
                color: _getColorByChorus(),
              ),
            ),
            const SizedBox(
              height: 15.0,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.song.title} | Página ${widget.song.page}'),
        backgroundColor: _getColorBy(widget.song.songsCategory),
      ),
      body: RawKeyboardListener(
        autofocus: true,
        focusNode: FocusNode(),
        onKey: (RawKeyEvent event) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
            if (_currentIndex < widget.song.lyrics.length - 1) {
              setState(() {
                _currentIndex++;
              });
            }
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
            if (_currentIndex > 0) {
              setState(() {
                _currentIndex--;
              });
            }
          }
        },
        child: _buildSongWidget(),
      ),
    );
  }
}

// Task created after investigation.
// DIADFF-608
