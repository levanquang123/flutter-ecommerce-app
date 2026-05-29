import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../core/data/data_provider.dart';
import '../../models/order.dart';
import '../../models/product_review_summary.dart';
import '../../models/review.dart';
import '../../utility/app_color.dart';
import '../../utility/extensions.dart';
import '../../utility/snack_bar_helper.dart';
import '../login_screen/login_screen.dart';
import 'provider/review_provider.dart';

class ProductReviewScreen extends StatelessWidget {
  final String productId;
  final String productName;
  final ProductReviewSummary initialSummary;
  final String? preferredOrderId;
  final String? preferredOrderItemId;
  final int? initialRating;
  final bool autoOpenComposer;

  const ProductReviewScreen({
    super.key,
    required this.productId,
    required this.productName,
    this.initialSummary = const ProductReviewSummary(),
    this.preferredOrderId,
    this.preferredOrderItemId,
    this.initialRating,
    this.autoOpenComposer = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ReviewProvider(context.read<DataProvider>())..loadReviews(productId),
      child: _ProductReviewBody(
        productId: productId,
        productName: productName,
        initialSummary: initialSummary,
        preferredOrderId: preferredOrderId,
        preferredOrderItemId: preferredOrderItemId,
        initialRating: initialRating,
        autoOpenComposer: autoOpenComposer,
      ),
    );
  }
}

class _ProductReviewBody extends StatefulWidget {
  final String productId;
  final String productName;
  final ProductReviewSummary initialSummary;
  final String? preferredOrderId;
  final String? preferredOrderItemId;
  final int? initialRating;
  final bool autoOpenComposer;

  const _ProductReviewBody({
    required this.productId,
    required this.productName,
    required this.initialSummary,
    required this.preferredOrderId,
    required this.preferredOrderItemId,
    required this.initialRating,
    required this.autoOpenComposer,
  });

  @override
  State<_ProductReviewBody> createState() => _ProductReviewBodyState();
}

class _ProductReviewBodyState extends State<_ProductReviewBody> {
  bool _didAutoOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareUserOrders());
  }

  Future<void> _prepareUserOrders() async {
    final loginUser = context.userProvider.getLoginUsr();
    if (loginUser == null) return;
    await context.dataProvider.getAllOrderByUser(loginUser);

    if (widget.autoOpenComposer && !_didAutoOpen && mounted) {
      _didAutoOpen = true;
      await _openComposer(initialRating: widget.initialRating ?? 5);
    }
  }

  Future<void> _handleCreatePressed() async {
    final user = context.userProvider.getLoginUsr();
    if (user == null) {
      final toLogin = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Login required'),
            content: const Text('Please login to submit a review.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Login'),
              ),
            ],
          );
        },
      );

      if (toLogin == true && mounted) {
        Get.to(() => const LoginScreen());
      }
      return;
    }

    await context.dataProvider.getAllOrderByUser(user);
    if (!mounted) return;
    await _openComposer(initialRating: widget.initialRating ?? 5);
  }

  Future<void> _openComposer({
    Review? editingReview,
    int initialRating = 5,
  }) async {
    final screenContext = context;
    final reviewProvider = screenContext.read<ReviewProvider>();
    final user = screenContext.userProvider.getLoginUsr();
    if (user == null) return;

    final submitted = await showDialog<bool>(
      context: screenContext,
      barrierDismissible: false,
      builder: (_) => _ReviewComposerDialog(
        reviewProvider: reviewProvider,
        orders: screenContext.dataProvider.orders,
        productId: widget.productId,
        preferredOrderId: widget.preferredOrderId,
        preferredOrderItemId: widget.preferredOrderItemId,
        editingReview: editingReview,
        initialRating: initialRating,
      ),
    );

    if (submitted == true && mounted) {
      // Refresh products after dialog is closed to avoid UI jitters and potential errors
      context.dataProvider.getAllProducts();
      SnackBarHelper.showSuccessSnackBar(
        editingReview == null ? 'Review submitted.' : 'Review updated.',
      );
    }
  }

  Future<void> _deleteReview(Review review) async {
    final screenContext = context;
    final confirm = await showDialog<bool>(
      context: screenContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete review'),
          content: const Text('Do you want to delete this review?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    if (!screenContext.mounted) return;

    final provider = screenContext.read<ReviewProvider>();
    try {
      await provider.deleteReview(review.id);
      if (!screenContext.mounted) return;
      await screenContext.dataProvider.getAllProducts();
      if (!screenContext.mounted) return;
      SnackBarHelper.showSuccessSnackBar('Review deleted.');
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _variantLabelFromLocalOrders(Review review) {
    for (final order in context.dataProvider.orders) {
      for (final Items item in (order.items ?? const <Items>[])) {
        if ((item.sId ?? '') != review.orderItemID) continue;

        final attributeText = (item.attributes ?? const <OrderItemAttribute>[])
            .map<String>((OrderItemAttribute attribute) {
              final type = (attribute.variantTypeName ?? '').trim();
              final name = (attribute.variantName ?? '').trim();
              if (type.isNotEmpty && name.isNotEmpty) return '$type: $name';
              if (name.isNotEmpty) return name;
              return type;
            })
            .where((String value) => value.isNotEmpty)
            .join(', ');
        if (attributeText.isNotEmpty) return attributeText;
        if ((item.variant ?? '').trim().isNotEmpty) {
          return item.variant!.trim();
        }
        if ((item.sku ?? '').trim().isNotEmpty) return 'SKU: ${item.sku}';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final loginUser = context.userProvider.getLoginUsr();
    final currentUserId = loginUser?.sId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, _) {
          final reviews = provider.reviews;
          final summary = provider.summary;
          final reviewCount = summary.reviewCount > 0
              ? summary.reviewCount
              : widget.initialSummary.reviewCount;
          final average = summary.reviewCount > 0
              ? summary.ratingAverage
              : widget.initialSummary.ratingAverage;

          return RefreshIndicator(
            onRefresh: () =>
                provider.loadReviews(widget.productId, force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _ModernSummaryCard(
                  productName: widget.productName,
                  average: average,
                  reviewCount: reviewCount,
                  ratingBreakdown: provider.ratingBreakdown,
                  onWriteReview: _handleCreatePressed,
                ),
                const SizedBox(height: 14),
                _ModernReviewFilterBar(
                  selectedRating: provider.selectedRating,
                  selectedSort: provider.sort,
                  ratingBreakdown: provider.ratingBreakdown,
                  onSelectRating: (rating) => provider.selectRating(rating),
                  onSortChanged: (value) => provider.setSort(value),
                ),
                const SizedBox(height: 12),
                if (provider.state == ReviewLoadState.loading)
                  const _StateContainer(
                    child: CircularProgressIndicator(),
                  ),
                if (provider.state == ReviewLoadState.error)
                  _StateContainer(
                    child: _ReviewStateMessage(
                      icon: Icons.wifi_off_rounded,
                      title: 'Could not load reviews',
                      message: provider.errorMessage,
                      actionLabel: 'Retry',
                      onAction: () =>
                          provider.loadReviews(widget.productId, force: true),
                    ),
                  ),
                if (provider.state == ReviewLoadState.empty)
                  _StateContainer(
                    child: _ReviewStateMessage(
                      icon: Icons.rate_review_outlined,
                      title: provider.selectedRating == null
                          ? 'No reviews yet'
                          : 'No ${provider.selectedRating}-star reviews',
                      message: provider.selectedRating == null
                          ? 'Be the first to share your experience with this product.'
                          : 'Try another rating filter or check back later.',
                      actionLabel: 'Write review',
                      onAction: _handleCreatePressed,
                    ),
                  ),
                if (provider.state == ReviewLoadState.success)
                  ...reviews.map<Widget>(
                    (Review review) {
                      final variantLabel =
                          review.orderItem.variantLabel.isNotEmpty
                              ? review.orderItem.variantLabel
                              : _variantLabelFromLocalOrders(review);

                      return _ReviewTile(
                        review: review,
                        variantLabel: variantLabel,
                        isMine: provider.isMyReview(review, currentUserId),
                        onEdit: () => _openComposer(editingReview: review),
                        onDelete: () => _deleteReview(review),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCreatePressed,
        backgroundColor: AppColor.darkOrange,
        foregroundColor: Colors.white,
        elevation: 8,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        extendedIconLabelSpacing: 12,
        icon: const Icon(Icons.rate_review, size: 26),
        label: const Text(
          'Write review',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ReviewFilterBar extends StatelessWidget {
  final int? selectedRating;
  final String selectedSort;
  final List<RatingBreakdownItem> ratingBreakdown;
  final ValueChanged<int?> onSelectRating;
  final ValueChanged<String> onSortChanged;

  const _ReviewFilterBar({
    required this.selectedRating,
    required this.selectedSort,
    required this.ratingBreakdown,
    required this.onSelectRating,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: selectedRating == null,
              onSelected: (_) => onSelectRating(null),
            ),
            ...ratingBreakdown.map((item) {
              return ChoiceChip(
                label: Text('★ ${item.rating} (${item.count})'),
                selected: selectedRating == item.rating,
                onSelected: (_) => onSelectRating(item.rating),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'Sort',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: selectedSort,
              onChanged: (value) {
                if (value == null) return;
                onSortChanged(value);
              },
              items: const [
                DropdownMenuItem(
                  value: 'newest',
                  child: Text('Newest'),
                ),
                DropdownMenuItem(
                  value: 'oldest',
                  child: Text('Oldest'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewComposerDialog extends StatefulWidget {
  final ReviewProvider reviewProvider;
  final List<Order> orders;
  final String productId;
  final String? preferredOrderId;
  final String? preferredOrderItemId;
  final Review? editingReview;
  final int initialRating;

  const _ReviewComposerDialog({
    required this.reviewProvider,
    required this.orders,
    required this.productId,
    required this.preferredOrderId,
    required this.preferredOrderItemId,
    required this.editingReview,
    required this.initialRating,
  });

  @override
  State<_ReviewComposerDialog> createState() => _ReviewComposerDialogState();
}

class _ReviewComposerDialogState extends State<_ReviewComposerDialog> {
  late final TextEditingController _commentController;
  late int _rating;
  bool _isSubmitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _rating = widget.editingReview?.rating ?? widget.initialRating;
    _commentController = TextEditingController(
      text: widget.editingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final validation = widget.reviewProvider.validate(
      rating: _rating,
      comment: _commentController.text,
    );
    if (validation != null) {
      setState(() {
        _localError = validation;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    try {
      final editingReview = widget.editingReview;
      if (editingReview == null) {
        final target = widget.reviewProvider.getNextReviewTarget(
          orders: widget.orders,
          productId: widget.productId,
          preferredOrderId: widget.preferredOrderId,
          preferredOrderItemId: widget.preferredOrderItemId,
        );

        if (target == null) {
          if (!mounted) return;
          setState(() {
            _isSubmitting = false;
            _localError = 'No delivered order was found for this product.';
          });
          return;
        }

        await widget.reviewProvider.createReview(
          productId: widget.productId,
          orderId: target.orderId,
          orderItemId: target.orderItemId,
          rating: _rating,
          comment: _commentController.text,
        );
      } else {
        await widget.reviewProvider.updateReview(
          reviewId: editingReview.id,
          rating: _rating,
          comment: _commentController.text,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _localError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editingReview = widget.editingReview;

    return AlertDialog(
      title: Text(editingReview == null ? 'Write review' : 'Edit review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StarPicker(
              selected: _rating,
              onChanged: _isSubmitting
                  ? (_) {}
                  : (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              enabled: !_isSubmitting,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
            ),
            if (_localError != null) ...[
              const SizedBox(height: 8),
              Text(
                _localError!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(editingReview == null ? 'Submit' : 'Save'),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _SummaryCard extends StatelessWidget {
  final String productName;
  final double average;
  final int reviewCount;
  final VoidCallback onWriteReview;

  const _SummaryCard({
    required this.productName,
    required this.average,
    required this.reviewCount,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName.isEmpty ? 'Product' : productName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 32),
              const SizedBox(width: 8),
              Text(
                average.toStringAsFixed(1),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Text(
                '($reviewCount reviews)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onWriteReview,
            icon: const Icon(Icons.edit),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(154, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            label: const Text('Write review'),
          ),
        ],
      ),
    );
  }
}

class _ModernReviewFilterBar extends StatelessWidget {
  final int? selectedRating;
  final String selectedSort;
  final List<RatingBreakdownItem> ratingBreakdown;
  final ValueChanged<int?> onSelectRating;
  final ValueChanged<String> onSortChanged;

  const _ModernReviewFilterBar({
    required this.selectedRating,
    required this.selectedSort,
    required this.ratingBreakdown,
    required this.onSelectRating,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filter reviews',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              _ModernSortMenu(
                value: selectedSort,
                onChanged: onSortChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModernRatingChip(
                label: 'All',
                count: null,
                selected: selectedRating == null,
                onSelected: () => onSelectRating(null),
              ),
              ...ratingBreakdown.map((item) {
                return _ModernRatingChip(
                  label: '${item.rating}',
                  count: item.count,
                  selected: selectedRating == item.rating,
                  onSelected: () => onSelectRating(item.rating),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernSortMenu extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ModernSortMenu({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
          items: const [
            DropdownMenuItem(value: 'newest', child: Text('Newest')),
            DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
          ],
        ),
      ),
    );
  }
}

class _ModernRatingChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onSelected;

  const _ModernRatingChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selectedColor: AppColor.darkOrange.withValues(alpha: 0.13),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColor.darkOrange : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(
              Icons.check_rounded,
              size: 17,
              color: AppColor.darkOrange,
            ),
            const SizedBox(width: 4),
          ],
          if (count != null) ...[
            Icon(
              Icons.star_rounded,
              size: 17,
              color: selected ? AppColor.darkOrange : Colors.amber.shade700,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            count == null ? label : '$label ($count)',
            style: TextStyle(
              color: selected ? AppColor.darkOrange : Colors.grey.shade800,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSummaryCard extends StatelessWidget {
  final String productName;
  final double average;
  final int reviewCount;
  final List<RatingBreakdownItem> ratingBreakdown;
  final VoidCallback onWriteReview;

  const _ModernSummaryCard({
    required this.productName,
    required this.average,
    required this.reviewCount,
    required this.ratingBreakdown,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName.isEmpty ? 'Product' : productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 104,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColor.darkOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber.shade700,
                          size: 26,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          average.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: ratingBreakdown
                      .map(
                        (item) => _ModernRatingBreakdownRow(
                          item: item,
                          total: reviewCount,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onWriteReview,
            icon: const Icon(Icons.edit),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.darkOrange,
              side: const BorderSide(color: AppColor.darkOrange),
              minimumSize: const Size.fromHeight(50),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            label: const Text('Write review'),
          ),
        ],
      ),
    );
  }
}

class _ModernRatingBreakdownRow extends StatelessWidget {
  final RatingBreakdownItem item;
  final int total;

  const _ModernRatingBreakdownRow({
    required this.item,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : item.count / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Row(
              children: [
                Text(
                  '${item.rating}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: Colors.amber.shade700,
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColor.darkOrange),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '${item.count}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  final String variantLabel;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewTile({
    required this.review,
    required this.variantLabel,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              _initials(review.user.displayName),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        review.user.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isMine)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StarIndicator(rating: review.rating),
                    if (variantLabel.trim().isNotEmpty)
                      Text(
                        '· ${variantLabel.trim()}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (review.comment.trim().isNotEmpty)
                  Text(
                    review.comment.trim(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ReviewStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColor.darkOrange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColor.darkOrange, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.darkOrange,
              side: const BorderSide(color: AppColor.darkOrange),
              minimumSize: const Size(140, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

class _StateContainer extends StatelessWidget {
  final Widget child;

  const _StateContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _StarIndicator extends StatelessWidget {
  final int rating;

  const _StarIndicator({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < rating.clamp(0, 5);
        return Icon(
          isActive ? Icons.star : Icons.star_border,
          color: Colors.amber.shade700,
          size: 18,
        );
      }),
    );
  }
}

class _StarPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _StarPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isActive = value <= selected;
        return IconButton(
          onPressed: () => onChanged(value),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            isActive ? Icons.star : Icons.star_border,
            color: Colors.amber.shade700,
            size: 30,
          ),
        );
      }),
    );
  }
}
