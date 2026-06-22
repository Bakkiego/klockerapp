import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 Added for Permissions

import 'components/employee_screen_components/manage_roles.dart';
import 'components/employee_screen_components/view_employee.dart';
import 'components/employee_screen_components/edit_employee.dart';

class Employees extends StatelessWidget {
  const Employees({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 Detect screen size to trigger web layout rules
    final isWeb = MediaQuery.of(context).size.width > 800;

    // 🚀 Bring in the Bouncer
    final userProvider = context.watch<UserProvider>();

    List<Tab> myTabs = [];
    List<Widget> myScreens = [];

    // 1. DIRECTORY: Everyone usually needs to see their coworkers
    myTabs.add(const Tab(text: "Directory"));
    myScreens.add(_buildConstrainedView(const ViewEmployee()));

    // 2. MANAGE EMPLOYEES: Only for HR / Admins
    if (userProvider.can('manage_employees')) {
      myTabs.add(const Tab(text: "Manage & Edit"));
      myScreens.add(_buildConstrainedView(const EditEmployee()));
    }

    // 3. MANAGE ROLES: Only for Business Owners / Top Admins
    if (userProvider.can('manage_roles')) {
      myTabs.add(const Tab(text: "Roles & Access"));
      myScreens.add(_buildConstrainedView(const ManageRolesScreen()));
    }

    return DefaultTabController(
      length: myTabs.length, // 🚀 Dynamically sizes based on permissions
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Employee Directory',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            tabAlignment: isWeb ? TabAlignment.center : TabAlignment.fill,
            isScrollable: isWeb,
            indicatorColor: const Color(0xFF00A36C),
            labelColor: const Color(0xFF00A36C),
            unselectedLabelColor: Colors.grey,
            tabs: myTabs, // 🚀 Inject allowed tabs
          ),
        ),
        body: TabBarView(
          children: myScreens, // 🚀 Inject allowed screens
        ),
      ),
    );
  }

  // 🚀 Helper to lock the width of the pages so they don't stretch forever
  Widget _buildConstrainedView(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1000,
        ), // Perfect desktop reading width
        child: child,
      ),
    );
  }
}
