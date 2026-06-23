import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/screens/finance-screen/employee_expense_screen.dart';
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
import '../models/app_enums.dart';
import '../supabase/repo/supabase_service.dart';
import 'company-screens/appraisal_screen.dart';
import 'company-screens/components/assets_management_screen.dart';
import 'company-screens/payslip_screen.dart';
import 'company-screens/performance_screen.dart';
import 'company-screens/salary_screen.dart';
import 'package:klockerapp/screens/employee-screens/employees.dart';
import 'package:klockerapp/screens/finance-screen/accounts_list_screen.dart';
import 'package:klockerapp/screens/finance-screen/deposit_screen.dart';
import 'package:klockerapp/screens/finance-screen/expense_screen.dart';
import 'package:klockerapp/screens/finance-screen/payee_screen.dart';
import 'package:klockerapp/screens/finance-screen/payers_screen.dart';
import 'package:klockerapp/screens/finance-screen/transfer_balance_screen.dart';
import 'package:klockerapp/screens/company-screens/company_screen.dart';
import 'package:klockerapp/screens/company-screens/training_screen.dart';
import 'package:klockerapp/screens/finance-screen/report_screen.dart';
import 'package:klockerapp/screens/help-screens/settings_screen.dart';
import 'package:klockerapp/screens/help-screens/help_screen.dart';
import 'company-screens/ticketing_screen.dart';
import 'package:klockerapp/screens/profile_settings_screen.dart';
import 'zoom_meetings_screen.dart';
import 'login_screen.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final userName = userProvider.fullName ?? 'Loading...';
    final bool isWeb = MediaQuery.of(context).size.width > 800;

    // 🚀 1. PARSE THE SUBSCRIPTION TIER
    // We convert the string to a number so it's easy to say "If Tier >= 3"
    final currentTierStr =
        userProvider.subscriptionTier?.toLowerCase() ?? 'lite';
    int tierLevel = 1; // Default to Lite
    if (currentTierStr == 'basic') tierLevel = 2;
    if (currentTierStr == 'standard') tierLevel = 3;
    if (currentTierStr == 'premium') tierLevel = 4;

    // 🚀 2. DYNAMIC HRM LIST
    List<MenuExpansionOBJ> hrmList = [];

    // HR Actions & Compliance (BASIC TIER AND UP)
    if (tierLevel >= 2) {
      if (userProvider.can('manage_awards')) {
        hrmList.add(
          MenuExpansionOBJ(
            title: 'Awards',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AwardsScreen()),
            ),
          ),
        );
      }
      if (userProvider.can('manage_offboarding')) {
        hrmList.add(
          MenuExpansionOBJ(
            title: 'Termination',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TerminationScreen(),
              ),
            ),
          ),
        );
        hrmList.add(
          MenuExpansionOBJ(
            title: 'Resignation',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ResignationScreen(),
              ),
            ),
          ),
        );
      }
      if (userProvider.can('manage_transfers')) {
        hrmList.add(
          MenuExpansionOBJ(
            title: 'Transfer',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransferScreen()),
            ),
          ),
        );
      }
      if (userProvider.can('manage_warnings')) {
        hrmList.add(
          MenuExpansionOBJ(
            title: 'Warning',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WarningScreen()),
            ),
          ),
        );
      }
      if (userProvider.can('manage_announcements')) {
        hrmList.add(
          MenuExpansionOBJ(
            title: 'Announcements',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AnnouncementsScreen(),
              ),
            ),
          ),
        );
      }
      if (userProvider.can('manage_promotions')) {
        hrmList.add(
          MenuExpansionOBJ(
            title: 'Promotion',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PromotionScreen()),
            ),
          ),
        );
      }
    }

    // 🚀 3. DYNAMIC FINANCE LIST
    List<MenuExpansionOBJ> financeList = [];

    // Payroll Automation (BASIC TIER AND UP)
    if (tierLevel >= 2) {
      if (userProvider.can('view_financials') ||
          userProvider.can('manage_salary_configs')) {
        financeList.add(
          MenuExpansionOBJ(
            title: "Salary & Payroll",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalaryScreen()),
            ),
          ),
        );
        financeList.add(
          MenuExpansionOBJ(
            title: "Payslips",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PayslipScreen()),
            ),
          ),
        );
      }
    }

    // Finance Management (PREMIUM TIER ONLY)
    if (tierLevel >= 4) {
      if (userProvider.can('manage_expenses')) {
        financeList.add(
          MenuExpansionOBJ(
            title: 'Employee Expenses',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmployeeExpenseScreen(),
              ),
            ),
          ),
        );
        financeList.add(
          MenuExpansionOBJ(
            title: 'Expense',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpenseScreen()),
            ),
          ),
        );
      }
      if (userProvider.can('manage_ledgers')) {
        financeList.add(
          MenuExpansionOBJ(
            title: 'Accounts List',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountsListScreen(),
              ),
            ),
          ),
        );
        financeList.add(
          MenuExpansionOBJ(
            title: 'Payee',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PayeeScreen()),
            ),
          ),
        );
        financeList.add(
          MenuExpansionOBJ(
            title: 'Payers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PayersScreen()),
            ),
          ),
        );
        financeList.add(
          MenuExpansionOBJ(
            title: 'Deposit',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DepositScreen()),
            ),
          ),
        );
        financeList.add(
          MenuExpansionOBJ(
            title: 'Transfer Balance',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageTransferScreen(),
              ),
            ),
          ),
        );
      }
    }

    // 🚀 4. DYNAMIC COMPANY LIST
    List<MenuExpansionOBJ> companyList = [];

    // Core setup, available to everyone who has permission
    if (userProvider.can('manage_branches') ||
        userProvider.can('manage_departments')) {
      companyList.add(
        MenuExpansionOBJ(
          title: 'Branch & Departments',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CompanyScreen()),
          ),
        ),
      );
    }

    // Performance & Training (STANDARD TIER AND UP)
    if (tierLevel >= 3) {
      if (userProvider.can('manage_performance')) {
        companyList.add(
          MenuExpansionOBJ(
            title: "Performance",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PerformanceScreen(),
              ),
            ),
          ),
        );
        companyList.add(
          MenuExpansionOBJ(
            title: "Appraisal",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppraisalScreen()),
            ),
          ),
        );
      }
      if (userProvider.can('manage_tickets') ||
          userProvider.can('view_company_tickets')) {
        companyList.add(
          MenuExpansionOBJ(
            title: "Ticketing",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TicketingScreen()),
            ),
          ),
        );
      }
      if (userProvider.can('manage_training')) {
        companyList.add(
          MenuExpansionOBJ(
            title: "Training Designator",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TrainingDesignatorScreen(),
              ),
            ),
          ),
        );
      }
    }

    // Asset Management (PREMIUM TIER ONLY)
    if (tierLevel >= 4) {
      if (userProvider.can('manage_assets')) {
        companyList.add(
          MenuExpansionOBJ(
            title: "Asset Management",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AssetManagementScreen(),
              ),
            ),
          ),
        );
      }
    }

    Widget menuContentList = ListView(
      shrinkWrap: true,
      physics: isWeb
          ? const ClampingScrollPhysics()
          : const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 12 : 20,
        vertical: isWeb ? 12 : 20,
      ),
      children: [
        _buildAdminProfileCard(context, userName, isWeb),
        SizedBox(height: isWeb ? 20 : 30),

        _sectionHeader("Employee Management", isWeb),
        // Everyone inherently gets these two
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

        // Only render the ExpansionTiles if the lists actually have items inside them!
        if (hrmList.isNotEmpty)
          MenuExpansionTile(hrmList, "HRM", Icons.perm_contact_calendar),
        SizedBox(height: isWeb ? 16 : 30),

        if (financeList.isNotEmpty || companyList.isNotEmpty)
          _sectionHeader("Finances & Company", isWeb),
        if (financeList.isNotEmpty)
          MenuExpansionTile(financeList, "Finance", Icons.monetization_on),
        if (companyList.isNotEmpty)
          MenuExpansionTile(companyList, "Company", Icons.business),

        // System Settings
        SizedBox(height: isWeb ? 16 : 30),
        _sectionHeader("System", isWeb),

        if (userProvider.can('manage_tenant_settings'))
          MenuItemDesign(
            'Company Settings',
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

        SizedBox(height: isWeb ? 24 : 40),
        _buildLogoutButton(context, isWeb),
        const SizedBox(height: 50),
      ],
    );

    // 🚀 THE FAILSAFE: If they have absolutely zero permissions
    if (hrmList.isEmpty &&
        financeList.isEmpty &&
        companyList.isEmpty &&
        !userProvider.can('manage_tenant_settings')) {
      Widget failsafeContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 80,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                "Setup Incomplete",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your Admin account has been created, but HR has not assigned your module permissions yet. Please contact your manager to get your access keys.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 40),
              _buildLogoutButton(context, isWeb),
            ],
          ),
        ),
      );

      // Return it safely wrapped in your app's background and safe areas
      if (isWeb) return SafeArea(child: failsafeContent);
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(child: failsafeContent),
      );
    }

    if (isWeb) return SafeArea(child: menuContentList);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: menuContentList),
    );
  }

  Widget _buildAdminProfileCard(BuildContext context, String name, bool isWeb) {
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
        padding: EdgeInsets.all(isWeb ? 12 : 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12), // Tighter radius for web
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: isWeb ? 18 : 30, // 🚀 Smaller Avatar on Web
              backgroundColor: const Color(0xFF00A36C),
              backgroundImage: context.watch<UserProvider>().avatarUrl != null
                  ? NetworkImage(context.watch<UserProvider>().avatarUrl!)
                  : null,
              child: context.watch<UserProvider>().avatarUrl == null
                  ? Icon(
                      Icons.person,
                      color: Colors.white,
                      size: isWeb ? 20 : 30,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 13 : 18,
                    ), // 🚀 Smaller Name
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "HR Administrator",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: isWeb ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00A36C),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "EDIT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWeb ? 8 : 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isWeb) {
    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 8 : 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: isWeb ? 10 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ), // 🚀 Smaller Header
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isWeb) {
    return ElevatedButton.icon(
      onPressed: () async {
        final navigator = Navigator.of(context, rootNavigator: true);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: CircularProgressIndicator(color: Colors.redAccent),
          ),
        );

        try {
          context.read<UserProvider>().clear();
          await SupabaseService().signOut();
        } catch (e) {
          debugPrint("Sign out error: $e");
        } finally {
          navigator.pop();
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      icon: Icon(Icons.logout, size: isWeb ? 16 : 18),
      label: Text(
        "Logout",
        style: TextStyle(fontSize: isWeb ? 13 : 14),
      ), // 🚀 Smaller Logout Text
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.08),
        foregroundColor: Colors.redAccent,
        elevation: 0,
        minimumSize: Size(
          double.infinity,
          isWeb ? 40 : 50,
        ), // 🚀 Thinner button on web
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
