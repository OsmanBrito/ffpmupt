import 'package:ffpmupt/content/family_promise.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PledgeSpeaker {
  PledgeSpeaker();

  final FlutterTts _flutterTts = FlutterTts();
  bool _hasConfiguredKoreanVoice = false;
  void Function()? onFinished;

  Future<void> configure() async {
    _flutterTts.setCompletionHandler(() => onFinished?.call());
    _flutterTts.setCancelHandler(() => onFinished?.call());
    _flutterTts.setErrorHandler((message) => onFinished?.call());

    await _configureKoreanVoice();
  }

  Future<void> _configureKoreanVoice() async {
    try {
      await _flutterTts.setLanguage(koreanFamilyPromiseTtsLocale);
      await _flutterTts.setSpeechRate(0.42);
      await _flutterTts.setPitch(1);
    } catch (_) {
      return;
    }

    if (_hasConfiguredKoreanVoice) {
      return;
    }

    final dynamic voices;
    try {
      voices = await _flutterTts.getVoices;
    } catch (_) {
      _hasConfiguredKoreanVoice = true;
      return;
    }

    if (voices is! List) {
      _hasConfiguredKoreanVoice = true;
      return;
    }

    for (final voice in voices) {
      if (voice is! Map) {
        continue;
      }

      final rawLocale = voice['locale']?.toString();
      final name = voice['name']?.toString();
      if (rawLocale == null || name == null) {
        continue;
      }

      final locale = rawLocale.replaceAll('_', '-').toLowerCase();
      if (locale != koreanFamilyPromiseTtsLocale.toLowerCase()) {
        continue;
      }

      try {
        await _flutterTts.setVoice({'name': name, 'locale': rawLocale});
      } catch (_) {
        _hasConfiguredKoreanVoice = true;
        return;
      }

      _hasConfiguredKoreanVoice = true;
      return;
    }

    _hasConfiguredKoreanVoice = true;
  }

  Future<void> speak(String text) async {
    await _configureKoreanVoice();
    await _flutterTts.speak(text);
  }

  Future<void> stop() {
    return _flutterTts.stop();
  }

  void dispose() {
    _flutterTts.stop();
  }
}
