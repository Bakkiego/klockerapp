import 'package:flutter/material.dart';

class KAppTextTheme {
  KAppTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle().copyWith(
      fontSize: 30,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle().copyWith(
      fontSize: 20,
      color: Colors.black,
      fontWeight: FontWeight.normal,
    ),
    headlineSmall: TextStyle().copyWith(
      fontSize: 10,
      color: Colors.black,
      fontWeight: FontWeight.w300,
    ),
    bodySmall: TextStyle().copyWith(
      fontSize: 10,
      color: Colors.black,
      fontWeight: FontWeight.w300,
    ),
    bodyMedium: TextStyle().copyWith(
      fontSize: 20,
      color: Colors.black,
      fontWeight: FontWeight.normal,
    ),
    bodyLarge: TextStyle().copyWith(
      fontSize: 30,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    labelLarge: TextStyle().copyWith(
      fontSize: 30,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    labelMedium: TextStyle().copyWith(
      fontSize: 20,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    labelSmall: TextStyle().copyWith(
      fontSize: 10,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle().copyWith(
      fontSize: 30,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle().copyWith(
      fontSize: 20,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    titleSmall: TextStyle().copyWith(
      fontSize: 10,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
  );
  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: TextStyle().copyWith(
      fontSize: 30,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle().copyWith(
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.normal,
    ),
    headlineSmall: TextStyle().copyWith(
      fontSize: 10,
      color: Colors.white,
      fontWeight: FontWeight.w300,
    ),
    bodySmall: TextStyle().copyWith(
      fontSize: 10,
      color: Colors.white,
      fontWeight: FontWeight.w300,
    ),
    bodyMedium: TextStyle().copyWith(
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.normal,
    ),
    bodyLarge: TextStyle().copyWith(
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    labelLarge: TextStyle().copyWith(
      fontSize: 30,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    labelMedium: TextStyle().copyWith(
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    labelSmall: TextStyle().copyWith(
      fontSize: 10,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),

    //App Bar title Syle
    titleLarge: TextStyle().copyWith(
      fontSize: 30,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    //
    titleMedium: TextStyle().copyWith(
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    titleSmall: TextStyle().copyWith(
      fontSize: 15,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  );
}
