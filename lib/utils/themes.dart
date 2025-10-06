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
  );
}
