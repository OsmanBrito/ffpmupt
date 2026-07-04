class CountryModel {
  const CountryModel({
    required this.code,
    required this.name,
    required this.defaultLanguage,
    required this.timezone,
    required this.enabled,
  });

  final String code;
  final String name;
  final String defaultLanguage;
  final String timezone;
  final bool enabled;

  Map<String, Object?> toMap() {
    return {
      'code': code,
      'name': name,
      'defaultLanguage': defaultLanguage,
      'timezone': timezone,
      'enabled': enabled,
    };
  }

  static CountryModel? fromMap(Map<String, Object?> map) {
    final code = map['code'];
    final name = map['name'];
    final defaultLanguage = map['defaultLanguage'];
    final timezone = map['timezone'];
    final enabled = map['enabled'];

    if (code is! String ||
        name is! String ||
        defaultLanguage is! String ||
        timezone is! String ||
        enabled is! bool) {
      return null;
    }

    return CountryModel(
      code: code,
      name: name,
      defaultLanguage: defaultLanguage,
      timezone: timezone,
      enabled: enabled,
    );
  }

  static const portugal = CountryModel(
    code: 'pt',
    name: 'Portugal',
    defaultLanguage: 'pt',
    timezone: 'Europe/Lisbon',
    enabled: true,
  );
}
