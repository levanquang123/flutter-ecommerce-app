import 'package:e_commerce_flutter/models/product.dart';

class User {
  final String? sId;
  final String? email;
  final String? password;
  final String? googleId;
  final String? role;
  List<Product>? favorites;
  final String? accessToken;
  final String? refreshToken;
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
    this.accessToken,
    this.refreshToken,
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

      accessToken: (json['token'] ?? json['accessToken'] ?? userData['accessToken'] ?? userData['token'])?.toString(),

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
      createdAt: userData['createdAt']?.toString(),
      updatedAt: userData['updatedAt']?.toString(),
      iV: userData['__v'] is int ? userData['__v'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'email': email,
      'password': password,
      'googleId': googleId,
      'favorites': favorites,
      'role': role,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
    };
  }
}