import 'package:e_commerce_flutter/utility/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/data_provider.dart';
import '../review_screen/product_review_screen.dart';
import '../../../../widget/carousel_slider.dart';
import '../../../../widget/page_wrapper.dart';
import '../../models/product.dart';
import '../../utility/currency_formatter.dart';
import 'components/product_rating_section.dart';
import 'provider/product_detail_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen(this.product, {super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.proDetailProvider.clearSelection();
    });
  }

  String _formatPrice(double value) {
    return formatUsd(value);
  }

  String _formatRange(List<double> values) {
    if (values.isEmpty) return '0';
    final sorted = [...values]..sort();
    final min = sorted.first;
    final max = sorted.last;
    if (min == max) return _formatPrice(min);
    return '${_formatPrice(min)} - ${_formatPrice(max)}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        body: SingleChildScrollView(
          child: PageWrapper(
            child: Consumer2<DataProvider, ProductDetailProvider>(
              builder: (context, dataProvider, detailProvider, child) {
                final product = dataProvider.allProducts.firstWhere(
                  (item) => item.sId == widget.product.sId,
                  orElse: () => widget.product,
                );
                final variantGroups = detailProvider.getVariantGroups(product);
                final hasVariants = variantGroups.isNotEmpty;
                final matchedVariants =
                    detailProvider.getMatchingVariants(product);
                final activeVariants =
                    detailProvider.getActiveVariants(product);
                final priceSource = matchedVariants.isNotEmpty
                    ? matchedVariants
                    : activeVariants;
                final resolvedVariant =
                    detailProvider.getResolvedVariant(product);
                final displayImages = detailProvider.getDisplayImages(product);

                final displayPrice = hasVariants
                    ? (resolvedVariant != null
                        ? _formatPrice(resolvedVariant.effectivePrice)
                        : _formatRange(
                            priceSource
                                .map((item) => item.effectivePrice)
                                .toList(),
                          ))
                    : _formatPrice(product.offerPrice ?? product.price ?? 0);

                final originalPriceText = hasVariants
                    ? (resolvedVariant != null
                        ? _formatPrice(
                            resolvedVariant.price ??
                                resolvedVariant.effectivePrice,
                          )
                        : _formatRange(
                            priceSource
                                .map(
                                    (item) => item.price ?? item.effectivePrice)
                                .toList(),
                          ))
                    : _formatPrice(product.price ?? (product.offerPrice ?? 0));

                final hasDiscount = hasVariants
                    ? priceSource.any(
                        (item) =>
                            (item.price ?? item.effectivePrice) >
                            item.effectivePrice,
                      )
                    : ((product.price ?? 0) >
                        (product.offerPrice ?? product.price ?? 0));

                final stock = hasVariants
                    ? (resolvedVariant?.quantity ?? 0)
                    : (product.quantity ?? 0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: width,
                      height: width,
                      child: CarouselSlider(items: displayImages),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${product.name}',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 10),
                          ProductRatingSection(
                            summary: product.reviewSummary,
                            onTap: () {
                              if ((product.sId ?? '').isEmpty) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductReviewScreen(
                                    productId: product.sId ?? '',
                                    productName: product.name ?? '',
                                    initialSummary: product.reviewSummary,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.end,
                                children: [
                                  Text(
                                    displayPrice,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge,
                                  ),
                                  if (hasDiscount)
                                    Text(
                                      originalPriceText,
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasVariants && resolvedVariant == null
                                    ? 'Select all options'
                                    : stock > 0
                                        ? 'Stock: $stock'
                                        : 'Out of stock',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (hasVariants)
                            ...variantGroups.map((group) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.typeName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: group.options.map((option) {
                                        final isSelected =
                                            detailProvider.isOptionSelected(
                                          group.typeId,
                                          option.optionId,
                                        );
                                        final isAvailable =
                                            detailProvider.isOptionAvailable(
                                          product: product,
                                          typeId: group.typeId,
                                          optionId: option.optionId,
                                        );

                                        return InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: isAvailable
                                              ? () {
                                                  detailProvider.selectOption(
                                                    typeId: group.typeId,
                                                    optionId: option.optionId,
                                                  );
                                                }
                                              : null,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            curve: Curves.easeInOut,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFFEC6813)
                                                      .withValues(alpha: 0.08)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFFEC6813)
                                                    : Colors.grey.shade300,
                                                width: isSelected ? 1.5 : 1,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFFEC6813)
                                                            .withValues(
                                                                alpha: 0.15),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Text(
                                              option.optionName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isAvailable
                                                    ? (isSelected
                                                        ? const Color(
                                                            0xFFEC6813)
                                                        : Colors.black87)
                                                    : Colors.grey.shade400,
                                                decoration: isAvailable
                                                    ? null
                                                    : TextDecoration
                                                        .lineThrough,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text('${product.description}'),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  detailProvider.addToCart(product, context),
                              child: const Text(
                                'Add to cart',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
