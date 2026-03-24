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
  final String? createdAt;
  final String? updatedAt;
  final int? iV;

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
    this.createdAt,
    this.updatedAt,
    this.iV,
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
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      iV: json['__v'] is int ? json['__v'] : null,
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
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

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      image: json['image'] is int ? json['image'] : null,
      url: json['url']?.toString(),
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
