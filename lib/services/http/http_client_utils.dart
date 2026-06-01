import 'package:sentry_flutter/sentry_flutter.dart';
import '../../utility/constants.dart';

/// Low-level URL building and Sentry tracing header utilities.
/// Kept dependency-free so it can be imported by both HttpService
/// and AuthSessionManager without creating circular references.
class HttpClientUtils {
  static String buildUrl(String endpoint) {
    if (endpoint.startsWith('http')) return endpoint;
    final String base = MAIN_URL.endsWith('/') ? MAIN_URL : '$MAIN_URL/';
    final String path =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$base$path';
  }

  static Uri buildUri(String endpoint) => Uri.parse(buildUrl(endpoint));

  static Map<String, String> buildTracingHeaders() {
    final headers = <String, String>{};
    final span = Sentry.getSpan();
    if (span == null) return headers;

    final sentryTrace = span.toSentryTrace();
    headers[sentryTrace.name] = sentryTrace.value;

    final baggage = span.toBaggageHeader();
    if (baggage != null) {
      headers[baggage.name] = baggage.value;
    }

    return headers;
  }
}
