import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore._();

  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static Future<String?> getString(String key) {
    return _preferences.getString(key);
  }

  static Future<void> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  static Future<List<String>?> getStringList(String key) {
    return _preferences.getStringList(key);
  }

  static Future<void> setStringList(String key, List<String> value) {
    return _preferences.setStringList(key, value);
  }
}
