import 'package:flutter/material.dart';

/// Typography only — size, weight, spacing.
///
/// Deliberately carries NO colour. Colour comes from `ColorScheme`, which
/// means one definition serves both light and dark instead of two parallel
/// copies that have to be kept in step.
///
/// This replaces the previous light/dark pair where every one of the 12
/// styles hardcoded `Colors.black` or `Colors.white`. If a style needs a
/// non-default colour at a call site, use `.copyWith(color: ...)` there.
class KAppTextTheme {
  KAppTextTheme._();

  static const _font = 'Poppins';

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _font,
      fontSize: 48,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.0,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontFamily: _font,
      fontSize: 36,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.15,
    ),
    displaySmall: TextStyle(
      fontFamily: _font,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
    ),

    headlineLarge: TextStyle(
      fontFamily: _font,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: _font,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontFamily: _font,
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),

    titleLarge: TextStyle(
      fontFamily: _font,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      fontFamily: _font,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),

    bodyLarge: TextStyle(
      fontFamily: _font,
      fontSize: 16,
      fontWeight: FontWeight.normal,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: _font,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),

    labelLarge: TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.2,
    ),
    labelMedium: TextStyle(
      fontFamily: _font,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
    labelSmall: TextStyle(
      fontFamily: _font,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    ),
  );
}
