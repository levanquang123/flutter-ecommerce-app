class Coupon {
  final String? sId;
  final String? couponCode;
  final String? discountType;
  final double? discountAmount;
  final double? minimumPurchaseAmount;
  final String? endDate;
  final String? status;
  final String? applicableCategory;
  final String? applicableSubCategory;
  final String? applicableProduct;
  final String? createdAt;
  final String? updatedAt;
  final int? iV;

  const Coupon({
    this.sId,
    this.couponCode,
    this.discountType,
    this.discountAmount,
    this.minimumPurchaseAmount,
    this.endDate,
    this.status,
    this.applicableCategory,
    this.applicableSubCategory,
    this.applicableProduct,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      sId: json['_id'],
      couponCode: json['couponCode'],
      discountType: json['discountType'],
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      minimumPurchaseAmount: (json['minimumPurchaseAmount'] as num?)?.toDouble(),
      endDate: json['endDate'],
      status: json['status'],
      applicableCategory: json['applicableCategory'],
      applicableSubCategory: json['applicableSubCategory'],
      applicableProduct: json['applicableProduct'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      iV: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'couponCode': couponCode,
      'discountType': discountType,
      'discountAmount': discountAmount,
      'minimumPurchaseAmount': minimumPurchaseAmount,
      'endDate': endDate,
      'status': status,
      'applicableCategory': applicableCategory,
      'applicableSubCategory': applicableSubCategory,
      'applicableProduct': applicableProduct,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
    };
  }
}