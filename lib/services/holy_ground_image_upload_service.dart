import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

typedef UploadRequestSender =
    Future<http.StreamedResponse> Function(http.MultipartRequest request);

class HolyGroundImageUploadService {
  static const maxImageBytes = 5 * 1024 * 1024;
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

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
    if (bytes.length > maxImageBytes) {
      throw const HolyGroundImageUploadException(
        'A imagem deve ter no máximo 5 MB.',
      );
    }
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw const HolyGroundImageUploadException(
        'Use uma imagem JPG, PNG ou WebP.',
      );
    }
    if (!_hasSupportedImageSignature(bytes, extension)) {
      throw const HolyGroundImageUploadException(
        'O conteúdo da imagem não corresponde ao formato indicado.',
      );
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

  bool _hasSupportedImageSignature(Uint8List bytes, String extension) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) {
        return false;
      }
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) {
          return false;
        }
      }
      return true;
    }

    bool matchesAt(List<int> signature, int offset) {
      if (bytes.length < offset + signature.length) {
        return false;
      }
      for (var index = 0; index < signature.length; index++) {
        if (bytes[offset + index] != signature[index]) {
          return false;
        }
      }
      return true;
    }

    return switch (extension) {
      'jpg' || 'jpeg' => startsWith(const [0xff, 0xd8, 0xff]),
      'png' => startsWith(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]),
      'webp' =>
        bytes.length >= 12 &&
            startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
            matchesAt(const [0x57, 0x45, 0x42, 0x50], 8),
      _ => false,
    };
  }
}

class HolyGroundImageUploadException implements Exception {
  const HolyGroundImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
