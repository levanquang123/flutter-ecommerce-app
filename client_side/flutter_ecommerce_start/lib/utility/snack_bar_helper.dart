import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackBarHelper {

  static DateTime? _lastShown;

  static void showErrorSnackBar(String message, {String title = "Error"}) {

    final now = DateTime.now();

    if (_lastShown != null &&
        now.difference(_lastShown!) < const Duration(milliseconds: 800)) {
      return; // chặn spam snackbar
    }

    _lastShown = now;

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      borderRadius: 20,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.error, color: Colors.white),
      animationDuration: const Duration(milliseconds: 500),
      snackPosition: SnackPosition.TOP,
    );
  }

  static void showSuccessSnackBar(String message, {String title = "Success"}) {

    final now = DateTime.now();

    if (_lastShown != null &&
        now.difference(_lastShown!) < const Duration(milliseconds: 800)) {
      return;
    }

    _lastShown = now;

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      borderRadius: 20,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
      animationDuration: const Duration(milliseconds: 500),
      snackPosition: SnackPosition.TOP,
    );
  }
}