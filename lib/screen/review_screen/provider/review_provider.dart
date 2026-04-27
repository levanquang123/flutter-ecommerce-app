import 'package:flutter/foundation.dart';

import '../../../core/data/data_provider.dart';
import '../../../models/order.dart';
import '../../../models/review.dart';

enum ReviewLoadState { idle, loading, success, empty, error }

class ReviewTarget {
  final String orderId;
  final String orderItemId;

  const ReviewTarget({
    required this.orderId,
    required this.orderItemId,
  });
}

class ReviewProvider extends ChangeNotifier {
  final DataProvider _dataProvider;

  ReviewProvider(this._dataProvider);

  ReviewLoadState _state = ReviewLoadState.idle;
  String _errorMessage = '';
  bool _isSubmitting = false;
  String _productId = '';
  List<Review> _reviews = [];
  int? _selectedRating;
  String _sort = 'newest';
  ReviewSummary _summary = const ReviewSummary();
  int _filteredCount = 0;

  ReviewLoadState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  List<Review> get reviews => _reviews;
  String get productId => _productId;
  int? get selectedRating => _selectedRating;
  String get sort => _sort;
  ReviewSummary get summary => _summary;
  int get filteredCount => _filteredCount;

  List<RatingBreakdownItem> get ratingBreakdown {
    final map = <int, int>{for (final item in _summary.ratingBreakdown) item.rating: item.count};
    return List<RatingBreakdownItem>.generate(5, (index) {
      final rating = 5 - index;
      return RatingBreakdownItem(rating: rating, count: map[rating] ?? 0);
    });
  }

  Future<void> loadReviews(String productId, {bool force = false}) async {
    if (!force &&
        _productId == productId &&
        _state == ReviewLoadState.success &&
        _sort == 'newest' &&
        _selectedRating == null) {
      return;
    }

    _productId = productId;
    _state = ReviewLoadState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _dataProvider.getProductReviews(
        productId,
        rating: _selectedRating,
        sort: _sort,
      );
      _reviews = result.reviews;
      _summary = result.meta.summary;
      _filteredCount = result.meta.filteredCount;
      _state =
          result.reviews.isEmpty ? ReviewLoadState.empty : ReviewLoadState.success;
    } catch (e) {
      _state = ReviewLoadState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> selectRating(int? rating) async {
    final normalizedRating =
        (rating != null && rating >= 1 && rating <= 5) ? rating : null;
    if (_selectedRating == normalizedRating && _productId.isNotEmpty) {
      return;
    }
    _selectedRating = normalizedRating;
    if (_productId.isNotEmpty) {
      await loadReviews(_productId, force: true);
    } else {
      notifyListeners();
    }
  }

  Future<void> setSort(String value) async {
    final normalized = value.toLowerCase() == 'oldest' ? 'oldest' : 'newest';
    if (_sort == normalized && _productId.isNotEmpty) {
      return;
    }
    _sort = normalized;
    if (_productId.isNotEmpty) {
      await loadReviews(_productId, force: true);
    } else {
      notifyListeners();
    }
  }

  Review? findMine(String userId) {
    if (userId.trim().isEmpty) return null;
    for (final review in _reviews) {
      if (review.user.id == userId) return review;
    }
    return null;
  }

  bool isMyReview(Review review, String userId) {
    return userId.trim().isNotEmpty && review.user.id == userId;
  }

  List<ReviewTarget> getEligibleTargets({
    required List<Order> orders,
    required String productId,
  }) {
    final deliveredOrders = orders.where((order) {
      return (order.orderStatus ?? '').toLowerCase() == 'delivered';
    });

    final List<ReviewTarget> targets = [];
    for (final order in deliveredOrders) {
      final orderId = order.sId ?? '';
      if (orderId.isEmpty) continue;

      for (final item in (order.items ?? const <Items>[])) {
        final matchesProduct = (item.productID ?? '') == productId;
        final itemId = item.sId ?? '';
        if (!matchesProduct || itemId.isEmpty) continue;
        targets.add(ReviewTarget(orderId: orderId, orderItemId: itemId));
      }
    }
    return targets;
  }

  ReviewTarget? getNextReviewTarget({
    required List<Order> orders,
    required String productId,
    String? preferredOrderId,
    String? preferredOrderItemId,
  }) {
    final targets = getEligibleTargets(orders: orders, productId: productId);
    if (targets.isEmpty) return null;

    if ((preferredOrderId ?? '').isNotEmpty &&
        (preferredOrderItemId ?? '').isNotEmpty) {
      final matched = targets.where((target) {
        return target.orderId == preferredOrderId &&
            target.orderItemId == preferredOrderItemId;
      });
      if (matched.isNotEmpty) return matched.first;
    }

    final reviewedOrderItemIds = _reviews.map((e) => e.orderItemID).toSet();
    for (final target in targets) {
      if (!reviewedOrderItemIds.contains(target.orderItemId)) {
        return target;
      }
    }

    return targets.first;
  }

  String? validate({
    required int rating,
    required String comment,
  }) {
    if (rating < 1 || rating > 5) {
      return 'Rating must be between 1 and 5 stars.';
    }
    if (comment.trim().length < 3) {
      return 'Review comment must be at least 3 characters.';
    }
    return null;
  }

  Future<void> createReview({
    required String productId,
    required String orderId,
    required String orderItemId,
    required int rating,
    required String comment,
  }) async {
    final error = validate(rating: rating, comment: comment);
    if (error != null) throw Exception(error);

    _isSubmitting = true;
    notifyListeners();
    try {
      await _dataProvider.createProductReview(
        productId: productId,
        orderID: orderId,
        orderItemID: orderItemId,
        rating: rating,
        comment: comment.trim(),
      );
      await loadReviews(productId, force: true);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    final error = validate(rating: rating, comment: comment);
    if (error != null) throw Exception(error);

    _isSubmitting = true;
    notifyListeners();
    try {
      await _dataProvider.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment.trim(),
      );
      await loadReviews(_productId, force: true);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteReview(String reviewId) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _dataProvider.deleteReview(reviewId);
      await loadReviews(_productId, force: true);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
