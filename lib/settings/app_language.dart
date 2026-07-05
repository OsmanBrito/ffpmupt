import 'package:ffpmupt/settings/local_store.dart';
import 'package:flutter/material.dart';

const _appLanguageKey = 'app_language_v1';

enum AppLanguage {
  portuguese,
  brazilian,
  korean,
  english,
  spanish,
  german,
  italian,
  french,
}

String appLanguageLabel(AppLanguage language) {
  switch (language) {
    case AppLanguage.portuguese:
    case AppLanguage.brazilian:
      return 'Português';
    case AppLanguage.korean:
      return '한국어';
    case AppLanguage.english:
      return 'English';
    case AppLanguage.spanish:
      return 'Español';
    case AppLanguage.german:
      return 'Deutsch';
    case AppLanguage.italian:
      return 'Italiano';
    case AppLanguage.french:
      return 'Français';
  }
}

AppLanguage appLanguageFromCode(String code) {
  return switch (code.toLowerCase()) {
    'pt' => AppLanguage.portuguese,
    'pt-br' => AppLanguage.portuguese,
    'ko' => AppLanguage.korean,
    'es' => AppLanguage.spanish,
    'de' => AppLanguage.german,
    'it' => AppLanguage.italian,
    'fr' => AppLanguage.french,
    _ => AppLanguage.english,
  };
}

class AppLanguageController extends ChangeNotifier {
  AppLanguageController({bool loadStoredLanguage = true}) {
    if (loadStoredLanguage) {
      _load();
    }
  }

  AppLanguage _language = AppLanguage.portuguese;

  AppLanguage get language => _language;

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }

    _language = language;
    notifyListeners();

    await LocalStore.setString(_appLanguageKey, language.name);
  }

  void useCountryLanguage(String languageCode) {
    final language = appLanguageFromCode(languageCode);
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }

  Future<void> _load() async {
    final storedValue = await LocalStore.getString(_appLanguageKey);
    AppLanguage? storedLanguage;
    for (final language in AppLanguage.values) {
      if (language.name == storedValue) {
        storedLanguage = language;
        break;
      }
    }

    if (storedLanguage == null) {
      return;
    }

    _language = storedLanguage;
    notifyListeners();
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController watch(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope not found in context');
    return scope!.notifier!;
  }

  static AppLanguageController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<AppLanguageScope>();
    final scope = element?.widget as AppLanguageScope?;
    assert(scope != null, 'AppLanguageScope not found in context');
    return scope!.notifier!;
  }
}
