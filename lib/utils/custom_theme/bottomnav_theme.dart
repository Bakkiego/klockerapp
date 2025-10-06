import 'package:flutter/material.dart';
import 'package:klockerapp/utils/custom_theme/text_theme.dart';

class KBottomNavTheme {
  KBottomNavTheme._();

  static BottomNavigationBarThemeData lightBottomNavTheme =
      BottomNavigationBarThemeData(
        selectedItemColor: Colors.lightGreenAccent,
        selectedLabelStyle: KAppTextTheme.lightTextTheme.labelSmall,
        unselectedItemColor: Colors.black,
        unselectedLabelStyle: KAppTextTheme.lightTextTheme.labelSmall,
      );
  static BottomNavigationBarThemeData darkBottomNavTheme =
      BottomNavigationBarThemeData(
        selectedItemColor: Colors.lightGreenAccent,
        selectedLabelStyle: KAppTextTheme.darkTextTheme.labelSmall,
        unselectedItemColor: Colors.white,
        unselectedLabelStyle: KAppTextTheme.darkTextTheme.labelSmall,
      );
}
