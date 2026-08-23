import 'package:ffpmupt/content/motto.dart';

class MottoSettings {
  const MottoSettings({required this.title, required this.body});

  final String title;
  final String body;

  factory MottoSettings.fallback({required String countryCode}) {
    if (countryCode.toLowerCase() == 'pt') {
      return MottoSettings(title: currentMotto.title, body: currentMotto.body);
    }
    return const MottoSettings(title: '', body: '');
  }

  bool get isConfigured => title.trim().isNotEmpty && body.trim().isNotEmpty;

  Map<String, Object?> toMap() => {'title': title, 'body': body};

  static MottoSettings? fromMap(Map<String, Object?> map) {
    final title = map['title'];
    final body = map['body'];
    if (title is! String || body is! String) {
      return null;
    }
    return MottoSettings(title: title, body: body);
  }
}
