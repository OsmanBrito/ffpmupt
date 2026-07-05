import 'dart:async';
import 'dart:js_interop';

import 'package:ffpmupt/services/offline_audio_cache_state.dart';

@JS('ffpmuCacheAudio')
external void _cacheAudio(JSArray<JSString> urls);

@JS('ffpmuListenAudioCache')
external void _listenAudioCache(JSFunction listener);

class OfflineAudioCache {
  factory OfflineAudioCache() => _instance;

  OfflineAudioCache._() {
    _progressListener = _handleProgress.toJS;
    _listenAudioCache(_progressListener);
  }

  static final OfflineAudioCache _instance = OfflineAudioCache._();
  final _progressController =
      StreamController<OfflineAudioCacheProgress>.broadcast();
  late final JSFunction _progressListener;
  OfflineAudioCacheProgress _currentProgress = OfflineAudioCacheProgress.idle;

  Stream<OfflineAudioCacheProgress> get progress => _progressController.stream;

  OfflineAudioCacheProgress get currentProgress => _currentProgress;

  void cacheAll(Iterable<String> urls) {
    final uniqueUrls = urls.where((url) => url.trim().isNotEmpty).toSet();
    if (uniqueUrls.isEmpty) {
      return;
    }
    _cacheAudio(uniqueUrls.map((url) => url.toJS).toList().toJS);
  }

  void _handleProgress(JSAny? value) {
    final data = value?.dartify();
    if (data is! Map) {
      return;
    }

    final status = switch (data['status']) {
      'checking' => OfflineAudioCacheStatus.checking,
      'downloading' => OfflineAudioCacheStatus.downloading,
      'ready' => OfflineAudioCacheStatus.ready,
      'partial' => OfflineAudioCacheStatus.partial,
      _ => OfflineAudioCacheStatus.idle,
    };
    final progress = OfflineAudioCacheProgress(
      status: status,
      completed: (data['completed'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      failed: (data['failed'] as num?)?.toInt() ?? 0,
    );
    _currentProgress = progress;
    _progressController.add(progress);
  }
}
