import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../core/data/data_provider.dart';
import '../../models/order.dart';
import '../../models/product_review_summary.dart';
import '../../screen/review_screen/product_review_screen.dart';
import '../../utility/app_color.dart';
import '../../utility/extensions.dart';
import '../../widget/order_tile.dart';
import '../tracking_screen/tracking_screen.dart';

class MyOrderScreen extends StatefulWidget {
  const MyOrderScreen({super.key});

  @override
  State<MyOrderScreen> createState() => _MyOrderScreenState();
}

class _MyOrderScreenState extends State<MyOrderScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    final user = context.userProvider.getLoginUsr();
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    final ok = await context.dataProvider.getAllOrderByUser(user);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasError = !ok;
    });
  }

  Future<void> _onQuickReviewTap({
    required Order order,
    required Items item,
    required int star,
  }) async {
    final productId = item.productID ?? '';
    if (productId.isEmpty) return;

    final dataProvider = context.read<DataProvider>();
    final matchedProduct =
        dataProvider.allProducts.where((p) => p.sId == productId);
    final product = matchedProduct.isNotEmpty ? matchedProduct.first : null;

    await Get.to(
      () => ProductReviewScreen(
        productId: productId,
        productName: item.productName ?? '',
        initialSummary:
            product?.reviewSummary ?? const ProductReviewSummary(),
        preferredOrderId: order.sId,
        preferredOrderItemId: item.sId,
        initialRating: star,
        autoOpenComposer: true,
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColor.darkOrange,
          ),
        ),
      ),
      body: Consumer<DataProvider>(
        builder: (context, provider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load your orders.'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                      });
                      _loadOrders();
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }

          final orders = provider.orders;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You do not have any orders yet.'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _loadOrders();
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadOrders,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderTile(
                  order: order,
                  onTrackTap: () {
                    if ((order.orderStatus ?? '').toLowerCase() == 'shipped') {
                      Get.to(TrackingScreen(url: order.trackingUrl ?? ''));
                    }
                  },
                  onQuickReviewTap: (item, star) {
                    _onQuickReviewTap(order: order, item: item, star: star);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
