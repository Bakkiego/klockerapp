import 'package:flutter/material.dart';
import 'package:klockerapp/components/menu_item_design.dart';
import 'package:klockerapp/components/menu_expansion_tile.dart';
import 'package:klockerapp/screens/employee-screens/time_management.dart';
import 'package:klockerapp/screens/hr-screens/announcements_screen.dart';
import 'package:klockerapp/screens/hr-screens/awards_screen.dart';
import 'package:klockerapp/screens/hr-screens/promotion_screen.dart';
import 'package:klockerapp/screens/hr-screens/resignation_screen.dart';
import 'package:klockerapp/screens/hr-screens/termination_screen.dart';
import 'package:klockerapp/screens/hr-screens/transfer_screen.dart';
import 'package:klockerapp/screens/hr-screens/warning_screen.dart';
import '../supabase/repo/supabase_service.dart';
import 'company-screens/payslip_screen.dart';
import 'company-screens/salary_screen.dart';
import 'package:klockerapp/screens/employee-screens/employees.dart';
import 'package:klockerapp/screens/finance-screen/accounts_list_screen.dart';
import 'package:klockerapp/screens/finance-screen/deposit_screen.dart';
import 'package:klockerapp/screens/finance-screen/expense_screen.dart';
import 'package:klockerapp/screens/finance-screen/payee_screen.dart';
import 'package:klockerapp/screens/finance-screen/payers_screen.dart';
import 'package:klockerapp/screens/finance-screen/transfer_balance_screen.dart';
import 'package:klockerapp/screens/company-screens/company_screen.dart';
import 'package:klockerapp/screens/finance-screen/report_screen.dart';
import 'package:klockerapp/screens/help-screens/settings_screen.dart';
import 'package:klockerapp/screens/help-screens/help_screen.dart';
import 'login_screen.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 1. HR LIST WITH ACTUAL NAVIGATION ---
    List<MenuExpansionOBJ> hrmList = [
      MenuExpansionOBJ(
        title: 'Awards',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AwardsScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Termination',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TerminationScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Transfer',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransferScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Warning',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WarningScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Announcements',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Promotion',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PromotionScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Resignation',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResignationScreen()),
        ),
      ),
    ];

    // --- 2. FINANCE LIST WITH ACTUAL NAVIGATION ---
    List<MenuExpansionOBJ> financeList = [
      MenuExpansionOBJ(
        title: 'Accounts List',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountsListScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Payee',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PayeeScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Payers',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PayersScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Deposit',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DepositScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Expense',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpenseScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: 'Transfer Balance',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManageTransferScreen()),
        ),
      ),
    ];

    // --- 3. COMPANY LIST WITH ACTUAL NAVIGATION ---
    List<MenuExpansionOBJ> companyList = [
      MenuExpansionOBJ(
        title: 'Branch & Departments',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CompanyScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: "Salary",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SalaryScreen()),
        ),
      ),
      MenuExpansionOBJ(
        title: "Payslip",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PayslipScreen()),
        ),
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          _buildAdminProfileCard(context),
          const SizedBox(height: 30),

          _sectionHeader("Employee Management"),
          MenuItemDesign(
            'Employee Directory',
            Icons.person,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Employees()),
            ),
          ),
          MenuItemDesign(
            'Time Management',
            Icons.timer,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TimeManagement()),
            ),
          ),
          MenuExpansionTile(hrmList, "HRM", Icons.perm_contact_calendar),

          const SizedBox(height: 30),

          _sectionHeader("Finances & Company"),
          MenuExpansionTile(financeList, "Finance", Icons.monetization_on),
          MenuExpansionTile(companyList, "Company", Icons.business),
          MenuItemDesign(
            'Reports',
            Icons.auto_graph_rounded,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportScreen()),
            ),
          ),

          const SizedBox(height: 30),

          _sectionHeader("System"),
          MenuItemDesign(
            'Support',
            Icons.settings_suggest_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          MenuItemDesign(
            'Help Center',
            Icons.help_outline_rounded,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            ),
          ),

          const SizedBox(height: 40),
          _buildLogoutButton(context),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- Helper Widgets remain the same ---
  Widget _buildAdminProfileCard(BuildContext context) {
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
            backgroundColor: Color(0xFF00A36C),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daniel Leke",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  "HR Administrator",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
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
              "ADMIN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
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
