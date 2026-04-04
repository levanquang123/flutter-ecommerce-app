import 'package:flutter/material.dart';

import '../utility/constants.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double scale;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    String finalImageUrl = imageUrl.trim().replaceAll('\\', '/');
    final String normalizedBase = MAIN_URL.replaceAll(RegExp(r'/$'), '');

    if (finalImageUrl.contains('localhost')) {
      finalImageUrl =
          finalImageUrl.replaceAll('http://localhost:3000', normalizedBase);
    }

    if (finalImageUrl.isNotEmpty &&
        !finalImageUrl.startsWith('http://') &&
        !finalImageUrl.startsWith('https://')) {
      if (finalImageUrl.startsWith('/')) {
        finalImageUrl = '$normalizedBase$finalImageUrl';
      } else {
        finalImageUrl = '$normalizedBase/$finalImageUrl';
      }
    }

    // Cloudinary images should always be served through https.
    if (finalImageUrl.contains('res.cloudinary.com') &&
        finalImageUrl.startsWith('http://')) {
      finalImageUrl = finalImageUrl.replaceFirst('http://', 'https://');
    }

    finalImageUrl = Uri.encodeFull(finalImageUrl);

    if (finalImageUrl.isEmpty) {
      return const Icon(Icons.image_not_supported, color: Colors.grey);
    }

    return Image.network(
      finalImageUrl,
      fit: fit,
      scale: scale,
      loadingBuilder:
          (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder:
          (BuildContext context, Object exception, StackTrace? stackTrace) {
        return const Icon(Icons.error, color: Colors.red);
      },
    );
  }
}
