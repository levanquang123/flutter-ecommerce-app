class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json,
      T Function(Object? json) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: (json['data'] != null) ? fromJsonT(json['data']) : (json['user'] !=
          null ? fromJsonT(json) : null),
    );
  }
}
