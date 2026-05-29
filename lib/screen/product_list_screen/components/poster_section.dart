import '../../../core/data/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../../../utility/app_data.dart';
import '../../coming_soon_screen.dart';
import '../../../widget/custom_network_image.dart';

class PosterSection extends StatelessWidget {
  const PosterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.82).clamp(300.0, 380.0);

    return SizedBox(
      height: 174,
      child: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.posters.isEmpty) return const SizedBox.shrink();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            scrollDirection: Axis.horizontal,
            itemCount: dataProvider.posters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final poster = dataProvider.posters[index];
              final imageUrl = poster.imageUrl ?? '';
              final title = (poster.posterName ?? '').trim();

              return _PosterCard(
                width: cardWidth,
                title: title.isEmpty ? 'Special offer' : title,
                imageUrl: imageUrl,
                backgroundColor: AppData.randomPosterBgColors[
                    index % AppData.randomPosterBgColors.length],
              );
            },
          );
        },
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final double width;
  final String title;
  final String imageUrl;
  final Color backgroundColor;

  const _PosterCard({
    required this.width,
    required this.title,
    required this.imageUrl,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            height: 1.12,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Get.to(() => const ComingSoonScreen(
                            title: 'Offer coming soon',
                            message:
                                'This promotion is being prepared. Please check back later.',
                            icon: Icons.local_offer_outlined,
                            primaryActionText: 'Back to home',
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size(78, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Get Now',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 14, 12),
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.image_not_supported,
                      color: Colors.white70,
                      size: 42,
                    )
                  : SizedBox.expand(
                      child: CustomNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
