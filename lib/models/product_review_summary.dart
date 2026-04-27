class ProductReviewSummary {
  final double ratingAverage;
  final int reviewCount;

  const ProductReviewSummary({
    this.ratingAverage = 0,
    this.reviewCount = 0,
  });

  factory ProductReviewSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProductReviewSummary();
    }

    return ProductReviewSummary(
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ratingAverage': ratingAverage,
      'reviewCount': reviewCount,
    };
  }
}
