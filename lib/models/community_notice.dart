enum NoticeCategory {
  general('general'),
  event('event'),
  specialDay('specialDay'),
  workshop('workshop'),
  weeklyHomework('weeklyHomework');

  const NoticeCategory(this.value);

  final String value;

  static NoticeCategory fromValue(Object? value) {
    return values.firstWhere(
      (category) => category.value == value,
      orElse: () => NoticeCategory.general,
    );
  }
}

class CommunityNotice {
  const CommunityNotice({
    required this.id,
    required this.countryCode,
    required this.title,
    required this.body,
    required this.category,
    required this.date,
    required this.location,
    required this.linkUrl,
    required this.languageCode,
    required this.enabled,
    required this.pinned,
    required this.sortOrder,
  });

  final String id;
  final String countryCode;
  final String title;
  final String body;
  final NoticeCategory category;

  /// Optional calendar date in ISO-8601 `yyyy-MM-dd` form.
  final String date;
  final String location;
  final String linkUrl;
  final String languageCode;
  final bool enabled;
  final bool pinned;
  final int sortOrder;

  DateTime? get parsedDate => DateTime.tryParse(date);

  Map<String, Object?> toMap() {
    return {
      'countryCode': countryCode,
      'title': title,
      'body': body,
      'category': category.value,
      'date': date,
      'location': location,
      'linkUrl': linkUrl,
      'languageCode': languageCode,
      'enabled': enabled,
      'pinned': pinned,
      'sortOrder': sortOrder,
    };
  }

  CommunityNotice copyWith({bool? enabled, bool? pinned}) {
    return CommunityNotice(
      id: id,
      countryCode: countryCode,
      title: title,
      body: body,
      category: category,
      date: date,
      location: location,
      linkUrl: linkUrl,
      languageCode: languageCode,
      enabled: enabled ?? this.enabled,
      pinned: pinned ?? this.pinned,
      sortOrder: sortOrder,
    );
  }

  static CommunityNotice? fromMap({
    required String id,
    required Map<String, Object?> map,
    String? countryCodeOverride,
  }) {
    final countryCode = countryCodeOverride ?? map['countryCode'];
    final title = map['title'];
    final body = map['body'];
    if (countryCode is! String ||
        countryCode.trim().isEmpty ||
        title is! String ||
        title.trim().isEmpty ||
        body is! String ||
        body.trim().isEmpty) {
      return null;
    }

    final date = map['date'] is String ? (map['date']! as String).trim() : '';
    if (date.isNotEmpty && DateTime.tryParse(date) == null) {
      return null;
    }

    return CommunityNotice(
      id: id,
      countryCode: countryCode.trim().toLowerCase(),
      title: title.trim(),
      body: body.trim(),
      category: NoticeCategory.fromValue(map['category']),
      date: date,
      location: _noticeString(map['location']),
      linkUrl: _noticeString(map['linkUrl']),
      languageCode: _noticeString(
        map['languageCode'],
        fallback: 'en',
      ).toLowerCase(),
      enabled: map['enabled'] is bool ? map['enabled']! as bool : false,
      pinned: map['pinned'] is bool ? map['pinned']! as bool : false,
      sortOrder: map['sortOrder'] is num
          ? (map['sortOrder']! as num).toInt()
          : 0,
    );
  }

  static int compare(CommunityNotice left, CommunityNotice right) {
    if (left.pinned != right.pinned) {
      return left.pinned ? -1 : 1;
    }
    final order = left.sortOrder.compareTo(right.sortOrder);
    if (order != 0) {
      return order;
    }
    if (left.date.isEmpty != right.date.isEmpty) {
      return left.date.isEmpty ? 1 : -1;
    }
    final date = left.date.compareTo(right.date);
    return date != 0 ? date : left.title.compareTo(right.title);
  }
}

String _noticeString(Object? value, {String fallback = ''}) {
  return value is String ? value.trim() : fallback;
}
