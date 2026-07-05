class FamilyPromiseDocument {
  const FamilyPromiseDocument({
    required this.languageCode,
    required this.title,
    required this.verses,
    required this.enabled,
    required this.sortOrder,
  });

  final String languageCode;
  final String title;
  final List<String> verses;
  final bool enabled;
  final int sortOrder;

  FamilyPromiseDocument copyWith({
    String? languageCode,
    String? title,
    List<String>? verses,
    bool? enabled,
    int? sortOrder,
  }) {
    return FamilyPromiseDocument(
      languageCode: languageCode ?? this.languageCode,
      title: title ?? this.title,
      verses: verses ?? this.verses,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'languageCode': languageCode,
      'title': title,
      'verses': verses,
      'enabled': enabled,
      'sortOrder': sortOrder,
    };
  }

  static FamilyPromiseDocument? fromMap(Map<String, Object?> map) {
    final languageCode = map['languageCode'];
    final title = map['title'];
    final versesValue = map['verses'];
    final enabled = map['enabled'];
    final sortOrder = map['sortOrder'];
    if (languageCode is! String ||
        title is! String ||
        versesValue is! List ||
        enabled is! bool ||
        sortOrder is! int) {
      return null;
    }
    final verses = versesValue.whereType<String>().toList();
    if (verses.length != versesValue.length) {
      return null;
    }
    return FamilyPromiseDocument(
      languageCode: languageCode,
      title: title,
      verses: verses,
      enabled: enabled,
      sortOrder: sortOrder,
    );
  }
}
