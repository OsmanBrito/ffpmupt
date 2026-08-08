import 'package:ffpmupt/models/country.dart';

class LocalChurch {
  const LocalChurch({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.timezone,
    required this.contactName,
    required this.contactEmail,
    required this.enabled,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final String timezone;
  final String contactName;
  final String contactEmail;
  final bool enabled;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'city': city,
      'address': address,
      'timezone': timezone,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'enabled': enabled,
    };
  }

  static LocalChurch? fromMap({
    required String id,
    required Map<String, Object?> map,
  }) {
    final name = map['name'];
    final city = map['city'];
    final address = map['address'];
    final timezone = map['timezone'];
    final contactName = map['contactName'];
    final contactEmail = map['contactEmail'];
    final enabled = map['enabled'];
    if (name is! String ||
        city is! String ||
        address is! String ||
        timezone is! String ||
        contactName is! String ||
        contactEmail is! String ||
        enabled is! bool) {
      return null;
    }
    return LocalChurch(
      id: id,
      name: name,
      city: city,
      address: address,
      timezone: timezone,
      contactName: contactName,
      contactEmail: contactEmail,
      enabled: enabled,
    );
  }
}

class AdminProfile {
  const AdminProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.enabled,
    required this.countryCodes,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role;
  final bool enabled;
  final List<String> countryCodes;

  AdminProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    bool? enabled,
    List<String>? countryCodes,
  }) {
    return AdminProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      enabled: enabled ?? this.enabled,
      countryCodes: countryCodes ?? this.countryCodes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'enabled': enabled,
      'countryCodes': countryCodes,
    };
  }

  static AdminProfile? fromMap({
    required String uid,
    required Map<String, Object?> map,
  }) {
    final role = map['role'];
    final enabled = map['enabled'];
    final countryCodes = map['countryCodes'];
    if (role is! String || enabled is! bool || countryCodes is! List) {
      return null;
    }
    final codes = countryCodes.whereType<String>().toList();
    if (codes.length != countryCodes.length) {
      return null;
    }
    return AdminProfile(
      uid: uid,
      email: map['email'] is String ? map['email']! as String : '',
      displayName: map['displayName'] is String
          ? map['displayName']! as String
          : '',
      role: role,
      enabled: enabled,
      countryCodes: codes,
    );
  }
}

class AdminInvite {
  const AdminInvite({
    required this.id,
    required this.email,
    required this.displayName,
    required this.countryCodes,
    required this.createdBy,
    required this.expiresAt,
    required this.enabled,
    required this.acceptedBy,
  });

  final String id;
  final String email;
  final String displayName;
  final List<String> countryCodes;
  final String createdBy;
  final DateTime expiresAt;
  final bool enabled;
  final String acceptedBy;

  bool get isAccepted => acceptedBy.isNotEmpty;
  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isPending => enabled && !isAccepted && !isExpired;

  Map<String, Object?> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'countryCodes': countryCodes,
      'createdBy': createdBy,
      'expiresAt': expiresAt,
      'enabled': enabled,
      'acceptedBy': acceptedBy,
    };
  }

  static AdminInvite? fromMap({
    required String id,
    required Map<String, Object?> map,
  }) {
    final email = map['email'];
    final displayName = map['displayName'];
    final countryCodes = map['countryCodes'];
    final createdBy = map['createdBy'];
    final expiresAt = map['expiresAt'];
    final enabled = map['enabled'];
    final acceptedBy = map['acceptedBy'];
    if (email is! String ||
        displayName is! String ||
        countryCodes is! List ||
        createdBy is! String ||
        expiresAt is! DateTime ||
        enabled is! bool ||
        acceptedBy is! String) {
      return null;
    }
    final codes = countryCodes.whereType<String>().toList();
    if (codes.length != countryCodes.length) {
      return null;
    }
    return AdminInvite(
      id: id,
      email: email,
      displayName: displayName,
      countryCodes: codes,
      createdBy: createdBy,
      expiresAt: expiresAt,
      enabled: enabled,
      acceptedBy: acceptedBy,
    );
  }
}

class CountryOperationalSummary {
  const CountryOperationalSummary({
    required this.country,
    required this.churchCount,
    required this.adminCount,
    required this.promiseLanguageCount,
    required this.songCount,
    required this.hasPayments,
    required this.hasWeeklyVideos,
    required this.holyGroundCount,
  });

  final CountryModel country;
  final int churchCount;
  final int adminCount;
  final int promiseLanguageCount;
  final int songCount;
  final bool hasPayments;
  final bool hasWeeklyVideos;
  final int holyGroundCount;

  int get expectedPromiseLanguages {
    return {'en', 'ko'}.contains(country.defaultLanguage) ? 2 : 3;
  }

  int get completedSteps {
    return [
      country.enabled,
      adminCount > 0,
      churchCount > 0,
      promiseLanguageCount >= expectedPromiseLanguages,
      songCount > 0,
      hasPayments,
      hasWeeklyVideos,
    ].where((complete) => complete).length;
  }

  int get totalSteps => 7;

  double get progress => completedSteps / totalSteps;

  bool get isReady => completedSteps == totalSteps;
}
