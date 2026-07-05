import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

typedef UploadRequestSender =
    Future<http.StreamedResponse> Function(http.MultipartRequest request);

class HolyGroundImageUploadService {
  HolyGroundImageUploadService({
    UploadRequestSender? send,
    this.cloudName = const String.fromEnvironment(
      'CLOUDINARY_CLOUD_NAME',
      defaultValue: 'ddqs0j1t',
    ),
    this.uploadPreset = const String.fromEnvironment(
      'CLOUDINARY_UPLOAD_PRESET',
      defaultValue: 'holy_grounds',
    ),
  }) : _send = send ?? ((request) => request.send());

  final String cloudName;
  final String uploadPreset;
  final UploadRequestSender _send;

  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw const HolyGroundImageUploadException('A imagem está vazia.');
    }
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw const HolyGroundImageUploadException(
        'O serviço de imagens não está configurado.',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload'),
          )
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    final response = await _send(request).timeout(const Duration(seconds: 45));
    final body = await response.stream.bytesToString();
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['error'] is Map
          ? (decoded['error'] as Map)['message']
          : null;
      throw HolyGroundImageUploadException(
        message is String && message.isNotEmpty
            ? message
            : 'O envio da imagem falhou (${response.statusCode}).',
      );
    }

    final secureUrl = decoded is Map ? decoded['secure_url'] : null;
    final uri = secureUrl is String ? Uri.tryParse(secureUrl) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const HolyGroundImageUploadException(
        'O serviço não devolveu uma URL válida para a imagem.',
      );
    }
    return secureUrl as String;
  }
}

class HolyGroundImageUploadException implements Exception {
  const HolyGroundImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
