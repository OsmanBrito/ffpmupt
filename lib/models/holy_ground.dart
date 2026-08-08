class HolyGround {
  const HolyGround({
    required this.id,
    required this.countryCode,
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.summary,
    required this.history,
    required this.visitInstructions,
    required this.contactName,
    required this.contactEmail,
    required this.languageCode,
    required this.enabled,
    required this.sortOrder,
  });

  final String id;
  final String countryCode;
  final String name;
  final String city;
  final String address;
  final double? latitude;
  final double? longitude;
  final String imageUrl;
  final String summary;
  final String history;
  final String visitInstructions;
  final String contactName;
  final String contactEmail;
  final String languageCode;
  final bool enabled;
  final int sortOrder;

  bool get hasCoordinates => latitude != null && longitude != null;

  Uri get googleMapsUri {
    final query = hasCoordinates
        ? '$latitude,$longitude'
        : [
            name,
            address,
            city,
          ].where((value) => value.trim().isNotEmpty).join(', ');
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
  }

  Map<String, Object?> toMap() {
    return {
      'countryCode': countryCode,
      'name': name,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'summary': summary,
      'history': history,
      'visitInstructions': visitInstructions,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'languageCode': languageCode,
      'enabled': enabled,
      'sortOrder': sortOrder,
    };
  }

  static HolyGround? fromMap({
    required String id,
    required Map<String, Object?> map,
    String? countryCodeOverride,
  }) {
    final countryCode = countryCodeOverride ?? map['countryCode'];
    final name = map['name'];
    if (countryCode is! String ||
        countryCode.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty) {
      return null;
    }
    final latitude = _number(map['latitude']);
    final longitude = _number(map['longitude']);
    if ((map['latitude'] != null && latitude == null) ||
        (map['longitude'] != null && longitude == null)) {
      return null;
    }
    return HolyGround(
      id: id,
      countryCode: countryCode.trim().toLowerCase(),
      name: name.trim(),
      city: _string(map['city']),
      address: _string(map['address']),
      latitude: latitude,
      longitude: longitude,
      imageUrl: _string(map['imageUrl']),
      summary: _string(map['summary']),
      history: _string(map['history']),
      visitInstructions: _string(map['visitInstructions']),
      contactName: _string(map['contactName']),
      contactEmail: _string(map['contactEmail']),
      languageCode: _string(map['languageCode'], fallback: 'en').toLowerCase(),
      enabled: map['enabled'] is bool ? map['enabled']! as bool : false,
      sortOrder: map['sortOrder'] is num
          ? (map['sortOrder']! as num).toInt()
          : 0,
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  return value is String ? value.trim() : fallback;
}

double? _number(Object? value) {
  return switch (value) {
    int number => number.toDouble(),
    double number => number,
    _ => null,
  };
}
