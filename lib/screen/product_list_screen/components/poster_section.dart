import '../../../core/data/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utility/app_data.dart';
import '../../coming_soon_screen.dart';
import '../../../widget/custom_network_image.dart';

class PosterSection extends StatelessWidget {
  const PosterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.posters.isEmpty) {
            return const SizedBox.shrink();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            scrollDirection: Axis.horizontal,
            itemCount: dataProvider.posters.length,
            itemBuilder: (_, index) {
              final String imageUrl =
                  dataProvider.posters[index].imageUrl ?? '';

              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppData.randomPosterBgColors[
                      index % AppData.randomPosterBgColors.length],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 15, top: 10, bottom: 10, right: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${dataProvider.posters[index].posterName}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ComingSoonScreen(
                                        title: 'Offer coming soon',
                                        message:
                                            'This promotion is being prepared. Please check back later.',
                                        icon: Icons.local_offer_outlined,
                                        primaryActionText: 'Back to home',
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  minimumSize: const Size(70, 28),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Get Now",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                      ),
                      if (imageUrl.isNotEmpty)
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
