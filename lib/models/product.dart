import 'product_review_summary.dart';

class Product {
  final String? sId;
  final String? name;
  final String? description;
  final int? quantity;
  final double? price;
  final double? offerPrice;
  final ProRef? proCategoryId;
  final ProRef? proSubCategoryId;
  final ProRef? proBrandId;
  final ProTypeRef? proVariantTypeId;
  final List<String>? proVariantId;
  final List<Images>? images;
  final List<ProductVariant>? variants;
  final String? createdAt;
  final String? updatedAt;
  final int? iV;
  final ProductReviewSummary reviewSummary;

  const Product({
    this.sId,
    this.name,
    this.description,
    this.quantity,
    this.price,
    this.offerPrice,
    this.proCategoryId,
    this.proSubCategoryId,
    this.proBrandId,
    this.proVariantTypeId,
    this.proVariantId,
    this.images,
    this.variants,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.reviewSummary = const ProductReviewSummary(),
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      sId: json['_id']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      quantity: json['quantity'] is int ? json['quantity'] : null,
      price: (json['price'] as num?)?.toDouble(),
      offerPrice: (json['offerPrice'] as num?)?.toDouble(),
      proCategoryId: json['proCategoryId'] != null
          ? ProRef.fromJson(json['proCategoryId'])
          : null,
      proSubCategoryId: json['proSubCategoryId'] != null
          ? ProRef.fromJson(json['proSubCategoryId'])
          : null,
      proBrandId: json['proBrandId'] != null
          ? ProRef.fromJson(json['proBrandId'])
          : null,
      proVariantTypeId: json['proVariantTypeId'] != null
          ? ProTypeRef.fromJson(json['proVariantTypeId'])
          : null,
      proVariantId: json['proVariantId'] != null && json['proVariantId'] is List
          ? (json['proVariantId'] as List).map((e) => e.toString()).toList()
          : [],
      images: json['images'] != null && json['images'] is List
          ? (json['images'] as List)
              .map((e) => Images.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      variants: json['variants'] is List
          ? (json['variants'] as List)
              .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      iV: json['__v'] is int ? json['__v'] : null,
      reviewSummary: ProductReviewSummary.fromJson(
        json['reviewSummary'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'price': price,
      'offerPrice': offerPrice,
      'proCategoryId': proCategoryId?.toJson(),
      'proSubCategoryId': proSubCategoryId?.toJson(),
      'proBrandId': proBrandId?.toJson(),
      'proVariantTypeId': proVariantTypeId?.toJson(),
      'proVariantId': proVariantId,
      'images': images?.map((v) => v.toJson()).toList(),
      'variants': variants?.map((v) => v.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
      'reviewSummary': reviewSummary.toJson(),
    };
  }
}

class ProductVariant {
  final String? sId;
  final String? sku;
  final List<ProductVariantAttribute> attributes;
  final double? price;
  final double? offerPrice;
  final int? quantity;
  final List<Images> images;
  final bool isActive;

  const ProductVariant({
    this.sId,
    this.sku,
    this.attributes = const [],
    this.price,
    this.offerPrice,
    this.quantity,
    this.images = const [],
    this.isActive = true,
  });

  double get effectivePrice => offerPrice ?? price ?? 0;

  String get label {
    final byAttributes = attributes
        .map((attribute) {
          if ((attribute.variantTypeName ?? '').isEmpty &&
              (attribute.variantName ?? '').isEmpty) {
            return '';
          }
          if ((attribute.variantTypeName ?? '').isEmpty) {
            return attribute.variantName ?? '';
          }
          if ((attribute.variantName ?? '').isEmpty) {
            return attribute.variantTypeName ?? '';
          }
          return '${attribute.variantTypeName}: ${attribute.variantName}';
        })
        .where((e) => e.isNotEmpty)
        .join(', ');

    if (byAttributes.isNotEmpty) return byAttributes;
    return sku ?? '';
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final parsedImages = json['images'] is List
        ? (json['images'] as List)
            .map((e) => Images.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <Images>[];
    parsedImages.sort((a, b) => (a.image ?? 0).compareTo(b.image ?? 0));

    return ProductVariant(
      sId: json['_id']?.toString(),
      sku: json['sku']?.toString(),
      attributes: json['attributes'] is List
          ? (json['attributes'] as List)
              .map((e) => ProductVariantAttribute.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      price: (json['price'] as num?)?.toDouble(),
      offerPrice: (json['offerPrice'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toInt(),
      images: parsedImages,
      isActive: json['isActive'] is bool ? json['isActive'] : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'sku': sku,
      'attributes': attributes.map((e) => e.toJson()).toList(),
      'price': price,
      'offerPrice': offerPrice,
      'quantity': quantity,
      'images': images.map((e) => e.toJson()).toList(),
      'isActive': isActive,
    };
  }
}

class ProductVariantAttribute {
  final String? variantTypeId;
  final String? variantTypeName;
  final String? variantId;
  final String? variantName;

  const ProductVariantAttribute({
    this.variantTypeId,
    this.variantTypeName,
    this.variantId,
    this.variantName,
  });

  factory ProductVariantAttribute.fromJson(Map<String, dynamic> json) {
    String? parseObjectId(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return raw;
      if (raw is Map<String, dynamic>) {
        return raw['_id']?.toString();
      }
      return null;
    }

    String? parseName(dynamic raw, {String fallbackField = 'name'}) {
      if (raw == null) return null;
      if (raw is String) return null;
      if (raw is Map<String, dynamic>) {
        return raw[fallbackField]?.toString();
      }
      return null;
    }

    return ProductVariantAttribute(
      variantTypeId: parseObjectId(json['variantTypeId']),
      variantTypeName: json['variantTypeName']?.toString() ??
          parseName(json['variantTypeId'], fallbackField: 'name') ??
          parseName(json['variantTypeId'], fallbackField: 'type'),
      variantId: parseObjectId(json['variantId']),
      variantName: json['variantName']?.toString() ??
          parseName(json['variantId'], fallbackField: 'name'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantTypeId': variantTypeId,
      'variantTypeName': variantTypeName,
      'variantId': variantId,
      'variantName': variantName,
    };
  }
}

class ProRef {
  final String? sId;
  final String? name;

  const ProRef({this.sId, this.name});

  factory ProRef.fromJson(dynamic json) {
    if (json is String) {
      return ProRef(sId: json);
    } else if (json is Map<String, dynamic>) {
      return ProRef(
        sId: json['_id']?.toString(),
        name: json['name']?.toString(),
      );
    }
    return const ProRef();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'name': name,
    };
  }
}

class ProTypeRef {
  final String? sId;
  final String? type;

  const ProTypeRef({this.sId, this.type});

  factory ProTypeRef.fromJson(dynamic json) {
    if (json is String) {
      return ProTypeRef(sId: json);
    } else if (json is Map<String, dynamic>) {
      return ProTypeRef(
        sId: json['_id']?.toString(),
        type: json['type']?.toString(),
      );
    }
    return const ProTypeRef();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'type': type,
    };
  }
}

class Images {
  final int? image;
  final String? url;
  final String? sId;

  const Images({this.image, this.url, this.sId});

  static String _normalizeUrl(dynamic raw) {
    if (raw == null) return '';
    return raw
        .toString()
        .trim()
        .replaceAll('\\', '/')
        .replaceAll('"', '')
        .replaceAll("'", '');
  }

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      image: json['image'] is int ? json['image'] : null,
      url: _normalizeUrl(json['url']),
      sId: json['_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'url': url,
      '_id': sId,
    };
  }
}
