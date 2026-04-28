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
  void didUpdateWidget(covariant CarouselSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSignature =
        oldWidget.items.map((item) => item.url ?? '').join('|');
    final newSignature = widget.items.map((item) => item.url ?? '').join('|');
    if (oldSignature != newSignature || newIndex >= widget.items.length) {
      setState(() => newIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned.fill(
          child: PageView.builder(
            key: ValueKey(widget.items.map((item) => item.url ?? '').join('|')),
            itemCount: widget.items.length,
            onPageChanged: (int currentIndex) {
              setState(() => newIndex = currentIndex);
            },
            itemBuilder: (_, index) {
              return ColoredBox(
                color: Colors.white,
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
