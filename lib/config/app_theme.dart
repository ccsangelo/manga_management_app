import 'package:flutter/material.dart';

// Centralized color and text style constants
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF333333);
  static const Color accent = Colors.deepPurple;
  static const Color accentLight = Colors.deepPurpleAccent;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle title = TextStyle(
      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle heading = TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle sectionHeader = TextStyle(
      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle bodyLarge =
      TextStyle(fontSize: 16, color: Colors.white);
  static const TextStyle body = TextStyle(fontSize: 14, color: Colors.white);
  static const TextStyle bodySecondary =
      TextStyle(fontSize: 14, color: Colors.grey, height: 1.5);
  static const TextStyle label =
      TextStyle(fontSize: 12, color: Colors.white);
  static const TextStyle caption =
      TextStyle(fontSize: 13, color: Colors.grey);
}

// TextTheme built from AppTextStyles for use in ThemeData
TextTheme get appTextTheme => const TextTheme(
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.heading,
      titleSmall: AppTextStyles.sectionHeader,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.bodySecondary,
      labelLarge: AppTextStyles.label,
      labelSmall: AppTextStyles.caption,
    );
