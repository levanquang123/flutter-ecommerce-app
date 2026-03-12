import 'package:flutter/material.dart';
import '../main.dart';

class SnackBarHelper {
  static void showSuccessSnackBar(String message) {
    // Xóa ngay lập tức SnackBar đang hiện (nếu có) để hiện cái mới luôn
    messengerKey.currentState?.removeCurrentSnackBar();

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.fixed, // Dài hết chiều ngang ở dưới
        duration: const Duration(milliseconds: 1500), // Hiện trong 1.5 giây
      ),
    );
  }

  static void showErrorSnackBar(String message) {
    // Xóa ngay lập tức SnackBar đang hiện (nếu có) để hiện cái mới luôn
    messengerKey.currentState?.removeCurrentSnackBar();

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed, // Dài hết chiều ngang ở dưới
        duration: const Duration(milliseconds: 1500), // Hiện trong 1.5 giây
      ),
    );
  }
}
