import 'dart:js_interop';

@JS('ffpmuToggleFullscreen')
external void _toggleFullscreen();

class PresentationMode {
  static bool get isSupported => true;

  static void toggle() => _toggleFullscreen();
}
