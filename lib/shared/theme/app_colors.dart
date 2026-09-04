import 'package:flutter/material.dart';

import '../../core/constants/exercise_category.dart';

class AppColors {
  // Primary — brand orange
  static const primary = Color(0xFFF66C1E);
  static const primaryDark = Color(0xFFD4580F);
  static const primaryLight = Color(0xFFFDB288);

  // Secondary — brand lime accent
  static const secondary = Color(0xFFC8FF00);
  static const secondaryDark = Color(0xFF9ACC00);

  // Success
  static const success = Color(0xFF4CAF50);
  static const successDark = Color(0xFF388E3C);

  // Brand
  static const brandBackground = Color(0xFF0D0D12);
  static const brandOrange = Color(0xFFF66C1E);
  static const brandAccent = Color(0xFFC8FF00);

  // Background
  static const backgroundLight = Color(0xFFF5F5F5);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E1E1E);

  // Text
  static const textPrimaryLight = Color(0xFF212121);
  static const textSecondaryLight = Color(0xFF757575);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFB3B3B3);

  // Categories
  static const chest = Color(0xFFE53935);
  static const back = Color(0xFF1E88E5);
  static const legs = Color(0xFF43A047);
  static const shoulders = Color(0xFFFB8C00);
  static const arms = Color(0xFF8E24AA);
  static const cardio = Color(0xFF00ACC1);
  static const other = Color(0xFF757575);

  static Color getCategoryColor(String category) {
    return ExerciseCategory.fromString(category).color;
  }
}
