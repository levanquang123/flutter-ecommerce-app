import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utility/app_color.dart';
import 'custom_network_image.dart';

class OrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTrackTap;
  final void Function(Items item, int star)? onQuickReviewTap;

  const OrderTile({
    super.key,
    required this.order,
    this.onTrackTap,
    this.onQuickReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = (order.orderStatus ?? 'pending').toLowerCase();
    final orderId = order.sId ?? '';
    final orderDate = _formatDate(order.orderDate ?? '');
    final total = order.orderTotal?.total ?? order.totalPrice ?? 0;
    final subtotal = order.orderTotal?.subtotal ?? total;
    final discount = order.orderTotal?.discount ?? 0;
    final items = order.items ?? const <Items>[];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${orderId.isEmpty ? '-' : orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColor.darkOrange,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              orderDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment: ${order.paymentMethod ?? '-'}',
              style: const TextStyle(fontSize: 14),
            ),
            const Divider(height: 24),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrderItemRow(
                  item: item,
                  showQuickReview: status == 'delivered',
                  onQuickReviewTap: (star) {
                    onQuickReviewTap?.call(item, star);
                  },
                ),
              );
            }),
            const Divider(height: 24),
            _InfoLine(label: 'Subtotal', value: _currency(subtotal)),
            _InfoLine(label: 'Discount', value: '-${_currency(discount)}'),
            _InfoLine(
              label: 'Purchased total',
              value: _currency(total),
              isBold: true,
            ),
            if (status == 'shipped') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onTrackTap,
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Track shipment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _currency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}

class _OrderItemRow extends StatelessWidget {
  final Items item;
  final bool showQuickReview;
  final ValueChanged<int>? onQuickReviewTap;

  const _OrderItemRow({
    required this.item,
    required this.showQuickReview,
    this.onQuickReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = item.quantity ?? 0;
    final price = item.price ?? 0;
    final itemTotal = price * quantity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 54,
            height: 54,
            child: CustomNetworkImage(imageUrl: item.image ?? ''),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? 'Product',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: $quantity x \$${price.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black54),
              ),
              Text(
                'Line total: \$${itemTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12),
              ),
              if (showQuickReview) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'Quick review:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    ...List.generate(5, (index) {
                      final star = index + 1;
                      return InkWell(
                        onTap: () => onQuickReviewTap?.call(star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Icon(
                            Icons.star_border,
                            size: 18,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _InfoLine({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      fontSize: isBold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
