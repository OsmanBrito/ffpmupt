import 'package:ffpmupt/services/holy_ground_image_upload_service.dart';

class CommunityNoticeImageUploadService extends HolyGroundImageUploadService {
  static const maxImageBytes = HolyGroundImageUploadService.maxImageBytes;
  static const allowedExtensions =
      HolyGroundImageUploadService.allowedExtensions;

  CommunityNoticeImageUploadService({
    super.send,
    super.cloudName = const String.fromEnvironment(
      'CLOUDINARY_CLOUD_NAME',
      defaultValue: 'ddqs0j1t',
    ),
    super.uploadPreset = const String.fromEnvironment(
      'CLOUDINARY_NOTICE_UPLOAD_PRESET',
      defaultValue: 'holy_grounds',
    ),
  });
}
