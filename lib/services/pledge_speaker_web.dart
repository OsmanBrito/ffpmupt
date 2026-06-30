import 'dart:js_interop';

import 'package:ffpmupt/content/family_promise.dart';

@JS('SpeechSynthesisUtterance')
@staticInterop
class _SpeechSynthesisUtterance {
  external factory _SpeechSynthesisUtterance(String text);
}

extension _SpeechSynthesisUtteranceExtension on _SpeechSynthesisUtterance {
  external set lang(String value);
  external set rate(double value);
  external set pitch(double value);
  external set onend(JSFunction value);
  external set onerror(JSFunction value);
}

@JS('window.speechSynthesis.speak')
external void _speak(_SpeechSynthesisUtterance utterance);

@JS('window.speechSynthesis.cancel')
external void _cancel();

class PledgeSpeaker {
  PledgeSpeaker();

  void Function()? onFinished;

  Future<void> configure() async {}

  Future<void> speak(String text) async {
    _cancel();

    final utterance = _SpeechSynthesisUtterance(text)
      ..lang = koreanFamilyPromiseTtsLocale
      ..rate = 0.82
      ..pitch = 1
      ..onend = (() {
        onFinished?.call();
      }).toJS
      ..onerror = (() {
        onFinished?.call();
      }).toJS;

    _speak(utterance);
  }

  Future<void> stop() async {
    _cancel();
  }

  void dispose() {
    _cancel();
  }
}
