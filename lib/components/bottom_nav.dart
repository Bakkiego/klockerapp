import 'package:flutter/material.dart';
import 'package:klockerapp/screens/inbox_list.dart';
import 'package:klockerapp/screens/calendar.dart';
import 'package:klockerapp/screens/menu.dart';
import 'package:klockerapp/screens/home_screen.dart';
import 'package:klockerapp/models/app_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Employee_App/EmployeeHomeScreen.dart';
import '../Employee_App/employee_menu.dart';

import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';

class BottomNav extends StatefulWidget {
  final userRole role;

  const BottomNav({super.key, required this.role});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  String? userrole;

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
          .select('role')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          userrole = data['role'];
        });
      }
    }
  }

  Widget _getMenuScreen() {
    if (widget.role == userRole.Employee) {
      return const EmployeeMenu();
    } else {
      return const Menu();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTier =
        context.watch<UserProvider>().subscriptionTier?.toLowerCase() ?? 'lite';
    bool canSeeSchedule = currentTier != 'lite';

    // 🚀 core screens map
    List<Widget> screens = [
      widget.role == userRole.Employee
          ? const EmployeeHomeScreen()
          : const HomeScreen(),
      const InboxList(),
      if (canSeeSchedule) const Calendar(),
      _getMenuScreen(), // Used natively by mobile layout shell
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    // ==========================================
    // 💻 UNIFIED DESKTOP WORKSPACE LAYOUT (Slack/ClickUp Style)
    // ==========================================
    if (isWeb) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🚀 PERMANENT SIDEBAR COLUMN
              Container(
                width: 280, // Clean, optimized sidebar width
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.2),
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Unified Main Top Navigation Rows
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 24,
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Column(
                        children: [
                          _buildWebSidebarTab(
                            icon: Icons.home_rounded,
                            label: "Home Dashboard",
                            isSelected: _selectedIndex == 0,
                            onTap: () => setState(() => _selectedIndex = 0),
                          ),
                          const SizedBox(height: 4),
                          _buildWebSidebarTab(
                            icon: Icons.mail_rounded,
                            label: "Inbox",
                            isSelected: _selectedIndex == 1,
                            onTap: () => setState(() => _selectedIndex = 1),
                          ),
                          if (canSeeSchedule) ...[
                            const SizedBox(height: 4),
                            _buildWebSidebarTab(
                              icon: Icons.calendar_month_rounded,
                              label: "Events",
                              isSelected: _selectedIndex == 2,
                              onTap: () => setState(() => _selectedIndex = 2),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(height: 20),
                    ),

                    // The rest of your feature list layout runs down cleanly here!
                    Expanded(child: _getMenuScreen()),
                  ],
                ),
              ),

              // 🚀 DYNAMIC CONTENT WINDOW (Takes up the rest of the display)
              Expanded(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: IndexedStack(
                    index: _selectedIndex >= screens.length
                        ? 0
                        : _selectedIndex,
                    children: screens,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================
    // 📱 MOBILE LAYOUT (Classic Bottom Bar - Unchanged)
    // ==========================================
    List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: "Home",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.mail_rounded),
        label: "Inbox",
      ),
      if (canSeeSchedule)
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: "Schedule",
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu_rounded),
        label: "More",
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex >= screens.length ? 0 : _selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00A36C),
        unselectedItemColor: Colors.grey,
        items: navItems,
      ),
    );
  }

  // Helper builder for custom web navigation items
  Widget _buildWebSidebarTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00A36C).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF00A36C)
                  : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00A36C)
                    : Colors.grey.shade300,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
