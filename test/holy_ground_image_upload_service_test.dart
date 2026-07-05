import 'dart:convert';
import 'dart:typed_data';

import 'package:ffpmupt/services/holy_ground_image_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('uploads an image with the configured unsigned preset', () async {
    late http.MultipartRequest capturedRequest;
    final service = HolyGroundImageUploadService(
      cloudName: 'example-cloud',
      uploadPreset: 'holy_grounds',
      send: (request) async {
        capturedRequest = request;
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'secure_url':
                    'https://res.cloudinary.com/example-cloud/image.jpg',
              }),
            ),
          ),
          200,
        );
      },
    );

    final url = await service.upload(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'holy-ground.jpg',
    );

    expect(url, startsWith('https://res.cloudinary.com/'));
    expect(capturedRequest.url.host, 'api.cloudinary.com');
    expect(capturedRequest.url.path, '/v1_1/example-cloud/image/upload');
    expect(capturedRequest.fields['upload_preset'], 'holy_grounds');
    expect(capturedRequest.files.single.filename, 'holy-ground.jpg');
  });

  test('surfaces the Cloudinary error message', () async {
    final service = HolyGroundImageUploadService(
      send: (_) async => http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'error': {'message': 'Unknown upload preset'},
            }),
          ),
        ),
        400,
      ),
    );

    expect(
      () =>
          service.upload(bytes: Uint8List.fromList([1]), fileName: 'image.jpg'),
      throwsA(
        isA<HolyGroundImageUploadException>().having(
          (error) => error.message,
          'message',
          'Unknown upload preset',
        ),
      ),
    );
  });
}
