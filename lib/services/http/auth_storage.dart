import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../utility/constants.dart';
import '../push_notification_service.dart';

class AuthStorage {
  static final GetStorage _box = GetStorage();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final Map<String, String> _secureCache = {};
  static bool _authStorageWasReset = false;

  static const Set<String> secureKeys = {
    TOKEN,
    REFRESH_TOKEN,
    TOKEN_TYPE,
    ACCESS_TOKEN_EXPIRES_IN,
  };

  static String? readString(String key) {
    if (secureKeys.contains(key)) {
      return _secureCache[key];
    }
    final value = _box.read(key);
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty || str == 'null' || str == 'undefined') {
      return null;
    }
    return str;
  }

  static Future<String?> readSecureString(String key) async {
    if (!secureKeys.contains(key)) return readString(key);

    final cached = _secureCache[key];
    if (cached != null && cached.isNotEmpty) return cached;

    String? value;
    try {
      value = await _secureStorage.read(key: key);
    } on PlatformException catch (e, stackTrace) {
      if (!_isSecureStorageDecryptError(e)) rethrow;
      await _handleSecureStorageDecryptError(e, stackTrace);
      return null;
    }

    value ??= _box.read(key)?.toString();
    final normalized = _normalizeStoredString(value);
    if (normalized == null) return null;

    _secureCache[key] = normalized;
    await _secureStorage.write(key: key, value: normalized);
    await _box.remove(key);
    return normalized;
  }

  static bool _isSecureStorageDecryptError(PlatformException exception) {
    final raw = [
      exception.code,
      exception.message,
      exception.details,
    ].whereType<Object>().join(' ').toLowerCase();

    return raw.contains('bad_decrypt') ||
        raw.contains('badpaddingexception') ||
        raw.contains('bad padding') ||
        raw.contains('failed to unwrap key') ||
        raw.contains('invalidkeyexception') ||
        raw.contains('keystore');
  }

  static Future<void> _handleSecureStorageDecryptError(
    PlatformException exception,
    StackTrace stackTrace,
  ) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'auth',
        category: 'auth.secure_storage',
        level: SentryLevel.warning,
        message: 'Secure storage could not decrypt existing auth data',
      ),
    );

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = SentryLevel.warning;
        scope.setTag('service', 'mobile-client');
        scope.setTag('client_type', 'mobile_client');
        scope.setTag('auth_storage_reset', 'true');
      },
    );

    await resetCorruptedAuthStorage();
  }

  static Future<void> resetCorruptedAuthStorage() async {
    _authStorageWasReset = true;
    _secureCache.clear();

    try {
      await _secureStorage.deleteAll();
    } on PlatformException catch (e) {
      log('[AUTH] secure storage deleteAll failed after decrypt error: $e');
    }

    for (final key in secureKeys) {
      await _box.remove(key);
    }
    await _box.remove(USER_INFO_BOX);
    await Sentry.configureScope((scope) => scope.setUser(null));
    await PushNotificationService.clearUser();
  }

  static String? _normalizeStoredString(String? value) {
    final str = value?.trim();
    if (str == null || str.isEmpty || str == 'null' || str == 'undefined') {
      return null;
    }
    return str;
  }

  static Future<void> writeSecureString(String key, String? value) async {
    final normalized = _normalizeStoredString(value);
    if (normalized == null) return;

    _secureCache[key] = normalized;
    await _secureStorage.write(key: key, value: normalized);
    await _box.remove(key);
  }

  static Future<void> deleteSecureString(String key) async {
    _secureCache.remove(key);
    await _secureStorage.delete(key: key);
    await _box.remove(key);
  }

  static Future<void> loadAuthCache() async {
    _authStorageWasReset = false;
    for (final key in secureKeys) {
      await readSecureString(key);
      if (_authStorageWasReset) {
        break;
      }
    }
  }

  static GetStorage get box => _box;
}
