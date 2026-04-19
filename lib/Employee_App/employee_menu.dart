import 'package:flutter/material.dart';
import 'package:klockerapp/screens/login_screen.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

// --- ADDED IMPORTS FOR THE NEW SCREENS ---
import 'package:klockerapp/screens/help-screens/settings_screen.dart';
import 'package:klockerapp/screens/help-screens/help_screen.dart';

import 'EmployeeAttendanceScreen.dart';
import 'EmployeeLeaveRequestScreen.dart';
import 'EmployeePayslipScreen.dart';

class EmployeeMenu extends StatelessWidget {
  const EmployeeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // --- PROFILE CARD ---
          _buildProfileCard(context, "Staff Member"),

          const SizedBox(height: 30),

          _sectionHeader("My Work"),
          _menuTile(
            context,
            "My Attendance",
            Icons.history,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmployeeAttendanceScreen(),
              ),
            ),
          ),
          _menuTile(
            context,
            "Leave Requests",
            Icons.beach_access,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LeaveRequestScreen(),
              ),
            ),
          ),
          _menuTile(
            context,
            "Payslips",
            Icons.receipt_long_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmployeePayslipScreen(),
              ),
            ),
          ),

          const SizedBox(height: 25),

          _sectionHeader("Account"),
          _menuTile(
            context,
            "App Settings",
            Icons.settings_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          _menuTile(
            context,
            "Help & Support",
            Icons.help_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            ),
          ),

          const SizedBox(height: 40),

          // --- LOGOUT ---
          _buildLogoutButton(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- UI Helper Widgets (Keeping your exact logic) ---
  Widget _buildProfileCard(BuildContext context, String role) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF00A36C), // Matches your brand green
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daniel Leke",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00A36C)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await SupabaseService().signOut();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text("Logout"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        foregroundColor: Colors.redAccent,
        elevation: 0,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
