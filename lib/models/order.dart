class Order {
  final ShippingAddress? shippingAddress;
  final OrderTotal? orderTotal;
  final String? sId;
  final UserID? userID;
  final String? orderStatus;
  final List<Items>? items;
  final double? totalPrice;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentIntentId;
  final CouponCode? couponCode;
  final String? trackingUrl;
  final String? orderDate;
  final int? iV;

  const Order({
    this.shippingAddress,
    this.orderTotal,
    this.sId,
    this.userID,
    this.orderStatus,
    this.items,
    this.totalPrice,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentIntentId,
    this.couponCode,
    this.trackingUrl,
    this.orderDate,
    this.iV,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      shippingAddress: json['shippingAddress'] != null
          ? ShippingAddress.fromJson(json['shippingAddress'])
          : null,
      orderTotal: json['orderTotal'] != null
          ? OrderTotal.fromJson(json['orderTotal'])
          : null,
      sId: json['_id'],
      userID: json['userID'] != null ? UserID.fromJson(json['userID']) : null,
      orderStatus: json['orderStatus'],
      items: (json['items'] as List?)
          ?.map((e) => Items.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus']?.toString(),
      paymentIntentId: json['paymentIntentId']?.toString(),
      couponCode: json['couponCode'] != null
          ? CouponCode.fromJson(json['couponCode'])
          : null,
      trackingUrl: json['trackingUrl'],
      orderDate: json['orderDate'],
      iV: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shippingAddress': shippingAddress?.toJson(),
      'orderTotal': orderTotal?.toJson(),
      '_id': sId,
      'userID': userID?.toJson(),
      'orderStatus': orderStatus,
      'items': items?.map((v) => v.toJson()).toList(),
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentIntentId': paymentIntentId,
      'couponCode': couponCode?.toJson(),
      'trackingUrl': trackingUrl,
      'orderDate': orderDate,
      '__v': iV,
    };
  }
}

class ShippingAddress {
  final String? phone;
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  const ShippingAddress({
    this.phone,
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      phone: json['phone'],
      street: json['street'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }
}

class OrderTotal {
  final double? subtotal;
  final double? discount;
  final double? total;

  const OrderTotal({
    this.subtotal,
    this.discount,
    this.total,
  });

  factory OrderTotal.fromJson(Map<String, dynamic> json) {
    return OrderTotal(
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
    };
  }
}

class UserID {
  final String? sId;
  final String? email;

  const UserID({
    this.sId,
    this.email,
  });

  factory UserID.fromJson(Map<String, dynamic> json) {
    return UserID(
      sId: json['_id'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'email': email,
    };
  }
}

class Items {
  final String? productID;
  final String? productName;
  final int? quantity;
  final double? price;
  final String? variant;
  final String? variantId;
  final String? sku;
  final String? image;
  final List<OrderItemAttribute>? attributes;
  final String? sId;

  const Items({
    this.productID,
    this.productName,
    this.quantity,
    this.price,
    this.variant,
    this.variantId,
    this.sku,
    this.image,
    this.attributes,
    this.sId,
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      productID: json['productID'],
      productName: json['productName'],
      quantity: json['quantity'],
      price: (json['price'] as num?)?.toDouble(),
      variant: json['variant'],
      variantId: json['variantId']?.toString(),
      sku: json['sku']?.toString(),
      image: json['image']?.toString(),
      attributes: (json['attributes'] as List?)
          ?.map((e) => OrderItemAttribute.fromJson(e as Map<String, dynamic>))
          .toList(),
      sId: json['_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productID': productID,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'variant': variant,
      'variantId': variantId,
      'sku': sku,
      'image': image,
      'attributes': attributes?.map((e) => e.toJson()).toList(),
      '_id': sId,
    };
  }
}

class OrderItemAttribute {
  final String? variantTypeId;
  final String? variantTypeName;
  final String? variantId;
  final String? variantName;

  const OrderItemAttribute({
    this.variantTypeId,
    this.variantTypeName,
    this.variantId,
    this.variantName,
  });

  factory OrderItemAttribute.fromJson(Map<String, dynamic> json) {
    return OrderItemAttribute(
      variantTypeId: json['variantTypeId']?.toString(),
      variantTypeName: json['variantTypeName']?.toString(),
      variantId: json['variantId']?.toString(),
      variantName: json['variantName']?.toString(),
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

class CouponCode {
  final String? sId;
  final String? couponCode;
  final String? discountType;
  final double? discountAmount;

  const CouponCode({
    this.sId,
    this.couponCode,
    this.discountType,
    this.discountAmount,
  });

  factory CouponCode.fromJson(Map<String, dynamic> json) {
    return CouponCode(
      sId: json['_id'],
      couponCode: json['couponCode'],
      discountType: json['discountType'],
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'couponCode': couponCode,
      'discountType': discountType,
      'discountAmount': discountAmount,
    };
  }
}
