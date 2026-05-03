import '../../product_by_category_screen/product_by_category_screen.dart';
import '../../../utility/animation/open_container_wrapper.dart';
import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../../../utility/network_image_url.dart';
import '../../../widget/custom_network_image.dart';

class CategorySelector extends StatelessWidget {
  final List<Category> categories;

  const CategorySelector({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          final imageUrl = normalizeNetworkImageUrl(category.image);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            child: OpenContainerWrapper(
              nextScreen:
                  ProductByCategoryScreen(selectedCategory: categories[index]),
              child: Container(
                width: 116,
                height: 70,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: category.isSelected
                      ? const Color(0xFFf16b26)
                      : const Color(0xFFE5E6E8),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 34,
                      height: 30,
                      child: CustomNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category.name ?? '',
                      style: TextStyle(
                        color:
                            category.isSelected ? Colors.white : Colors.black,
                        fontSize: 13,
                        height: 1.05,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
