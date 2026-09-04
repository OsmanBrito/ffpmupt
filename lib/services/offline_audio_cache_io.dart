import 'dart:async';

import 'package:ffpmupt/services/offline_audio_cache_state.dart';

class OfflineAudioCache {
  factory OfflineAudioCache() => _instance;

  OfflineAudioCache._();

  static final OfflineAudioCache _instance = OfflineAudioCache._();
  final _progressController =
      StreamController<OfflineAudioCacheProgress>.broadcast();

  Stream<OfflineAudioCacheProgress> get progress => _progressController.stream;

  OfflineAudioCacheProgress get currentProgress =>
      OfflineAudioCacheProgress.idle;

  void setAvailable(Iterable<String> urls) {}

  void downloadAvailable() {}

  void retry() {}
}
