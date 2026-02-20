import 'dart:developer';
import 'dart:io';

import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:cloudinary_url_gen/transformation/delivery/delivery.dart';
import 'package:cloudinary_url_gen/transformation/delivery/delivery_actions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();

  factory CloudinaryService() => _instance;

  CloudinaryService._internal();

  final Dio _dio = Dio();

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Lazily initialized Cloudinary SDK instance for URL generation.
  late final Cloudinary _cloudinary =
      Cloudinary.fromCloudName(cloudName: _cloudName);

  /// Uploads an image file to Cloudinary and returns the secure URL.
  ///
  /// Uses unsigned upload with an upload preset (safe for client-side).
  Future<String?> uploadImage(File file) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw Exception('Cloudinary keys not found in .env');
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'upload_preset': _uploadPreset,
      });

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      } else {
        throw Exception('Failed to upload image: ${response.statusMessage}');
      }
    } catch (e) {
      log('Cloudinary Upload Error: $e');
      return null;
    }
  }

  /// Checks whether a given URL is a Cloudinary URL.
  bool isCloudinaryUrl(String url) {
    return url.contains('res.cloudinary.com') && url.contains(_cloudName);
  }

  /// Extracts the public_id from a Cloudinary URL.
  ///
  /// Example URL:
  /// https://res.cloudinary.com/<cloud>/image/upload/v1234567890/folder/image.jpg
  /// Returns: folder/image (without extension)
  String? extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      // Find 'upload' segment index – public_id follows after the version
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 1 >= segments.length) return null;

      // Skip version segment if present (starts with 'v' followed by digits)
      int startIndex = uploadIndex + 1;
      if (startIndex < segments.length &&
          RegExp(r'^v\d+$').hasMatch(segments[startIndex])) {
        startIndex++;
      }

      if (startIndex >= segments.length) return null;

      // Join remaining segments and strip the file extension
      final publicIdWithExt = segments.sublist(startIndex).join('/');
      final lastDot = publicIdWithExt.lastIndexOf('.');
      if (lastDot != -1) {
        return publicIdWithExt.substring(0, lastDot);
      }
      return publicIdWithExt;
    } catch (e) {
      log('Error extracting public_id: $e');
      return null;
    }
  }

  /// Generates an optimized Cloudinary URL with f_auto & q_auto for a given
  /// public_id.
  String getOptimizedUrl(String publicId) {
    final image = _cloudinary.image(publicId)
      ..transformation(Transformation()
        ..delivery(Delivery.format(Format.auto))
        ..delivery(Delivery.quality(Quality.auto())));
    return image.toString();
  }

  /// If the URL is a Cloudinary URL, returns an optimized version.
  /// Otherwise, returns the original URL.
  String optimizeImageUrl(String url) {
    if (!isCloudinaryUrl(url)) return url;

    final publicId = extractPublicId(url);
    if (publicId == null) return url;

    return getOptimizedUrl(publicId);
  }
}
