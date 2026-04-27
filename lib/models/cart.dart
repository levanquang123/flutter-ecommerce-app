class Cart {
  final String? sId;
  final String? userId;
  final List<CartItem> items;
  final String? createdAt;
  final String? updatedAt;

  const Cart({
    this.sId,
    this.userId,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      sId: json['_id']?.toString(),
      userId: json['userId']?.toString(),
      items: json['items'] is List
          ? (json['items'] as List)
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class CartItem {
  final String productId;
  final String variantId;
  final int quantity;
  final String variant;
  final String sku;
  final List<CartItemAttribute> attributes;
  final String image;
  final double priceAtAdd;

  const CartItem({
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.variant,
    required this.sku,
    this.attributes = const [],
    this.image = '',
    required this.priceAtAdd,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    String parseObjectId(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw;
      if (raw is Map<String, dynamic>) {
        return raw['_id']?.toString() ?? raw['id']?.toString() ?? '';
      }
      return '';
    }

    return CartItem(
      productId: parseObjectId(json['productId']),
      variantId: parseObjectId(json['variantId']),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      variant: (json['variant']?.toString() ?? '').isNotEmpty
          ? json['variant'].toString()
          : (json['attributes'] is List
              ? (json['attributes'] as List)
                  .map((e) => CartItemAttribute.fromJson(
                      Map<String, dynamic>.from(e)))
                  .map((attribute) =>
                      '${attribute.variantTypeName}: ${attribute.variantName}')
                  .where((label) => !label.endsWith(': '))
                  .join(', ')
              : ''),
      sku: json['sku']?.toString() ?? '',
      attributes: json['attributes'] is List
          ? (json['attributes'] as List)
              .map((e) =>
                  CartItemAttribute.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      image: json['image']?.toString() ?? '',
      priceAtAdd: (json['priceAtAdd'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'productId': productId,
      'variantId': variantId,
      'quantity': quantity,
      'variant': variant,
      'sku': sku,
    };
  }
}

class CartItemAttribute {
  final String variantTypeId;
  final String variantTypeName;
  final String variantId;
  final String variantName;

  const CartItemAttribute({
    required this.variantTypeId,
    required this.variantTypeName,
    required this.variantId,
    required this.variantName,
  });

  factory CartItemAttribute.fromJson(Map<String, dynamic> json) {
    String parseObjectId(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw;
      if (raw is Map<String, dynamic>) {
        return raw['_id']?.toString() ?? '';
      }
      return '';
    }

    return CartItemAttribute(
      variantTypeId: parseObjectId(json['variantTypeId']),
      variantTypeName: json['variantTypeName']?.toString() ?? '',
      variantId: parseObjectId(json['variantId']),
      variantName: json['variantName']?.toString() ?? '',
    );
  }
}
