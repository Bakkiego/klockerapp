import 'package:flutter/material.dart';
import 'package:klockerapp/utils/themes.dart';
import 'package:klockerapp/screens/login_screen.dart';
import 'package:klockerapp/screens/welcome_screen.dart';
import 'package:klockerapp/screens/home_screen.dart';
import 'package:klockerapp/components/bottom_nav.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: KlockerappTheme.lightTheme,
      darkTheme: KlockerappTheme.darkTheme,

      initialRoute: BottomNav.id,
      routes: {
        WelcomeScreen.id: (context) => WelcomeScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        BottomNav.id: (context) => BottomNav(),
      },
    );
  }
}
