import 'package:flutter/material.dart';
import 'package:klockerapp/utils/custom_theme/text_theme.dart';
import 'package:klockerapp/utils/custom_theme/appbar_theme.dart';
import 'package:klockerapp/utils/custom_theme/bottomnav_theme.dart';

class KlockerappTheme {
  KlockerappTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: Colors.lightGreenAccent,
    scaffoldBackgroundColor: Colors.white,
    textTheme: KAppTextTheme.lightTextTheme,
    appBarTheme: KAppBarTheme.lightAppBarTheme,
    bottomNavigationBarTheme: KBottomNavTheme.lightBottomNavTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green, // Change this to your main brand color!
      brightness: Brightness.light,
    ),
    inputDecorationTheme: InputDecorationTheme(
      // Style for the border when the field is not focused
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(width: 1, color: Colors.grey),
      ),
      // Style for the border when the field is focused (tapped on)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          width: 2,
          color: Colors.green,
        ), // Uses your brand color
      ),
      // Style for the label text (e.g., "Name", "Email")
      labelStyle: const TextStyle(color: Colors.black54),
      // Style for the hint text (e.g., "Enter Employee Name")
      hintStyle: const TextStyle(color: Colors.black45),
    ),
  );
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: Colors.lightGreenAccent,
    scaffoldBackgroundColor: Colors.black,
    textTheme: KAppTextTheme.darkTextTheme,
    appBarTheme: KAppBarTheme.darkAppBarTheme,
    bottomNavigationBarTheme: KBottomNavTheme.darkBottomNavTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green, // Use the same brand color
      brightness: Brightness.dark, // Crucial for dark mode colors
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(width: 1, color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          width: 2,
          color: Colors.green,
        ), // Uses your brand color
      ),
      // Style for the label text in dark mode
      labelStyle: const TextStyle(color: Colors.white),
      // Style for the hint text in dark mode
      hintStyle: const TextStyle(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.green),
  );
}
