import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();

  factory CloudinaryService() => _instance;

  CloudinaryService._internal();

  final Dio _dio = Dio();

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Uploads an image file to Cloudinary and returns the secure URL.
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
}
