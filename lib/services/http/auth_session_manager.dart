import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/user.dart';
import '../../screen/login_screen/login_screen.dart';
import '../../utility/constants.dart';
import '../push_notification_service.dart';
import 'auth_storage.dart';
import 'http_client_utils.dart';

class AuthSessionManager {
  static Completer<bool>? _refreshCompleter;
  static bool _isRedirectingToLogin = false;
  static const Uuid _uuid = Uuid();
  static const String _clientType = 'mobile_client';

  // ---- Sentry User ----
  static Future<void> setSentryUser(User? user) async {
    await Sentry.configureScope((scope) {
      if (user == null) {
        scope.setUser(null);
        return;
      }
      scope.setUser(SentryUser(
        id: user.sId,
        email: user.email,
        data: {'role': user.role},
      ));
    });
  }

  // ---- Session Persistence ----
  static Future<void> persistAuthSession(User user) async {
    if ((user.accessToken ?? '').isNotEmpty) {
      await AuthStorage.writeSecureString(TOKEN, user.accessToken);
    }
    if ((user.refreshToken ?? '').isNotEmpty) {
      await AuthStorage.writeSecureString(REFRESH_TOKEN, user.refreshToken);
    }
    if ((user.tokenType ?? '').isNotEmpty) {
      await AuthStorage.writeSecureString(TOKEN_TYPE, user.tokenType);
    }
    if ((user.accessTokenExpiresIn ?? '').isNotEmpty) {
      await AuthStorage.writeSecureString(
        ACCESS_TOKEN_EXPIRES_IN,
        user.accessTokenExpiresIn,
      );
    }

    final storedUserRaw = AuthStorage.box.read(USER_INFO_BOX);
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
      emailVerified: user.emailVerified || (storedUser?.emailVerified ?? false),
      address: user.address ?? storedUser?.address,
      accessToken: user.accessToken ??
          storedUser?.accessToken ??
          AuthStorage.readString(TOKEN),
      refreshToken: user.refreshToken ??
          storedUser?.refreshToken ??
          AuthStorage.readString(REFRESH_TOKEN),
      tokenType: user.tokenType ??
          storedUser?.tokenType ??
          AuthStorage.readString(TOKEN_TYPE),
      accessTokenExpiresIn: user.accessTokenExpiresIn ??
          storedUser?.accessTokenExpiresIn ??
          AuthStorage.readString(ACCESS_TOKEN_EXPIRES_IN),
      createdAt: user.createdAt ?? storedUser?.createdAt,
      updatedAt: user.updatedAt ?? storedUser?.updatedAt,
      iV: user.iV ?? storedUser?.iV,
    );

    await AuthStorage.box.write(
      USER_INFO_BOX,
      mergedUser.toJson(includeTokens: false),
    );
    await setSentryUser(mergedUser);
    await PushNotificationService.identifyUser(mergedUser);
  }

  // ---- Session Clear ----
  static Future<void> clearAuthSession({bool clearAddress = false}) async {
    await AuthStorage.deleteSecureString(TOKEN);
    await AuthStorage.deleteSecureString(REFRESH_TOKEN);
    await AuthStorage.deleteSecureString(TOKEN_TYPE);
    await AuthStorage.deleteSecureString(ACCESS_TOKEN_EXPIRES_IN);
    await AuthStorage.box.remove(USER_INFO_BOX);

    if (clearAddress) {
      await AuthStorage.box.remove(PHONE_KEY);
      await AuthStorage.box.remove(STREET_KEY);
      await AuthStorage.box.remove(CITY_KEY);
      await AuthStorage.box.remove(STATE_KEY);
      await AuthStorage.box.remove(POSTAL_CODE_KEY);
      await AuthStorage.box.remove(COUNTRY_KEY);
    }

    await setSentryUser(null);
    await PushNotificationService.clearUser();
  }

  // ---- Session Expiry ----
  static Future<void> handleSessionExpired(
      {bool navigateToLogin = true}) async {
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

  // ---- Bootstrap ----
  /// Restores the user session from stored credentials on app start.
  /// Returns true if a valid session was established.
  static Future<bool> bootstrapSession({
    required Future<Response<dynamic>> Function(String url,
            {Map<String, String>? headers})
        httpGet,
    required Future<bool> Function({required bool navigateOnFail})
        refreshWithLock,
  }) async {
    await AuthStorage.loadAuthCache();
    final accessToken = AuthStorage.readString(TOKEN);
    final refreshToken = AuthStorage.readString(REFRESH_TOKEN);

    if ((accessToken ?? '').isEmpty && (refreshToken ?? '').isEmpty) {
      await clearAuthSession();
      return false;
    }

    if ((accessToken ?? '').isEmpty && (refreshToken ?? '').isNotEmpty) {
      return await refreshWithLock(navigateOnFail: false);
    }

    try {
      final meResponse = await httpGet(
        HttpClientUtils.buildUrl('users/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (meResponse.isOk) {
        await persistUserFromAnyPayload(meResponse.body);
        return true;
      }

      if (meResponse.statusCode == 401) {
        final refreshed = await refreshWithLock(navigateOnFail: false);
        if (!refreshed) return false;

        final retryToken = AuthStorage.readString(TOKEN);
        if ((retryToken ?? '').isEmpty) return false;

        final retryMe = await httpGet(
          HttpClientUtils.buildUrl('users/me'),
          headers: {'Authorization': 'Bearer $retryToken'},
        );
        if (retryMe.isOk) {
          await persistUserFromAnyPayload(retryMe.body);
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

  static Future<void> persistUserFromAnyPayload(dynamic body) async {
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

  // ---- Token Refresh (with lock) ----
  static Future<bool> refreshTokenWithLock({
    required bool navigateOnFail,
    required Map<String, String> Function() buildTracingHeaders,
    required Uri Function(String) buildUri,
  }) async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    String? attemptedRefreshToken;

    try {
      final refreshToken = AuthStorage.readString(REFRESH_TOKEN);
      attemptedRefreshToken = refreshToken;
      if ((refreshToken ?? '').isEmpty) {
        await handleSessionExpired(navigateToLogin: navigateOnFail);
        completer.complete(false);
        return false;
      }

      final requestId = _uuid.v4();
      final rawResponse = await http
          .post(
            buildUri('users/refresh-token'),
            headers: {
              'content-type': 'application/json',
              'accept': 'application/json',
              'x-client-type': _clientType,
              'x-request-id': requestId,
              'x-refresh-token': refreshToken!,
              ...buildTracingHeaders(),
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 30));

      dynamic decodedBody;
      try {
        decodedBody =
            rawResponse.body.isEmpty ? null : jsonDecode(rawResponse.body);
      } catch (_) {
        decodedBody = rawResponse.body;
      }

      final response = Response<dynamic>(
        body: decodedBody,
        statusCode: rawResponse.statusCode,
        statusText: rawResponse.reasonPhrase,
        headers: rawResponse.headers,
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

      if (_storedRefreshTokenChanged(refreshToken)) {
        completer.complete(true);
        return true;
      }

      if (_isExplicitInvalidRefreshResponse(response)) {
        await handleSessionExpired(navigateToLogin: navigateOnFail);
      }
      completer.complete(false);
      return false;
    } catch (e, stackTrace) {
      log('[AUTH] refresh error: $e');
      await Sentry.addBreadcrumb(
        Breadcrumb(
          type: 'auth',
          category: 'auth.refresh_token',
          level: SentryLevel.error,
          message: 'Refresh token request failed',
        ),
      );
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('service', 'mobile-client');
          scope.setTag('client_type', _clientType);
          scope.setTag('endpoint', 'users/refresh-token');
          scope.setTag('method', 'POST');
        },
      );
      if (attemptedRefreshToken != null &&
          _storedRefreshTokenChanged(attemptedRefreshToken)) {
        completer.complete(true);
        return true;
      }
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  // ---- Private Helpers ----
  static bool _storedRefreshTokenChanged(String previousRefreshToken) {
    final latestRefreshToken = AuthStorage.readString(REFRESH_TOKEN);
    return latestRefreshToken != null &&
        latestRefreshToken.isNotEmpty &&
        latestRefreshToken != previousRefreshToken;
  }

  static bool _isExplicitInvalidRefreshResponse(
      Response<dynamic> response) {
    final body = response.body;
    if (body is! Map) return response.statusCode == 401;
    final message = body['message']?.toString().toLowerCase() ?? '';
    return response.statusCode == 401 &&
        (message.contains('invalid or expired refresh token') ||
            message.contains('refresh token expired') ||
            message.contains('refresh token is required') ||
            message.contains('session expired') ||
            message.contains('invalid token type'));
  }
}
