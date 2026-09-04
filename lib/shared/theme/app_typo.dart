import 'package:flutter/material.dart';

abstract final class AppTypo {
  static const double displayLg = 32;
  static const double displayMd = 28;
  static const double titleLg = 24;
  static const double titleMd = 20;
  static const double titleSm = 18;
  static const double bodyLg = 16;
  static const double bodyMd = 14;
  static const double bodySm = 12;
  static const double caption = 11;
  static const double overline = 10;

  static const TextStyle display = TextStyle(
    fontSize: displayLg,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle headline = TextStyle(
    fontSize: titleLg,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle title = TextStyle(
    fontSize: titleMd,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: titleSm,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: bodyLg,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: bodyMd,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontSize: bodySm,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: caption,
    fontWeight: FontWeight.w400,
  );
}
