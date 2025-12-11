import 'package:flutter/material.dart';
import 'package:klockerapp/utils/custom_theme/text_theme.dart';

class KAppBarTheme {
  KAppBarTheme._();

  static AppBarTheme lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.lightGreenAccent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: Colors.lightGreenAccent, size: 25),
    titleTextStyle: KAppTextTheme.lightTextTheme.titleLarge,
    // --- ADDED: Rounded Corners ---
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(16.0),
        bottomRight: Radius.circular(16.0),
      ),
    ),
  );

  static AppBarTheme darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.black,
    surfaceTintColor: Colors.black,
    iconTheme: IconThemeData(color: Colors.lightGreenAccent, size: 25),
    titleTextStyle: KAppTextTheme.darkTextTheme.titleLarge,
    // --- ADDED: Rounded Corners ---
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(16.0),
        bottomRight: Radius.circular(16.0),
      ),
    ),
  );
}
