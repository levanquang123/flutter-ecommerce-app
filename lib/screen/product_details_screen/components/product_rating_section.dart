import 'package:flutter/material.dart';

import '../../../models/product_review_summary.dart';

class ProductRatingSection extends StatelessWidget {
  final ProductReviewSummary summary;
  final VoidCallback onTap;

  const ProductRatingSection({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rating = summary.ratingAverage;
    final reviewCount = summary.reviewCount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              '${rating.toStringAsFixed(1)} ($reviewCount reviews)',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
