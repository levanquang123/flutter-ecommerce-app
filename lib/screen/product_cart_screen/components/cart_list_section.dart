import 'package:e_commerce_flutter/utility/extensions.dart';
import 'package:flutter/material.dart';

import '../../../models/cart.dart';
import '../../../models/product.dart';
import '../../../utility/utility_extension.dart';

class CartListSection extends StatelessWidget {
  final List<CartItem> cartProducts;

  const CartListSection({
    super.key,
    required this.cartProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: cartProducts.length,
        itemBuilder: (context, index) {
          final cartItem = cartProducts[index];
          final product = context.dataProvider.allProducts.firstWhere(
                (p) => p.sId == cartItem.productId,
            orElse: () => const Product(),
          );

          final productImage = product.images.safeElementAt(0)?.url ?? '';
          final productName = product.name ?? 'Product';

          return Dismissible(
            key: ValueKey('${cartItem.productId}_${cartItem.variant}_$index'),
            direction: DismissDirection.endToStart, // vuốt từ phải qua trái
            background: Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
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
                  content: Text('Do you want to remove "$productName" from cart?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
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
                variant: cartItem.variant,
              );
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[200]?.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.primaries[index % Colors.primaries.length],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: productImage.isEmpty
                              ? const SizedBox(
                            width: 100,
                            height: 90,
                            child: Icon(Icons.image_not_supported),
                          )
                              : Image.network(
                            productImage,
                            width: 100,
                            height: 90,
                            loadingBuilder: (
                                BuildContext context,
                                Widget child,
                                ImageChunkEvent? loadingProgress,
                                ) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (
                                BuildContext context,
                                Object exception,
                                StackTrace? stackTrace,
                                ) {
                              return const Icon(Icons.error, color: Colors.red);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Qty: ${cartItem.quantity}',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (cartItem.variant.isNotEmpty)
                        Text(
                          'Variant: ${cartItem.variant}',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        '\$${cartItem.priceAtAdd}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 23,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          splashRadius: 10.0,
                          onPressed: () {
                            context.cartProvider.updateCart(cartItem, -1, context);
                          },
                          icon: const Icon(
                            Icons.remove,
                            color: Color(0xFFEC6813),
                          ),
                        ),
                        Text(
                          '${cartItem.quantity}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          splashRadius: 10.0,
                          onPressed: () {
                            context.cartProvider.updateCart(cartItem, 1, context);
                          },
                          icon: const Icon(
                            Icons.add,
                            color: Color(0xFFEC6813),
                          ),
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