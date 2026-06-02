import 'dart:developer';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../utility/constants.dart';
import 'http/auth_session_manager.dart';
import 'http/auth_storage.dart';
import 'http/http_client_utils.dart';
import 'http/http_error_handler.dart';

export 'http/api_exception.dart';

class HttpService extends GetConnect {
  static const Uuid _uuid = Uuid();
  static const String _clientType = 'mobile_client';
  static String? _lastKnownRouteName;

  @override
  void onInit() {
    baseUrl = MAIN_URL;
    httpClient.baseUrl = MAIN_URL;
    timeout = const Duration(seconds: 30);
    super.onInit();
  }

  // ---------------------------------------------------------------------------
  // Static Facades — keep the same public API used by DataProvider, providers
  // ---------------------------------------------------------------------------

  static void setCurrentRouteName(String? routeName) {
    final normalized = routeName?.trim();
    if (normalized == null || normalized.isEmpty) return;
    _lastKnownRouteName = normalized;
  }

  static Future<void> setSentryUser(User? user) =>
      AuthSessionManager.setSentryUser(user);

  static Future<bool> bootstrapSession() {
    final tempClient = HttpService();
    return AuthSessionManager.bootstrapSession(
      httpGet: (url, {headers}) => tempClient.get(url, headers: headers),
      refreshWithLock: ({required bool navigateOnFail}) =>
          AuthSessionManager.refreshTokenWithLock(
        navigateOnFail: navigateOnFail,
        buildTracingHeaders: HttpClientUtils.buildTracingHeaders,
        buildUri: HttpClientUtils.buildUri,
      ),
    );
  }

  static Future<void> persistAuthSession(User user) =>
      AuthSessionManager.persistAuthSession(user);

  static Future<void> clearAuthSession({bool clearAddress = false}) =>
      AuthSessionManager.clearAuthSession(clearAddress: clearAddress);

  static Future<void> handleSessionExpired({bool navigateToLogin = true}) =>
      AuthSessionManager.handleSessionExpired(navigateToLogin: navigateToLogin);

  static String? readStoredToken(String key) => AuthStorage.readString(key);

  static String parseApiMessage(
    dynamic body, {
    String fallback = 'Something went wrong. Please try again.',
  }) =>
      HttpErrorHandler.parseApiMessage(body, fallback: fallback);

  static String parseResponseMessage(
    Response response, {
    String fallback = 'Something went wrong. Please try again.',
  }) =>
      HttpErrorHandler.parseResponseMessage(response, fallback: fallback);

  static String humanizeError(
    Object error, {
    String fallback = 'Unexpected error. Please try again.',
  }) =>
      HttpErrorHandler.humanizeError(error, fallback: fallback);

  // ---------------------------------------------------------------------------
  // Internal request helpers — only used within HttpService
  // ---------------------------------------------------------------------------

  String buildUrl(String endpoint) => HttpClientUtils.buildUrl(endpoint);

  Uri buildUri(String endpoint) => HttpClientUtils.buildUri(endpoint);

  Map<String, String> buildTracingHeaders() =>
      HttpClientUtils.buildTracingHeaders();

  static String normalizeEndpoint(String endpointUrl) =>
      HttpErrorHandler.normalizeEndpoint(endpointUrl);

  static String currentRoute() =>
      HttpErrorHandler.currentRoute(_lastKnownRouteName);

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    if (!includeAuth) return {};
    final token = AuthStorage.readString(TOKEN);
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  Map<String, String> _buildRequestHeaders({
    required bool includeAuth,
    required String requestId,
  }) {
    return {
      ..._getHeaders(includeAuth: includeAuth),
      'x-client-type': _clientType,
      'x-request-id': requestId,
      ...buildTracingHeaders(),
    };
  }

  // ---------------------------------------------------------------------------
  // Endpoint classification
  // ---------------------------------------------------------------------------

  bool _isCriticalEndpoint(String endpointUrl) {
    final ep = normalizeEndpoint(endpointUrl).toLowerCase();
    return ep.contains('payment') ||
        ep.contains('stripe') ||
        ep.contains('order') ||
        ep.contains('cart') ||
        ep.contains('review') ||
        ep == 'users/logout' ||
        ep == 'users/refresh-token';
  }

  bool _isCatalogEndpoint(String endpointUrl) {
    final ep = normalizeEndpoint(endpointUrl).toLowerCase();
    return ep == 'categories' ||
        ep == 'subcategories' ||
        ep == 'brands' ||
        ep == 'products' ||
        ep == 'posters';
  }

  static bool _isTransientNetworkStatus(int statusCode) =>
      statusCode == 408 ||
      statusCode == 429 ||
      statusCode == 500 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;

  bool _isExpectedAuthClientError(String endpointUrl, int statusCode) {
    final ep = normalizeEndpoint(endpointUrl).toLowerCase();
    if (ep == 'users/logout' && statusCode == 401) return true;
    return (ep == 'users/login' || ep == 'users/register') &&
        (statusCode == 400 || statusCode == 401 || statusCode == 403);
  }

  bool _shouldCaptureApiError(String endpointUrl, int statusCode) {
    if (_isCatalogEndpoint(endpointUrl) &&
        _isTransientNetworkStatus(statusCode)) {
      return false;
    }
    if (statusCode >= 500) return true;
    if (_isExpectedAuthClientError(endpointUrl, statusCode)) return false;
    if (statusCode == 401 && !_isAuthFreeEndpoint(endpointUrl)) return true;
    return _isCriticalEndpoint(endpointUrl) && statusCode >= 400;
  }

  bool _isRefreshEndpoint(String endpointUrl) =>
      normalizeEndpoint(endpointUrl) == 'users/refresh-token';

  bool _isAuthFreeEndpoint(String endpointUrl) {
    final ep = normalizeEndpoint(endpointUrl);
    return ep == 'users/login' ||
        ep == 'users/register' ||
        ep == 'users/refresh-token';
  }

  // ---------------------------------------------------------------------------
  // Core request dispatcher (auth-retry + Sentry capture)
  // ---------------------------------------------------------------------------

  Future<Response<T>> _sendWithAuthRetry<T>({
    required String endpointUrl,
    required String method,
    dynamic requestBody,
    required Future<Response<T>> Function(Map<String, String> headers) send,
    bool includeAuth = true,
    bool allowRefreshOn401 = true,
  }) async {
    final requestId = _uuid.v4();
    Map<String, String> currentHeaders = _buildRequestHeaders(
      includeAuth: includeAuth,
      requestId: requestId,
    );
    final hadAccessToken = currentHeaders.containsKey('Authorization');

    try {
      Response<T> response = await send(currentHeaders);

      final shouldTryRefresh = allowRefreshOn401 &&
          response.statusCode == 401 &&
          includeAuth &&
          hadAccessToken &&
          !_isRefreshEndpoint(endpointUrl) &&
          !_isAuthFreeEndpoint(endpointUrl);

      if (shouldTryRefresh) {
        final refreshed = await AuthSessionManager.refreshTokenWithLock(
          navigateOnFail: true,
          buildTracingHeaders: HttpClientUtils.buildTracingHeaders,
          buildUri: HttpClientUtils.buildUri,
        );
        if (refreshed) {
          currentHeaders = _buildRequestHeaders(
            includeAuth: includeAuth,
            requestId: requestId,
          );
          response = await send(currentHeaders);
        }
      }

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400 &&
          _shouldCaptureApiError(endpointUrl, statusCode)) {
        await HttpErrorHandler.captureHttpException(
          method: method,
          endpointUrl: endpointUrl,
          statusCode: response.statusCode,
          requestId: requestId,
          route: currentRoute(),
          requestBody: requestBody,
          headers: currentHeaders,
          responseBody: response.body,
          stackTrace: StackTrace.current,
        );
      }

      return response;
    } catch (e, stackTrace) {
      await HttpErrorHandler.captureHttpException(
        method: method,
        endpointUrl: endpointUrl,
        statusCode: null,
        requestId: requestId,
        route: currentRoute(),
        requestBody: requestBody,
        headers: currentHeaders,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Public HTTP methods (unchanged API)
  // ---------------------------------------------------------------------------

  Future<Response> getItems({
    required String endpointUrl,
    bool includeAuth = true,
    bool allowRefreshOn401 = true,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        endpointUrl: endpointUrl,
        method: 'GET',
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => get(buildUrl(endpointUrl), headers: headers),
      );
      log('[GET] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': humanizeError(e)}, statusCode: 500);
    }
  }

  Future<Response> addItem({
    required String endpointUrl,
    required dynamic itemData,
    bool includeAuth = true,
    bool allowRefreshOn401 = true,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        endpointUrl: endpointUrl,
        method: 'POST',
        requestBody: itemData,
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) =>
            post(buildUrl(endpointUrl), itemData, headers: headers),
      );
      log('[POST] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': humanizeError(e)}, statusCode: 500);
    }
  }

  Future<Response> updateItem({
    required String endpointUrl,
    required String itemId,
    required dynamic itemData,
    bool includeAuth = true,
    bool allowRefreshOn401 = true,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        endpointUrl: '$endpointUrl/$itemId',
        method: 'PUT',
        requestBody: itemData,
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => put(
          buildUrl('$endpointUrl/$itemId'),
          itemData,
          headers: headers,
        ),
      );
      return response;
    } catch (e) {
      return Response(body: {'message': humanizeError(e)}, statusCode: 500);
    }
  }

  Future<Response> putItem({
    required String endpointUrl,
    required dynamic itemData,
    bool includeAuth = true,
    bool allowRefreshOn401 = true,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        endpointUrl: endpointUrl,
        method: 'PUT',
        requestBody: itemData,
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => put(
          buildUrl(endpointUrl),
          itemData,
          headers: headers,
        ),
      );
      log('[PUT] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': humanizeError(e)}, statusCode: 500);
    }
  }

  Future<Response> deleteItem({
    required String endpointUrl,
    required String itemId,
    bool includeAuth = true,
    bool allowRefreshOn401 = true,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        endpointUrl: '$endpointUrl/$itemId',
        method: 'DELETE',
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => delete(
          buildUrl('$endpointUrl/$itemId'),
          headers: headers,
        ),
      );
      return response;
    } catch (e) {
      return Response(body: {'message': humanizeError(e)}, statusCode: 500);
    }
  }

  Future<Response> deleteWithBody({
    required String endpointUrl,
    required dynamic body,
    bool includeAuth = true,
    bool allowRefreshOn401 = true,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        endpointUrl: endpointUrl,
        method: 'DELETE',
        requestBody: body,
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => request(
          buildUrl(endpointUrl),
          'DELETE',
          body: body,
          headers: headers,
        ),
      );
      log('[DELETE] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': humanizeError(e)}, statusCode: 500);
    }
  }
}
