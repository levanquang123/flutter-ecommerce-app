class User {
  final String? sId;
  final String? name;
  final String? password;
  final String? createdAt;
  final String? updatedAt;
  final int? iV;

  const User(
      {this.sId,
      this.name,
      this.password,
      this.createdAt,
      this.updatedAt,
      this.iV});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      sId: json['_id'],
      name: json['name'],
      password: json['password'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      iV: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'name': name,
      'password': password,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
    };
  }
}
