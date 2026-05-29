import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utility/animation/animated_switcher_wrapper.dart';
import '../../utility/app_color.dart';
import '../../utility/currency_formatter.dart';
import '../../utility/extensions.dart';
import 'components/buy_now_bottom_sheet.dart';
import 'components/cart_list_section.dart';
import 'components/empty_cart.dart';
import 'provider/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().getCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final hasItems = cartProvider.myCartItems.isNotEmpty;
          final hasLoadError = cartProvider.loadErrorMessage != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (cartProvider.isLoading && !hasItems)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (hasLoadError && !hasItems)
                _CartLoadError(
                  message: cartProvider.loadErrorMessage!,
                  onRetry: cartProvider.loadCart,
                )
              else if (!hasItems)
                const EmptyCart()
              else
                CartListSection(cartProducts: cartProvider.myCartItems),
              if (hasItems) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w400),
                      ),
                      AnimatedSwitcherWrapper(
                        child: Text(
                          formatUsd(context.cartProvider.getCartSubTotal()),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEC6813),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 30, right: 30, bottom: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20)),
                      onPressed: () {
                        showCustomBottomSheet(context);
                      },
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                )
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CartLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CartLoadError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: AppColor.darkOrange),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
