class User {
  final String? sId;
  final String? name;
  final String? password;
  final String? role;
  final String? token;
  final String? createdAt;
  final String? updatedAt;
  final int? iV;

  const User({
    this.sId,
    this.name,
    this.password,
    this.role,
    this.token,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> userData = json['user'] ?? json;
    
    return User(
      sId: userData['_id'],
      name: userData['name'],
      password: userData['password'],
      role: userData['role'],
      token: json['token'],
      createdAt: userData['createdAt'],
      updatedAt: userData['updatedAt'],
      iV: userData['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'name': name,
      'password': password,
      'role': role,
      'token': token,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
    };
  }
}
