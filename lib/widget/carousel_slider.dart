import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../utility/app_color.dart';
import '../models/product.dart';
import '../utility/utility_extension.dart';
import 'custom_network_image.dart';

class CarouselSlider extends StatefulWidget {
  const CarouselSlider({
    super.key,
    required this.items,
  });

  final List<Images> items;

  @override
  State<CarouselSlider> createState() => _CarouselSliderState();
}

class _CarouselSliderState extends State<CarouselSlider> {
  int newIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned.fill(
          child: PageView.builder(
            itemCount: widget.items.length,
            onPageChanged: (int currentIndex) {
              setState(() => newIndex = currentIndex);
            },
            itemBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomNetworkImage(
                  imageUrl: widget.items.safeElementAt(index)?.url ?? '',
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 20,
          child: AnimatedSmoothIndicator(
            effect: const WormEffect(
              dotColor: Colors.black12,
              activeDotColor: AppColor.darkOrange,
              dotHeight: 7,
              dotWidth: 7,
              spacing: 5,
            ),
            count: widget.items.length,
            activeIndex: newIndex,
          ),
        )
      ],
    );
  }
}
