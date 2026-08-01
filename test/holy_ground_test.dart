import 'package:ffpmupt/models/holy_ground.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ground = HolyGround(
    id: 'lisbon',
    countryCode: 'pt',
    name: 'Lisbon Holy Ground',
    city: 'Lisbon',
    address: 'Example address, Lisbon',
    latitude: 38.7223,
    longitude: -9.1393,
    imageUrl: 'https://example.com/image.jpg',
    summary: 'A Holy Ground in Lisbon.',
    history: 'History',
    visitInstructions: 'Visit instructions',
    contactName: 'Local contact',
    contactEmail: 'contact@example.com',
    languageCode: 'pt',
    enabled: true,
    sortOrder: 1,
  );

  test('holy ground round-trips through Firestore data', () {
    final decoded = HolyGround.fromMap(id: ground.id, map: ground.toMap());
    expect(decoded?.name, ground.name);
    expect(decoded?.latitude, ground.latitude);
    expect(decoded?.contactEmail, ground.contactEmail);
  });

  test('Google Maps URL uses coordinates without an API key', () {
    final uri = ground.googleMapsUri;
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['query'], '38.7223,-9.1393');
  });

  test('Google Maps URL falls back to address', () {
    final withoutCoordinates = HolyGround.fromMap(
      id: ground.id,
      map: {...ground.toMap(), 'latitude': null, 'longitude': null},
    )!;
    expect(
      withoutCoordinates.googleMapsUri.queryParameters['query'],
      contains('Example address'),
    );
  });

  test('legacy documents keep working when optional fields are missing', () {
    final decoded = HolyGround.fromMap(
      id: 'legacy',
      countryCodeOverride: 'pt',
      map: const {'name': 'Legacy Holy Ground', 'enabled': true},
    );

    expect(decoded, isNotNull);
    expect(decoded?.countryCode, 'pt');
    expect(decoded?.city, isEmpty);
    expect(decoded?.languageCode, 'en');
    expect(decoded?.sortOrder, 0);
  });

  test('document path takes precedence over a mismatched country field', () {
    final decoded = HolyGround.fromMap(
      id: ground.id,
      countryCodeOverride: 'pt',
      map: {...ground.toMap(), 'countryCode': 'br'},
    );

    expect(decoded?.countryCode, 'pt');
  });
}
