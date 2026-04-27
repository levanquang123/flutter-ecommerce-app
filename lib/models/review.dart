class Review {
  final String id;
  final String productId;
  final String orderID;
  final String orderItemID;
  final int rating;
  final String comment;
  final ReviewUser user;
  final ReviewOrderItem orderItem;
  final String createdAt;
  final String updatedAt;

  const Review({
    this.id = '',
    this.productId = '',
    this.orderID = '',
    this.orderItemID = '',
    this.rating = 0,
    this.comment = '',
    this.user = const ReviewUser(),
    this.orderItem = const ReviewOrderItem(),
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String parseId(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw;
      if (raw is Map<String, dynamic>) {
        return raw['_id']?.toString() ?? '';
      }
      return '';
    }

    return Review(
      id: json['_id']?.toString() ?? '',
      productId: parseId(json['productID'] ?? json['productId']),
      orderID: parseId(json['orderID'] ?? json['orderId']),
      orderItemID: parseId(json['orderItemID'] ?? json['orderItemId']),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      user: ReviewUser.fromJson(
          _parseMap(json['userID'] ?? json['user'] ?? json['createdBy'])),
      orderItem: ReviewOrderItem.fromJson(
        _parseMap(json['orderItemID'] ??
            json['orderItemId'] ??
            json['orderItem'] ??
            json['item']),
      ),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  static Map<String, dynamic>? _parseMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productID': productId,
      'orderID': orderID,
      'orderItemID': orderItemID,
      'rating': rating,
      'comment': comment,
      'userID': user.toJson(),
      'orderItem': orderItem.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class ReviewQueryResult {
  final List<Review> reviews;
  final ReviewMeta meta;

  const ReviewQueryResult({
    this.reviews = const <Review>[],
    this.meta = const ReviewMeta(),
  });

  factory ReviewQueryResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewQueryResult();

    final rawData = json['data'];
    final list = rawData is List
        ? rawData
        : (rawData is Map<String, dynamic> && rawData['reviews'] is List)
            ? rawData['reviews'] as List
            : const <dynamic>[];

    final reviews = list
        .whereType<Map<String, dynamic>>()
        .map(Review.fromJson)
        .toList();

    return ReviewQueryResult(
      reviews: reviews,
      meta: ReviewMeta.fromJson(
        json['meta'] is Map<String, dynamic> ? json['meta'] : null,
      ),
    );
  }
}

class ReviewMeta {
  final ReviewFilters filters;
  final int filteredCount;
  final ReviewSummary summary;

  const ReviewMeta({
    this.filters = const ReviewFilters(),
    this.filteredCount = 0,
    this.summary = const ReviewSummary(),
  });

  factory ReviewMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewMeta();
    return ReviewMeta(
      filters: ReviewFilters.fromJson(
        json['filters'] is Map<String, dynamic>
            ? json['filters'] as Map<String, dynamic>
            : null,
      ),
      filteredCount: (json['filteredCount'] as num?)?.toInt() ?? 0,
      summary: ReviewSummary.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : null,
      ),
    );
  }
}

class ReviewFilters {
  final int? rating;
  final String sort;

  const ReviewFilters({
    this.rating,
    this.sort = 'newest',
  });

  factory ReviewFilters.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewFilters();
    final rawRating = json['rating'];
    final parsedRating = (rawRating is num) ? rawRating.toInt() : null;
    return ReviewFilters(
      rating:
          (parsedRating != null && parsedRating >= 1 && parsedRating <= 5)
              ? parsedRating
              : null,
      sort: (json['sort']?.toString().trim().isNotEmpty ?? false)
          ? json['sort'].toString()
          : 'newest',
    );
  }
}

class ReviewSummary {
  final int reviewCount;
  final double ratingAverage;
  final List<RatingBreakdownItem> ratingBreakdown;

  const ReviewSummary({
    this.reviewCount = 0,
    this.ratingAverage = 0,
    this.ratingBreakdown = const <RatingBreakdownItem>[],
  });

  factory ReviewSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewSummary();
    final rawBreakdown = json['ratingBreakdown'];
    return ReviewSummary(
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
      ratingBreakdown: rawBreakdown is List
          ? rawBreakdown
              .whereType<Map<String, dynamic>>()
              .map(RatingBreakdownItem.fromJson)
              .toList()
          : const <RatingBreakdownItem>[],
    );
  }
}

class RatingBreakdownItem {
  final int rating;
  final int count;

  const RatingBreakdownItem({
    this.rating = 0,
    this.count = 0,
  });

  factory RatingBreakdownItem.fromJson(Map<String, dynamic> json) {
    return RatingBreakdownItem(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReviewOrderItem {
  final String id;
  final String variant;
  final String variantId;
  final String sku;
  final List<ReviewOrderItemAttribute> attributes;

  const ReviewOrderItem({
    this.id = '',
    this.variant = '',
    this.variantId = '',
    this.sku = '',
    this.attributes = const <ReviewOrderItemAttribute>[],
  });

  String get variantLabel {
    final attributeText = attributes
        .map<String>((ReviewOrderItemAttribute item) => item.displayText)
        .where((String item) => item.isNotEmpty)
        .join(', ');
    if (attributeText.isNotEmpty) return attributeText;
    if (variant.trim().isNotEmpty) return variant.trim();
    if (sku.trim().isNotEmpty) return 'SKU: ${sku.trim()}';
    return '';
  }

  factory ReviewOrderItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewOrderItem();
    final rawAttributes = json['attributes'];
    final attributes = <ReviewOrderItemAttribute>[];
    if (rawAttributes is List) {
      for (final rawAttribute in rawAttributes) {
        if (rawAttribute is Map<String, dynamic>) {
          attributes.add(ReviewOrderItemAttribute.fromJson(rawAttribute));
        } else if (rawAttribute is Map) {
          attributes.add(
            ReviewOrderItemAttribute.fromJson(
              rawAttribute.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ),
          );
        }
      }
    }

    return ReviewOrderItem(
      id: json['_id']?.toString() ?? '',
      variant: json['variant']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      attributes: attributes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'variant': variant,
      'variantId': variantId,
      'sku': sku,
      'attributes': attributes.map((item) => item.toJson()).toList(),
    };
  }
}

class ReviewOrderItemAttribute {
  final String variantTypeName;
  final String variantName;

  const ReviewOrderItemAttribute({
    this.variantTypeName = '',
    this.variantName = '',
  });

  String get displayText {
    final type = variantTypeName.trim();
    final name = variantName.trim();
    if (type.isNotEmpty && name.isNotEmpty) return '$type: $name';
    if (name.isNotEmpty) return name;
    return type;
  }

  factory ReviewOrderItemAttribute.fromJson(Map<String, dynamic> json) {
    return ReviewOrderItemAttribute(
      variantTypeName: json['variantTypeName']?.toString() ??
          json['typeName']?.toString() ??
          json['name']?.toString() ??
          '',
      variantName: json['variantName']?.toString() ??
          json['optionName']?.toString() ??
          json['value']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantTypeName': variantTypeName,
      'variantName': variantName,
    };
  }
}

class ReviewUser {
  final String id;
  final String email;
  final String name;

  const ReviewUser({
    this.id = '',
    this.email = '',
    this.name = '',
  });

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return 'Anonymous user';
  }

  factory ReviewUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewUser();
    return ReviewUser(
      id: json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
    };
  }
}
