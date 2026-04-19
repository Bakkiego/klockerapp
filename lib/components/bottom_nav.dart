import 'package:flutter/material.dart';
import 'package:klockerapp/screens/inbox.dart';
import 'package:klockerapp/screens/calendar.dart';
import 'package:klockerapp/screens/menu.dart';
import 'package:klockerapp/screens/home_screen.dart';
import 'package:klockerapp/models/app_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Employee_App/EmployeeHomeScreen.dart';
import '../Employee_App/employee_menu.dart'; // Import your enum file

class BottomNav extends StatefulWidget {
  final userRole role; // This captures the role from Login/AuthGate

  const BottomNav({super.key, required this.role});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  String? userrole;
  // We define the screens in a getter or initState so we can check the role

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role') // Assuming you have a 'role' column
          .eq('id', user.id)
          .single();

      setState(() {
        userrole = data['role'];
      });
    }
  }

  Widget _getMenuScreen() {
    if (widget.role == userRole.Employee) {
      return const EmployeeMenu(); // Shows the simplified menu
    } else {
      return const Menu(); // Shows the HR/Manager menu
    }
  }

  List<Widget> get _screens => [
    // Position 0: Home
    widget.role == userRole.Employee ? EmployeeHomeScreen() : HomeScreen(),

    const Inbox(), // Position 1
    const Calendar(), // Position 2
    // Position 3: Dynamic Menu
    _getMenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // 2. IndexedStack keeps all screens "alive" in the background
        // so they don't reset every time you tap a tab.
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00A36C),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_rounded),
            label: "Inbox",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            label: "More",
          ),
        ],
      ),
    );
  }
}
