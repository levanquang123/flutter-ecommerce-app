import 'package:e_commerce_flutter/utility/extensions.dart';
import 'package:flutter/material.dart';

import '../../../models/cart.dart';
import '../../../models/product.dart';
import '../../../utility/app_color.dart';
import '../../../utility/utility_extension.dart';

class CartListSection extends StatelessWidget {
  final List<CartItem> cartProducts;

  const CartListSection({
    super.key,
    required this.cartProducts,
  });

  String _formatPrice(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  ProductVariant? _findVariant(Product product, String variantId) {
    if (variantId.isEmpty) return null;
    final variants = product.variants ?? const <ProductVariant>[];
    for (final variant in variants) {
      if (variant.sId == variantId) return variant;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: cartProducts.length,
        itemBuilder: (context, index) {
          final cartItem = cartProducts[index];
          final product = context.dataProvider.allProducts.firstWhere(
            (p) => p.sId == cartItem.productId,
            orElse: () => const Product(),
          );

          final variant = _findVariant(product, cartItem.variantId);
          final productImage = cartItem.image.isNotEmpty
              ? cartItem.image
              : product.images.safeElementAt(0)?.url ?? '';
          final productName = product.name ?? 'Product';
          final originalPrice = variant?.price ?? product.price;
          final hasOriginalPrice =
              originalPrice != null && originalPrice > cartItem.priceAtAdd;
          final discountPercent = hasOriginalPrice
              ? ((originalPrice - cartItem.priceAtAdd) / originalPrice * 100)
                  .round()
              : 0;

          return Dismissible(
            key: ValueKey('${cartItem.productId}_${cartItem.variantId}_$index'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Remove item'),
                      content: Text(
                          'Do you want to remove "$productName" from cart?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) async {
              await context.cartProvider.removeCartItemById(
                productId: cartItem.productId,
                variantId: cartItem.variantId,
              );
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEDEDED)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 104,
                      height: 104,
                      color: const Color(0xFFF3F3F3),
                      child: productImage.isEmpty
                          ? const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColor.darkGrey,
                            )
                          : Image.network(
                              productImage,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                BuildContext context,
                                Widget child,
                                ImageChunkEvent? loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (
                                BuildContext context,
                                Object exception,
                                StackTrace? stackTrace,
                              ) {
                                return const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColor.darkGrey,
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            height: 1.25,
                          ),
                        ),
                        if (cartItem.variant.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 210),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    cartItem.variant,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF555555),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Color(0xFF777777),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${_formatPrice(cartItem.priceAtAdd)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColor.darkOrange,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 21,
                                    ),
                                  ),
                                  if (hasOriginalPrice)
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '\$${_formatPrice(originalPrice)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF8A8A8A),
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColor.lightOrange,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '-$discountPercent%',
                                            style: const TextStyle(
                                              color: AppColor.darkOrange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _QuantityStepper(cartItem: cartItem),
                          ],
                        ),
                      ],
                    ),
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

class _QuantityStepper extends StatelessWidget {
  final CartItem cartItem;

  const _QuantityStepper({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              splashRadius: 18,
              onPressed: () {
                context.cartProvider.updateCart(cartItem, -1, context);
              },
              icon: const Icon(
                Icons.remove,
                size: 18,
                color: Color(0xFF777777),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 18,
            color: const Color(0xFFE0E0E0),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${cartItem.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 18,
            color: const Color(0xFFE0E0E0),
          ),
          SizedBox(
            width: 34,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              splashRadius: 18,
              onPressed: () {
                context.cartProvider.updateCart(cartItem, 1, context);
              },
              icon: const Icon(
                Icons.add,
                size: 18,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
