import 'package:flutter/material.dart';
import 'package:klockerapp/utils/custom_theme/text_theme.dart';

class KAppBarTheme {
  KAppBarTheme._();

  static AppBarTheme lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: Colors.lightGreenAccent, size: 25),
    titleTextStyle: KAppTextTheme.lightTextTheme.titleLarge,
  );
  static AppBarTheme darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.black,
    surfaceTintColor: Colors.black,
    iconTheme: IconThemeData(color: Colors.lightGreenAccent, size: 25),
    titleTextStyle: KAppTextTheme.darkTextTheme.titleLarge,
  );
}
