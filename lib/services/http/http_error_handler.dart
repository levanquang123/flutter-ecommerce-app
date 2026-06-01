import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'api_exception.dart';

export 'api_exception.dart';

class HttpErrorHandler {
  static const Set<String> sensitiveKeys = {
    'password',
    'token',
    'refreshtoken',
    'authorization',
    'cookie',
    'card',
    'cardnumber',
    'cvv',
    'cvc',
    'exp',
    'expiry',
    'expiration',
  };

  static bool isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return sensitiveKeys.any(normalized.contains);
  }

  static dynamic scrub(dynamic value, {String? key}) {
    if (key != null && isSensitiveKey(key)) {
      return '[Filtered]';
    }

    if (value is Map) {
      final scrubbed = <String, dynamic>{};
      value.forEach((k, v) {
        final stringKey = k.toString();
        scrubbed[stringKey] = scrub(v, key: stringKey);
      });
      return scrubbed;
    }

    if (value is List) {
      return value.map((item) => scrub(item)).toList();
    }

    return value;
  }

  static String parseApiMessage(
    dynamic body, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    String? message;

    if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    } else if (body is Map<String, dynamic>) {
      if (body['message'] is String) {
        message = body['message'] as String;
      } else if (body['error'] is String) {
        message = body['error'] as String;
      } else if (body['errors'] is List &&
          (body['errors'] as List).isNotEmpty) {
        message = (body['errors'] as List).first?.toString();
      } else if (body['data'] is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>;
        if (data['message'] is String) {
          message = data['message'] as String;
        }
      }
    }

    if ((message ?? '').trim().isEmpty) {
      message = fallback;
    }

    return _normalizeMessage(message!);
  }

  static String parseResponseMessage(
    Response response, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final statusText = response.statusText?.trim();
    return parseApiMessage(
      response.body,
      fallback: statusText?.isNotEmpty == true
          ? humanizeError(statusText!, fallback: statusText)
          : fallback,
    );
  }

  static String humanizeError(
    Object error, {
    String fallback = 'Unexpected error. Please try again.',
  }) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (lower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    return fallback;
  }

  static String _normalizeMessage(String message) {
    String text = message.trim();
    if (text.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    final lower = text.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('network is unreachable')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    text = text.replaceAllMapped(RegExp(r'"([^"]+)"'), (m) => m.group(1) ?? '');

    if (text.length > 1) {
      text = '${text[0].toUpperCase()}${text.substring(1)}';
    }

    if (!RegExp(r'[.!?]$').hasMatch(text)) {
      text = '$text.';
    }

    return text;
  }

  /// Normalises any endpoint/URL to a clean relative path (no host, no query).
  static String normalizeEndpoint(String endpointUrl) {
    String endpoint = endpointUrl.trim();
    if (endpoint.startsWith('http')) {
      endpoint = endpoint.replaceFirst(RegExp(r'^https?://[^/]+/?'), '');
    }
    endpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return endpoint.split('?').first;
  }

  /// Returns the current named route for Sentry breadcrumb tagging.
  static String currentRoute(String? lastKnownRouteName) {
    final route = Get.currentRoute.trim();
    if (route.isNotEmpty && route != '/') {
      return route;
    }
    return lastKnownRouteName ?? 'unknown';
  }

  static Future<void> captureHttpException({
    required String method,
    required String endpointUrl,
    required int? statusCode,
    required String requestId,
    required String route,
    dynamic requestBody,
    Map<String, String>? headers,
    dynamic responseBody,
    Object? exception,
    StackTrace? stackTrace,
  }) async {
    final endpoint = normalizeEndpoint(endpointUrl);
    final scrubbedHeaders = scrub(headers ?? <String, String>{});
    final scrubbedRequest = scrub(requestBody);
    final scrubbedResponse = scrub(responseBody);

    final apiMessage = parseApiMessage(
      responseBody,
      fallback: 'HTTP ${method.toUpperCase()} $endpoint failed',
    );
    final capturedException = exception ??
        ApiException(
          method: method.toUpperCase(),
          endpoint: endpoint,
          statusCode: statusCode,
          message: apiMessage,
        );

    await Sentry.captureException(
      capturedException,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = SentryLevel.error;
        scope.setTag('service', 'mobile-client');
        scope.setTag('client_type', 'mobile_client');
        scope.setTag('endpoint', endpoint);
        scope.setTag('method', method.toUpperCase());
        scope.setTag('status_code', '${statusCode ?? 500}');
        scope.setTag('request_id', requestId);
        scope.setTag('route', route);
        scope.setContexts('http_request', {
          'endpoint': endpoint,
          'method': method.toUpperCase(),
          'status_code': statusCode,
          'request_id': requestId,
          'headers': scrubbedHeaders,
          'payload': scrubbedRequest,
        });
        scope.setContexts('http_response', {
          'body': scrubbedResponse,
        });
      },
    );
  }
}
