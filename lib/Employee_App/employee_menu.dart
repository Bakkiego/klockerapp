import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- YOUR APP IMPORTS ---
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/screens/login_screen.dart';
import 'package:klockerapp/screens/help-screens/settings_screen.dart';
import 'package:klockerapp/screens/help-screens/help_screen.dart';

import 'package:klockerapp/screens/company-screens/ticketing_screen.dart';
// 🚀 NEW IMPORT: Employee Expense Screen
import 'package:klockerapp/screens/finance-screen/employee_expense_screen.dart';

// --- EMPLOYEE SCREENS ---
import 'EmployeeAttendanceScreen.dart';
import 'EmployeeLeaveRequestScreen.dart';
import 'EmployeePayslipScreen.dart';
import "EmployeeShiftScreen.dart";

// 🚀 IMPORT THE PROFILE SETTINGS SCREEN (Make sure the path matches where you saved it!)
import 'package:klockerapp/screens/profile_settings_screen.dart';

class EmployeeMenu extends StatelessWidget {
  const EmployeeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- GRAB DATA FROM PROVIDER ---
    final userProvider = context.watch<UserProvider>();
    final currentTier = userProvider.subscriptionTier?.toLowerCase() ?? 'lite';
    final userName = userProvider.fullName ?? 'Staff Member';

    // --- EXACT PLAN MAPPING ---
    // Shifts unlock at Basic and go up
    bool canSeeShifts = [
      'basic',
      'standard',
      'enterprise',
    ].contains(currentTier);

    // Payslips unlock at Basic and go up
    bool canSeePayslips = [
      'basic',
      'standard',
      'enterprise',
    ].contains(currentTier);

    // Leave Requests are reserved for Standard and Enterprise
    bool canRequestLeave = ['standard', 'enterprise'].contains(currentTier);

    // 🚀 Expenses are reserved for Standard and Enterprise
    bool canSubmitExpenses = ['standard', 'enterprise'].contains(currentTier);

    // Ticketing is reserved for Standard and Enterprise
    bool canUseTicketing = ['standard', 'enterprise'].contains(currentTier);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // --- PROFILE CARD ---
          _buildProfileCard(context, userName, "Employee"),

          const SizedBox(height: 30),

          _sectionHeader("My Work"),

          // Everyone gets Attendance
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

          // Gated: Upcoming Shifts
          if (canSeeShifts)
            _menuTile(
              context,
              "My Shifts",
              Icons.calendar_month_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeShiftsScreen(),
                ),
              ),
            ),

          // Gated: Leave Requests
          if (canRequestLeave)
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

          // Gated: Payslips
          if (canSeePayslips)
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

          // 🚀 Gated: My Expenses
          if (canSubmitExpenses)
            _menuTile(
              context,
              "My Expenses",
              Icons.account_balance_wallet_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeExpenseScreen(),
                ),
              ),
            ),

          const SizedBox(height: 25),

          _sectionHeader("Account"),

          // Gated: Helpdesk Tickets
          if (canUseTicketing)
            _menuTile(
              context,
              "Helpdesk Tickets",
              Icons.support_agent,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TicketingScreen(),
                ),
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
          _buildLogoutButton(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- UI Helper Widgets ---

  // UPDATED: Made clickable with the 'EDIT' badge!
  Widget _buildProfileCard(BuildContext context, String name, String role) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileSettingsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF00A36C),
              backgroundImage: context.watch<UserProvider>().avatarUrl != null
                  ? NetworkImage(context.watch<UserProvider>().avatarUrl!)
                  : null,
              child: context.watch<UserProvider>().avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00A36C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "EDIT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
        // 1. CAPTURE THE NAVIGATOR BEFORE DOING ANYTHING ASYNC
        final navigator = Navigator.of(context, rootNavigator: true);

        // 2. Show the loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: CircularProgressIndicator(color: Colors.redAccent),
          ),
        );

        try {
          // 3. Clear local provider data and sign out of Supabase
          context.read<UserProvider>().clear();
          await SupabaseService().signOut();
        } catch (e) {
          debugPrint("Sign out error: $e");
        } finally {
          // 4. USE THE CAPTURED NAVIGATOR to safely pop the spinner and route!
          navigator.pop(); // Destroys the red spinner
          navigator.pushAndRemoveUntil(
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
