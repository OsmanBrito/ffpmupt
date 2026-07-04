import 'dart:js_interop';

@JS('ffpmuCacheAudio')
external void _cacheAudio(JSArray<JSString> urls);

class OfflineAudioCache {
  const OfflineAudioCache();

  void cacheAll(Iterable<String> urls) {
    final uniqueUrls = urls.where((url) => url.trim().isNotEmpty).toSet();
    if (uniqueUrls.isEmpty) {
      return;
    }
    _cacheAudio(uniqueUrls.map((url) => url.toJS).toList().toJS);
  }
}
