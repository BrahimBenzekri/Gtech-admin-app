import 'dart:convert';
import 'package:admin_app/core/services/cloudinary_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageDisplay extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const ImageDisplay({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    try {
      // Check if it's a valid URL
      if (imageUrl.startsWith('http')) {
        // Use Cloudinary SDK to generate an optimized URL if applicable
        final displayUrl =
            CloudinaryService().optimizeImageUrl(imageUrl);

        return CachedNetworkImage(
          imageUrl: displayUrl,
          fit: fit,
          placeholder: (context, url) => Container(color: Colors.grey.shade200),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
        );
      }

      // Assume Base64
      return Image.memory(
        base64Decode(imageUrl),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
           return const Icon(Icons.broken_image);
        },
      );
    } catch (e) {
      return const Icon(Icons.error);
    }
  }
}
