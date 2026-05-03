import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/data/data_provider.dart';
import '../models/product.dart';
import '../utility/currency_formatter.dart';
import '../utility/extensions.dart';
import '../utility/utility_extension.dart';
import 'custom_network_image.dart';

class ProductGridTile extends StatelessWidget {
  final Product product;
  final int index;
  final bool isPriceOff;

  const ProductGridTile({
    super.key,
    required this.product,
    required this.index,
    required this.isPriceOff,
  });

  String _formatPrice(double value) {
    return formatUsd(value);
  }

  @override
  Widget build(BuildContext context) {
    final variants = product.variants ?? const <ProductVariant>[];
    final hasVariants = variants.isNotEmpty;
    final activeVariants = variants.where((v) => v.isActive).toList();
    final variantsForPrice =
        activeVariants.isNotEmpty ? activeVariants : variants;
    final minBasePrice = variantsForPrice.isEmpty
        ? 0.0
        : variantsForPrice
            .map((v) => v.price ?? v.effectivePrice)
            .reduce((a, b) => a < b ? a : b);
    final minOfferPrice = variantsForPrice
        .map((v) => v.offerPrice)
        .whereType<double>()
        .fold<double>(double.infinity, (a, b) => a < b ? a : b);
    final hasOffer =
        minOfferPrice != double.infinity && minOfferPrice < minBasePrice;

    double discountPercentage = context.dataProvider
        .calculateDiscountPercentage(
            product.price ?? 0, product.offerPrice ?? 0);
    return GridTile(
      header: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Visibility(
              visible: discountPercentage != 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                ),
                width: 80,
                height: 30,
                alignment: Alignment.center,
                child: Text(
                  "OFF ${discountPercentage.toInt()} %",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Consumer<DataProvider>(
              builder: (context, dataProvider, child) {
                bool isFavorite = dataProvider.user?.favorites
                        ?.any((p) => p.sId == product.sId) ??
                    false;

                return IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: isFavorite ? Colors.red : const Color(0xFFA6A3A0),
                  ),
                  onPressed: () {
                    dataProvider.toggleFavoriteApi(product.sId ?? '');
                  },
                );
              },
            ),
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(10),
          height: 70,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                child: Text(
                  product.name ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      hasVariants
                          ? _formatPrice(
                              hasOffer ? minOfferPrice : minBasePrice)
                          : _formatPrice(
                              product.offerPrice ?? product.price ?? 0),
                      style: Theme.of(context).textTheme.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 3),
                  if (hasVariants
                      ? hasOffer
                      : (product.offerPrice != null &&
                          product.offerPrice != product.price))
                    Flexible(
                      child: Text(
                        hasVariants
                            ? _formatPrice(minBasePrice)
                            : _formatPrice(product.price ?? 0),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE5E6E8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 52, 14, 78),
          child: CustomNetworkImage(
            imageUrl: product.images!.isNotEmpty
                ? product.images?.safeElementAt(0)?.url ?? ''
                : '',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
