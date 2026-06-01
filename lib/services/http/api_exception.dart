/// A typed exception for HTTP API errors.
/// Using a dedicated class instead of `Exception` makes Sentry group
/// and display errors cleanly (e.g. ApiException: GET products failed (Status 401)).
class ApiException implements Exception {
  final String method;
  final String endpoint;
  final int? statusCode;
  final String message;

  ApiException({
    required this.method,
    required this.endpoint,
    this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    final statusStr = statusCode != null ? ' (Status $statusCode)' : '';
    return 'ApiException: $method $endpoint failed$statusStr: $message';
  }
}
