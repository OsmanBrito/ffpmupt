import 'dart:convert';
import 'dart:js_interop';

@JS('window.localStorage.getItem')
external String? _getItem(String key);

@JS('window.localStorage.setItem')
external void _setItem(String key, String value);

class LocalStore {
  LocalStore._();

  static Future<String?> getString(String key) async {
    return _getItem(key);
  }

  static Future<void> setString(String key, String value) async {
    _setItem(key, value);
  }

  static Future<List<String>?> getStringList(String key) async {
    final value = _getItem(key);
    if (value == null) {
      return null;
    }

    final decoded = jsonDecode(value);
    if (decoded is! List) {
      return null;
    }

    return decoded.whereType<String>().toList();
  }

  static Future<void> setStringList(String key, List<String> value) async {
    _setItem(key, jsonEncode(value));
  }
}
