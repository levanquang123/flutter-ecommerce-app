import 'package:flutter/material.dart' show Color;

class AppColor {
  const AppColor._();

  // Primary Colors - QMarket Branding
  static const primary = Color(0xFFEC6813); // Main Action Color
  static const primaryLight = Color(0xFFFDEEE3);
  static const primaryDark = Color(0xFFB84E0B);

  // Neutral Colors - For Spacing, Backgrounds and Borders
  static const background = Color(0xFFF8F9FA); // Standard Material Background
  static const cardBackground = Color(0xFFFFFFFF);
  static const border = Color(0xFFE9ECEF);
  
  // Text Colors - High Contrast for Readability
  static const textPrimary = Color(0xFF212529); // Headlines
  static const textSecondary = Color(0xFF6C757D); // Subtitles/Body
  static const textHint = Color(0xFFADB5BD);

  // Status Colors
  static const error = Color(0xFFDC3545);
  static const success = Color(0xFF28A745);

  // Legacy Mapping (To avoid breaking existing code)
  static const darkOrange = primary;
  static const lightOrange = Color(0xFFf8b89a);
  static const darkGrey = textSecondary;
  static const lightGrey = border;
}
