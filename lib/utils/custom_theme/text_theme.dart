import 'package:flutter/material.dart';

class KAppTextTheme {
  KAppTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: const TextStyle(
      fontSize: 28,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: const TextStyle(
      fontSize: 24,
      color: Colors.black,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: const TextStyle(
      fontSize: 20,
      color: Colors.black,
      fontWeight: FontWeight.w500,
    ),
    titleLarge: const TextStyle(
      fontSize: 20,
      color: Colors.black,
      fontWeight: FontWeight.bold, // Often used for AppBars
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      color: Colors.black,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      color: Colors.black,
      fontWeight: FontWeight.w300,
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      color: Colors.black,
      fontWeight: FontWeight.bold, // Often used for Buttons
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    labelSmall: const TextStyle(
      fontSize: 10,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
  );

  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: const TextStyle(
      fontSize: 28,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: const TextStyle(
      fontSize: 24,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: const TextStyle(
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    ),
    titleLarge: const TextStyle(
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.bold, // Often used for AppBars
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      color: Colors.white,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      color: Colors.white,
      fontWeight: FontWeight.w300,
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.bold, // Often used for Buttons
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    labelSmall: const TextStyle(
      fontSize: 10,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  );
}
