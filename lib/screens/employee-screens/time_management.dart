import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';

// Import your screens here
import 'components/time_management_components/rooster_screen.dart';
import 'components/time_management_components/attendance_screen.dart';
import 'components/time_management_components/leave_screen.dart';

class TimeManagement extends StatelessWidget {
  const TimeManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isWeb = MediaQuery.of(context).size.width > 800;

    List<Tab> myTabs = [];
    List<Widget> myScreens = [];

    // 🚀 CHECK PERMISSIONS BEFORE ADDING TABS
    if (userProvider.can('view_company_rosters') ||
        userProvider.can('manage_rosters')) {
      myTabs.add(const Tab(text: "Rosters"));
      myScreens.add(const RoosterScreen());
    }

    if (userProvider.can('view_company_attendance') ||
        userProvider.can('manage_attendance')) {
      myTabs.add(const Tab(text: "Live Attendance"));
      myScreens.add(const AttendanceScreen());
    }

    if (userProvider.can('manage_leave_requests')) {
      myTabs.add(const Tab(text: "Approve Leave"));
      myScreens.add(const LeaveScreen());
    }

    // 🚀 THE FIX: If they have NO permissions, show an empty state instead of crashing
    // 🚀 THE FIX: If they have NO permissions, show an empty state instead of crashing
    if (myTabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Time Management',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
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
                "You do not have permission to view manager time tools.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // 🚀 DEBUG LINES: Let's see what Flutter thinks is happening!
              Text(
                "DEBUG INFO:",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Legacy Role: ${userProvider.role}",
                style: TextStyle(color: Colors.redAccent),
              ),
              Text(
                "Permissions Found: ${userProvider.permissions.length}",
                style: TextStyle(color: Colors.redAccent),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "List: ${userProvider.permissions.join(', ')}",
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If they have at least 1 tab, render the standard TabController
    return DefaultTabController(
      length: myTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Time Management',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            tabAlignment: isWeb ? TabAlignment.center : TabAlignment.fill,
            isScrollable: isWeb,
            indicatorColor: const Color(0xFF00A36C),
            labelColor: const Color(0xFF00A36C),
            unselectedLabelColor: Colors.grey,
            tabs: myTabs,
          ),
        ),
        body: TabBarView(children: myScreens),
      ),
    );
  }
}
