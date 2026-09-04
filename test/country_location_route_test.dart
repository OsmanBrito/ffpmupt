import 'package:ffpmupt/settings/country_location_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves Flutter hash navigation during country initialization', () {
    expect(
      shouldPreserveAppNavigation(
        Uri.parse('https://example.com/#/invite/invite-id'),
      ),
      isTrue,
    );
    expect(
      shouldPreserveAppNavigation(
        Uri.parse('https://example.com/#/request-access'),
      ),
      isTrue,
    );
  });

  test('allows country paths to be synchronized on regular pages', () {
    expect(
      shouldPreserveAppNavigation(Uri.parse('https://example.com/')),
      isFalse,
    );
    expect(
      shouldPreserveAppNavigation(Uri.parse('https://example.com/pt')),
      isFalse,
    );
    expect(
      shouldPreserveAppNavigation(Uri.parse('https://example.com/#section')),
      isFalse,
    );
  });
}
