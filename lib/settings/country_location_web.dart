import 'dart:js_interop';

import 'package:ffpmupt/settings/country_location_route.dart';

@JS('window.history.replaceState')
external void _replaceState(JSAny? state, String title, String url);

String? countryCodeFromLocation() {
  final segments = Uri.base.pathSegments;
  if (segments.isEmpty) {
    return null;
  }
  final code = segments.first.trim().toLowerCase();
  return RegExp(r'^[a-z]{2,3}$').hasMatch(code) ? code : null;
}

bool shouldPreserveCountryLocation() {
  return shouldPreserveAppNavigation(Uri.base);
}

void setCountryLocation(String? countryCode) {
  final path = countryCode == null ? '/' : '/${countryCode.toLowerCase()}';
  _replaceState(null, '', path);
}
