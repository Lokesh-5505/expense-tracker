import 'package:flutter/material.dart';

class AppTextStyles {
  // Balance Header (Display) with Tabular Figures
  static TextStyle balanceAmount({
    Color? color,
    double fontSize = 34.0,
    FontWeight fontWeight = FontWeight.w800,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.8,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Section Heading
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // Card Header / Subheading
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // Transaction Amount with Tabular Figures
  static TextStyle transactionAmount({
    Color? color,
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Body Regular
  static const TextStyle body = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  // Body Medium
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // Caption / Subtitle
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  // Keypad Number
  static const TextStyle keypadNumber = TextStyle(
    fontSize: 26.0,
    fontWeight: FontWeight.w600,
  );
}
