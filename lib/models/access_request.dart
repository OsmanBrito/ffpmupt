enum AccessRequestRole {
  countryLeader('country_leader'),
  countryAdmin('country_admin');

  const AccessRequestRole(this.value);

  final String value;
}

class AccessRequest {
  const AccessRequest({
    required this.countryCode,
    required this.countryName,
    required this.displayName,
    required this.email,
    required this.role,
    this.message = '',
  });

  final String countryCode;
  final String countryName;
  final String displayName;
  final String email;
  final AccessRequestRole role;
  final String message;

  Map<String, Object?> toMap() {
    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'displayName': displayName,
      'email': email,
      'role': role.value,
      'message': message,
    };
  }

  static AccessRequest? fromMap(Map<String, Object?> map) {
    final countryCode = map['countryCode'];
    final countryName = map['countryName'];
    final displayName = map['displayName'];
    final email = map['email'];
    final role = map['role'];
    final message = map['message'] ?? '';

    if (countryCode is! String ||
        countryName is! String ||
        displayName is! String ||
        email is! String ||
        role is! String ||
        message is! String) {
      return null;
    }

    final parsedRole = AccessRequestRole.values.where(
      (item) => item.value == role,
    );
    if (parsedRole.isEmpty) {
      return null;
    }

    return AccessRequest(
      countryCode: countryCode,
      countryName: countryName,
      displayName: displayName,
      email: email,
      role: parsedRole.first,
      message: message,
    );
  }
}
