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

  String _capitalizeName(String? name) {
    if (name == null || name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];

          final imageUrl = normalizeNetworkImageUrl(category.image);

          return OpenContainerWrapper(
            nextScreen:
                ProductByCategoryScreen(selectedCategory: categories[index]),
            child: Container(
              width: 96,
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
                    width: 30,
                    height: 25,
                    child: CustomNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _capitalizeName(category.name),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: category.isSelected ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
