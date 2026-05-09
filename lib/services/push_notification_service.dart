import 'dart:developer';

import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../models/user.dart';
import '../utility/constants.dart';

class PushNotificationService {
  static Future<void> initialize() async {
    try {
      OneSignal.initialize(ONE_SIGNAL_APP_ID);
      await OneSignal.Notifications.requestPermission(true);
    } catch (error) {
      log('OneSignal initialize error: $error');
    }
  }

  static Future<void> identifyUser(User? user) async {
    final externalId = user?.sId?.trim();
    if (externalId == null || externalId.isEmpty) return;

    try {
      final currentExternalId = await OneSignal.User.getExternalId();
      if (currentExternalId == externalId) return;

      await OneSignal.login(externalId);
    } catch (error) {
      log('OneSignal identify user error: $error');
    }
  }

  static Future<void> clearUser() async {
    try {
      final currentExternalId = await OneSignal.User.getExternalId();
      if (currentExternalId == null || currentExternalId.isEmpty) return;

      await OneSignal.logout();
    } catch (error) {
      log('OneSignal clear user error: $error');
    }
  }
}
