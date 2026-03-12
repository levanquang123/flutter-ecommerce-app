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
    // Xử lý URL localhost
    String finalImageUrl = imageUrl;
    if (finalImageUrl.contains('localhost')) {
      finalImageUrl = finalImageUrl.replaceAll('http://localhost:3000', MAIN_URL.replaceAll(RegExp(r'/$'), ''));
    }

    return Image.network(
      finalImageUrl,
      fit: fit,
      scale: scale,
      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,  // Progress indicator.
          ),
        );
      },
      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
        return const Icon(Icons.error, color: Colors.red);
      },
    );
  }
}
