import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 Added for Permissions

import 'social_settings_screen.dart';
import 'profile_settings_screen.dart';
import 'system_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 THE BOUNCER: Check for Master Tenant Settings Permission
    final userProvider = context.watch<UserProvider>();
    final canManageTenant = userProvider.can('manage_tenant_settings');

    // 🚀 If they don't have the key, show the Access Denied screen!
    if (!canManageTenant) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                "Access Denied",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "You need System Admin permissions to edit company settings.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 🚀 If they DO have the key, build the settings tabs normally
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00A36C),
            labelColor: Color(0xFF00A36C),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(child: Text("Profile Settings")),
              Tab(child: Text("System Settings")),
              Tab(child: Text("Social Settings")),
            ],
          ),
        ),
        body: const TabBarView(
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
