import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/user.dart';
import '../screen/login_screen/login_screen.dart';
import '../utility/constants.dart';

class HttpService extends GetConnect {
  static final GetStorage _box = GetStorage();
  static Completer<bool>? _refreshCompleter;
  static bool _isRedirectingToLogin = false;

  @override
  void onInit() {
    baseUrl = MAIN_URL;
    httpClient.baseUrl = MAIN_URL;
    timeout = const Duration(seconds: 30);
    super.onInit();
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    if (!includeAuth) {
      return {};
    }

    final token = _readString(TOKEN);
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  String _buildUrl(String endpoint) {
    if (endpoint.startsWith('http')) return endpoint;
    String base = MAIN_URL.endsWith('/') ? MAIN_URL : '$MAIN_URL/';
    String path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$base$path';
  }

  static String _normalizeEndpoint(String endpointUrl) {
    String endpoint = endpointUrl.trim();
    if (endpoint.startsWith('http')) {
      endpoint = endpoint.replaceFirst(RegExp(r'^https?://[^/]+/?'), '');
    }
    endpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return endpoint.split('?').first;
  }

  static String? _readString(String key) {
    final value = _box.read(key);
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
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
      } else if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
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
    return parseApiMessage(
      response.body,
      fallback: response.statusText?.trim().isNotEmpty == true
          ? response.statusText!.trim()
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

    // Joi messages often include quoted keys: "email" must be a valid email.
    text = text.replaceAllMapped(RegExp(r'"([^"]+)"'), (m) => m.group(1) ?? '');

    if (text.length > 1) {
      text = '${text[0].toUpperCase()}${text.substring(1)}';
    }

    if (!RegExp(r'[.!?]$').hasMatch(text)) {
      text = '$text.';
    }

    return text;
  }

  static Future<void> persistAuthSession(User user) async {
    if ((user.accessToken ?? '').isNotEmpty) {
      await _box.write(TOKEN, user.accessToken);
    }
    if ((user.refreshToken ?? '').isNotEmpty) {
      await _box.write(REFRESH_TOKEN, user.refreshToken);
    }
    if ((user.tokenType ?? '').isNotEmpty) {
      await _box.write(TOKEN_TYPE, user.tokenType);
    }
    if ((user.accessTokenExpiresIn ?? '').isNotEmpty) {
      await _box.write(ACCESS_TOKEN_EXPIRES_IN, user.accessTokenExpiresIn);
    }

    final storedUserRaw = _box.read(USER_INFO_BOX);
    User? storedUser;
    if (storedUserRaw is Map<String, dynamic> && storedUserRaw.isNotEmpty) {
      storedUser = User.fromJson(storedUserRaw);
    }

    final mergedUser = User(
      sId: user.sId ?? storedUser?.sId,
      email: user.email ?? storedUser?.email,
      password: storedUser?.password,
      googleId: user.googleId ?? storedUser?.googleId,
      favorites: user.favorites ?? storedUser?.favorites,
      role: user.role ?? storedUser?.role,
      address: user.address ?? storedUser?.address,
      accessToken: user.accessToken ?? storedUser?.accessToken ?? _readString(TOKEN),
      refreshToken: user.refreshToken ?? storedUser?.refreshToken ?? _readString(REFRESH_TOKEN),
      tokenType: user.tokenType ?? storedUser?.tokenType ?? _readString(TOKEN_TYPE),
      accessTokenExpiresIn: user.accessTokenExpiresIn ??
          storedUser?.accessTokenExpiresIn ??
          _readString(ACCESS_TOKEN_EXPIRES_IN),
      createdAt: user.createdAt ?? storedUser?.createdAt,
      updatedAt: user.updatedAt ?? storedUser?.updatedAt,
      iV: user.iV ?? storedUser?.iV,
    );

    await _box.write(USER_INFO_BOX, mergedUser.toJson());
  }

  static Future<void> clearAuthSession({bool clearAddress = false}) async {
    await _box.remove(TOKEN);
    await _box.remove(REFRESH_TOKEN);
    await _box.remove(TOKEN_TYPE);
    await _box.remove(ACCESS_TOKEN_EXPIRES_IN);
    await _box.remove(USER_INFO_BOX);

    if (clearAddress) {
      await _box.remove(PHONE_KEY);
      await _box.remove(STREET_KEY);
      await _box.remove(CITY_KEY);
      await _box.remove(STATE_KEY);
      await _box.remove(POSTAL_CODE_KEY);
      await _box.remove(COUNTRY_KEY);
    }
  }

  static Future<void> handleSessionExpired({bool navigateToLogin = true}) async {
    await clearAuthSession();

    if (!navigateToLogin || _isRedirectingToLogin) {
      return;
    }

    _isRedirectingToLogin = true;
    Get.offAll(() => const LoginScreen());
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      _isRedirectingToLogin = false;
    });
  }

  static Future<bool> bootstrapSession() async {
    final accessToken = _readString(TOKEN);
    final refreshToken = _readString(REFRESH_TOKEN);

    if ((accessToken ?? '').isEmpty && (refreshToken ?? '').isEmpty) {
      await clearAuthSession();
      return false;
    }

    final service = HttpService();

    if ((accessToken ?? '').isEmpty && (refreshToken ?? '').isNotEmpty) {
      return await service._refreshTokenWithLock(navigateOnFail: false);
    }

    try {
      final meResponse = await service.get(
        service._buildUrl('users/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (meResponse.isOk) {
        await service._persistUserFromAnyPayload(meResponse.body);
        return true;
      }

      if (meResponse.statusCode == 401) {
        final refreshed = await service._refreshTokenWithLock(navigateOnFail: false);
        if (!refreshed) return false;

        final retryToken = _readString(TOKEN);
        if ((retryToken ?? '').isEmpty) return false;

        final retryMe = await service.get(
          service._buildUrl('users/me'),
          headers: {'Authorization': 'Bearer $retryToken'},
        );
        if (retryMe.isOk) {
          await service._persistUserFromAnyPayload(retryMe.body);
          return true;
        }

        if (retryMe.statusCode == 401) {
          await clearAuthSession();
          return false;
        }
      }
    } catch (_) {
      // Keep existing session on startup when network is unstable.
      return true;
    }

    return (accessToken ?? '').isNotEmpty;
  }

  bool _isRefreshEndpoint(String endpointUrl) {
    return _normalizeEndpoint(endpointUrl) == 'users/refresh-token';
  }

  bool _isAuthFreeEndpoint(String endpointUrl) {
    final endpoint = _normalizeEndpoint(endpointUrl);
    return endpoint == 'users/login' ||
        endpoint == 'users/register' ||
        endpoint == 'users/refresh-token';
  }

  Future<void> _persistUserFromAnyPayload(dynamic body) async {
    if (body is! Map<String, dynamic>) return;

    dynamic payload = body;
    if (payload['data'] is Map<String, dynamic>) {
      payload = payload['data'];
    }

    if (payload is Map<String, dynamic>) {
      final user = User.fromJson(payload);
      await persistAuthSession(user);
    }
  }

  Future<bool> _refreshTokenWithLock({bool navigateOnFail = true}) async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken = _readString(REFRESH_TOKEN);
      if ((refreshToken ?? '').isEmpty) {
        await handleSessionExpired(navigateToLogin: navigateOnFail);
        completer.complete(false);
        return false;
      }

      final response = await post(
        _buildUrl('users/refresh-token'),
        {'refreshToken': refreshToken},
      );

      if (response.isOk && response.body is Map<String, dynamic>) {
        final dynamic data = response.body['data'];
        if (data is Map<String, dynamic>) {
          final user = User.fromJson(data);
          if ((user.accessToken ?? '').isNotEmpty &&
              (user.refreshToken ?? '').isNotEmpty) {
            await persistAuthSession(user);
            completer.complete(true);
            return true;
          }
        }
      }

      await handleSessionExpired(navigateToLogin: navigateOnFail);
      completer.complete(false);
      return false;
    } catch (e) {
      log('[AUTH] refresh error: $e');
      await handleSessionExpired(navigateToLogin: navigateOnFail);
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Response<T>> _sendWithAuthRetry<T>({
    required String endpointUrl,
    required Future<Response<T>> Function(Map<String, String> headers) send,
    bool includeAuth = true,
    bool allowRefreshOn401 = true,
  }) async {
    final headers = _getHeaders(includeAuth: includeAuth);
    final hadAccessToken = headers.containsKey('Authorization');

    Response<T> response = await send(headers);

    final shouldTryRefresh = allowRefreshOn401 &&
        response.statusCode == 401 &&
        includeAuth &&
        hadAccessToken &&
        !_isRefreshEndpoint(endpointUrl) &&
        !_isAuthFreeEndpoint(endpointUrl);

    if (!shouldTryRefresh) {
      return response;
    }

    final refreshed = await _refreshTokenWithLock(navigateOnFail: true);
    if (!refreshed) {
      return response;
    }

    final retryHeaders = _getHeaders(includeAuth: includeAuth);
    response = await send(retryHeaders);
    return response;
  }

  Future<Response> getItems({
    required String endpointUrl,
    bool includeAuth = true,
    bool allowRefreshOn401 = true,
  }) async {
    try {
      final response = await _sendWithAuthRetry(
        endpointUrl: endpointUrl,
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => get(_buildUrl(endpointUrl), headers: headers),
      );
      log('[GET] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
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
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => post(_buildUrl(endpointUrl), itemData, headers: headers),
      );
      log('[POST] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
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
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => put(
          _buildUrl('$endpointUrl/$itemId'),
          itemData,
          headers: headers,
        ),
      );
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
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
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => put(
          _buildUrl(endpointUrl),
          itemData,
          headers: headers,
        ),
      );
      log('[PUT] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
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
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => delete(
          _buildUrl('$endpointUrl/$itemId'),
          headers: headers,
        ),
      );
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
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
        includeAuth: includeAuth,
        allowRefreshOn401: allowRefreshOn401,
        send: (headers) => request(
          _buildUrl(endpointUrl),
          'DELETE',
          body: body,
          headers: headers,
        ),
      );
      log('[DELETE] ${response.statusCode} => $endpointUrl');
      return response;
    } catch (e) {
      return Response(body: {'message': e.toString()}, statusCode: 500);
    }
  }
}
