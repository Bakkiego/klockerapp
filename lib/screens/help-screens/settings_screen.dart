import 'package:flutter/material.dart';
import 'social_settings_screen.dart';
import 'profile_settings_screen.dart';
import 'system_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(child: Text("Profile Settings")),
              Tab(child: Text("System Settings")),
              Tab(child: Text("Social Settings")),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProfileSettingsScreen(),
            SystemSettingsScreen(),
            SocialSettingsScreen(),
          ],
        ),
      ),
    );
  }
}
