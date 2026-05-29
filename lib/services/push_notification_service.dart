import 'dart:async';
import 'dart:developer';

import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../models/user.dart';
import '../utility/constants.dart';

class PushNotificationService {
  static const Duration _oneSignalTimeout = Duration(seconds: 5);
  static const String _loggedInTag = 'logged_in';
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      OneSignal.initialize(ONE_SIGNAL_APP_ID);
      _isInitialized = true;
      unawaited(
        OneSignal.Notifications.requestPermission(true).timeout(
          _oneSignalTimeout,
          onTimeout: () => false,
        ),
      );
    } catch (error) {
      log('OneSignal initialize error: $error');
    }
  }

  static Future<void> identifyUser(User? user) async {
    final externalId = user?.sId?.trim();
    if (externalId == null || externalId.isEmpty) return;
    if (!_isInitialized) return;

    try {
      final currentExternalId = await OneSignal.User.getExternalId().timeout(
        _oneSignalTimeout,
        onTimeout: () => null,
      );

      if (currentExternalId != externalId) {
        await OneSignal.login(externalId).timeout(_oneSignalTimeout);
      }

      await OneSignal.User.addTagWithKey(_loggedInTag, 'true').timeout(
        _oneSignalTimeout,
      );
    } catch (error) {
      log('OneSignal identify user error: $error');
    }
  }

  static Future<void> clearUser() async {
    if (!_isInitialized) return;

    try {
      await OneSignal.User.removeTag(_loggedInTag).timeout(_oneSignalTimeout);

      final currentExternalId = await OneSignal.User.getExternalId().timeout(
        _oneSignalTimeout,
        onTimeout: () => null,
      );
      if (currentExternalId == null || currentExternalId.isEmpty) return;

      await OneSignal.logout().timeout(_oneSignalTimeout);
    } catch (error) {
      log('OneSignal clear user error: $error');
    }
  }
}
