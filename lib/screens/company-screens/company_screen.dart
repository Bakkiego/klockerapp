import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 Added for Permissions

import '../company-screens/department_screen.dart';
import '../company-screens/branch_screen.dart';

class CompanyScreen extends StatelessWidget {
  const CompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 THE BOUNCER: Check their exact keys
    final userProvider = context.watch<UserProvider>();
    final canManageBranches = userProvider.can('manage_branches');
    final canManageDepartments = userProvider.can('manage_departments');

    List<Tab> myTabs = [];
    List<Widget> myScreens = [];

    // 🚀 DYNAMIC TAB 1: Branches
    if (canManageBranches) {
      myTabs.add(const Tab(text: "Branches"));
      myScreens.add(const BranchScreen());
    }

    // 🚀 DYNAMIC TAB 2: Departments
    if (canManageDepartments) {
      myTabs.add(const Tab(text: "Departments"));
      myScreens.add(const DepartmentScreen());
    }

    // Fallback: If they somehow bypass the menu with zero keys
    if (myTabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Company Setup',
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
                "You do not have permission to view this section.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: myTabs
          .length, // 🚀 Automatically sizes based on how many keys they have
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Company Setup',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF00A36C),
            labelColor: const Color(0xFF00A36C),
            unselectedLabelColor: Colors.grey,
            tabs: myTabs, // 🚀 Only loads the tabs they are allowed to see
          ),
        ),
        body: TabBarView(
          children:
              myScreens, // 🚀 Only loads the screens they are allowed to see
        ),
      ),
    );
  }
}
