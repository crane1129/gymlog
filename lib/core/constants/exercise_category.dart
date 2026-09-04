import 'package:flutter/material.dart';

enum ExerciseCategory {
  chest,
  back,
  legs,
  shoulders,
  arms,
  cardio,
  other;

  String get labelKo => switch (this) {
        chest => '가슴',
        back => '등',
        legs => '하체',
        shoulders => '어깨',
        arms => '팔',
        cardio => '유산소',
        other => '기타',
      };

  String get labelEn => switch (this) {
        chest => 'Chest',
        back => 'Back',
        legs => 'Legs',
        shoulders => 'Shoulders',
        arms => 'Arms',
        cardio => 'Cardio',
        other => 'Other',
      };

  String label(bool isKorean) => isKorean ? labelKo : labelEn;

  Color get color => switch (this) {
        chest => const Color(0xFFE53935),
        back => const Color(0xFF1E88E5),
        legs => const Color(0xFF43A047),
        shoulders => const Color(0xFFFB8C00),
        arms => const Color(0xFF8E24AA),
        cardio => const Color(0xFF00ACC1),
        other => const Color(0xFF757575),
      };

  static ExerciseCategory fromString(String value) {
    final lower = value.toLowerCase();
    for (final cat in values) {
      if (cat.labelKo == value ||
          cat.labelEn == value ||
          cat.name == lower) {
        return cat;
      }
    }
    return other;
  }

  static List<String> labels(bool isKorean) =>
      values.map((c) => c.label(isKorean)).toList();
}
