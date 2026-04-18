import 'package:e_commerce_flutter/models/product.dart';
import 'address.dart';

class User {
  final String? sId;
  final String? email;
  final String? password;
  final String? googleId;
  final String? role;
  List<Product>? favorites;
  final Address? address;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final String? accessTokenExpiresIn;
  final String? createdAt;
  final String? updatedAt;
  final int? iV;

   User({
    this.sId,
    this.email,
    this.password,
    this.googleId,
    this.favorites,
    this.role,
    this.address,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.accessTokenExpiresIn,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> userData;
    if (json.containsKey('user') && json['user'] is Map) {
      userData = json['user'];
    } else {
      userData = json;
    }

    return User(
      sId: userData['_id']?.toString(),
      email: userData['email']?.toString(),
      password: userData['password']?.toString(),
      googleId: userData['googleId']?.toString(),
      role: userData['role']?.toString(),

      accessToken: (json['accessToken'] ?? json['token'] ?? userData['accessToken'] ?? userData['token'])?.toString(),
      address: userData['address'] is Map<String, dynamic>
          ? Address.fromJson(userData['address'])
          : null,

      favorites: userData['favorites'] != null && userData['favorites'] is List
          ? List<Product>.from((userData['favorites'] as List).map((x) {
        if (x is Map<String, dynamic>) {
          return Product.fromJson(x);
        } else {
          return Product(sId: x.toString());
        }
      }))
          : [],

      refreshToken: (json['refreshToken'] ?? userData['refreshToken'])?.toString(),
      tokenType: (json['tokenType'] ?? userData['tokenType'])?.toString(),
      accessTokenExpiresIn: (json['accessTokenExpiresIn'] ?? userData['accessTokenExpiresIn'])?.toString(),
      createdAt: userData['createdAt']?.toString(),
      updatedAt: userData['updatedAt']?.toString(),
      iV: userData['__v'] is int ? userData['__v'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'email': email,
      'googleId': googleId,
      'favorites': favorites?.map((e) => e.toJson()).toList() ?? [],
      'role': role,
      'address': address?.toJson(),
      'token': accessToken,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'accessTokenExpiresIn': accessTokenExpiresIn,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
    };
  }
}
