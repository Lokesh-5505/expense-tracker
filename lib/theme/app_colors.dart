import 'package:flutter/material.dart';

class AppColors {
  // Brand Default Seed
  static const Color defaultPrimary = Color(0xFF1A237E); // Deep Indigo

  // Semantic Colors (Light)
  static const Color income = Color(0xFF00C853); // Vibrant Green
  static const Color expense = Color(0xFFFF3D57); // Modern Coral Red
  static const Color transfer = Color(0xFF2979FF); // Electric Blue
  static const Color warning = Color(0xFFFFB300); // Amber Warning
  static const Color info = Color(0xFF00B0FF); // Sky Blue Info

  // Semantic Colors (Dark)
  static const Color incomeDark = Color(0xFF69F0AE);
  static const Color expenseDark = Color(0xFFFF8A80);
  static const Color transferDark = Color(0xFF82B1FF);
  static const Color warningDark = Color(0xFFFFD54F);

  // Neutral & Surfaces (True Dark Mode)
  static const Color darkBackground = Color(0xFF0D0E15);
  static const Color darkSurface = Color(0xFF151824);
  static const Color darkSurfaceVariant = Color(0xFF1E2235);
  static const Color darkBorder = Color(0xFF292E46);

  // Light Surfaces
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF2F6);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Gradient Presets for Balance Card
  static const List<Color> balanceCardGradient = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  static const List<Color> balanceCardGradientAlt = [
    Color(0xFF004D40),
    Color(0xFF00695C),
    Color(0xFF00897B),
  ];

  // Shimmer / Highlight colors
  static const Color glassHighlight = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}
