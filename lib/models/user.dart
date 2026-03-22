class User {
  final String? sId;
  final String? email;
  final String? password;
  final String? googleId;
  final String? role;
  final String? accessToken;
  final String? refreshToken;
  final String? createdAt;
  final String? updatedAt;
  final int? iV;

  const User({
    this.sId,
    this.email,
    this.password,
    this.googleId,
    this.role,
    this.accessToken,
    this.refreshToken,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> userData = json['user'] ?? json;

    return User(
      sId: userData['_id'],
      email: userData['email'],
      password: userData['password'],
      googleId: userData['googleId'],
      role: userData['role'],
      accessToken: json['token'] ?? json['accessToken'] ?? userData['accessToken'],
      refreshToken: json['refreshToken'] ?? userData['refreshToken'],
      createdAt: userData['createdAt'],
      updatedAt: userData['updatedAt'],
      iV: userData['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'email': email,
      'password': password,
      'googleId': googleId,
      'role': role,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
    };
  }
}