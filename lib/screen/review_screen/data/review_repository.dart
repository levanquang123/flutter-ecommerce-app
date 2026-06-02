import '../../../models/review.dart';
import '../../../services/http_services.dart';

class ReviewRepository {
  final HttpService _service;

  ReviewRepository(this._service);

  Future<ReviewQueryResult> getProductReviews(
    String productId, {
    int? rating,
    String sort = 'newest',
  }) async {
    final query = <String>[];
    if (rating != null && rating >= 1 && rating <= 5) {
      query.add('rating=$rating');
    }
    final normalizedSort = sort.toLowerCase() == 'oldest' ? 'oldest' : 'newest';
    query.add('sort=$normalizedSort');
    final endpoint = 'reviews/product/$productId?${query.join('&')}';

    final response = await _service.getItems(endpointUrl: endpoint);
    if (!response.isOk) {
      throw Exception(
        HttpService.parseApiMessage(
          response.body,
          fallback: 'Cannot load reviews',
        ),
      );
    }
    if (response.body is Map<String, dynamic>) {
      return ReviewQueryResult.fromJson(response.body as Map<String, dynamic>);
    }
    final reviews = _extractList(response.body)
        .whereType<Map<String, dynamic>>()
        .map(Review.fromJson)
        .toList();
    return ReviewQueryResult(reviews: reviews);
  }

  Future<Review> createProductReview({
    required String productId,
    required String orderID,
    required String orderItemID,
    required int rating,
    required String comment,
  }) async {
    final response = await _service.addItem(
      endpointUrl: 'reviews/product/$productId',
      itemData: {
        'orderID': orderID,
        'orderItemID': orderItemID,
        'rating': rating,
        'comment': comment,
      },
    );
    return _readReview(response, fallback: 'Cannot create review');
  }

  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    final response = await _service.putItem(
      endpointUrl: 'reviews/$reviewId',
      itemData: {'rating': rating, 'comment': comment},
    );
    return _readReview(response, fallback: 'Cannot update review');
  }

  Future<void> deleteReview(String reviewId) async {
    final response =
        await _service.deleteItem(endpointUrl: 'reviews', itemId: reviewId);
    if (!response.isOk) {
      throw Exception(
        HttpService.parseApiMessage(
          response.body,
          fallback: 'Cannot delete review',
        ),
      );
    }
  }

  Review _readReview(dynamic response, {required String fallback}) {
    if (!response.isOk) {
      throw Exception(
        HttpService.parseApiMessage(response.body, fallback: fallback),
      );
    }
    final raw = _extractDataObject(response.body);
    if (raw == null) {
      throw Exception('Review payload is invalid');
    }
    return Review.fromJson(raw);
  }

  static List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic> && data['reviews'] is List) {
        return data['reviews'] as List;
      }
      if (body['reviews'] is List) return body['reviews'] as List;
    }
    return const <dynamic>[];
  }

  static Map<String, dynamic>? _extractDataObject(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) {
        return body['data'] as Map<String, dynamic>;
      }
      if (body['review'] is Map<String, dynamic>) {
        return body['review'] as Map<String, dynamic>;
      }
    }
    return body is Map<String, dynamic> ? body : null;
  }
}
