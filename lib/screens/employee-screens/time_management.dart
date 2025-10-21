import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/rooster_screen.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_screen.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/leave_screen.dart';

class TimeManagement extends StatefulWidget {
  const TimeManagement({super.key});

  @override
  State<TimeManagement> createState() => _TimeManagementState();
}

class _TimeManagementState extends State<TimeManagement> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Time Management'),
          bottom: const TabBar(
            tabs: [
              Tab(child: Text("Attendance")),
              Tab(child: Text("Rooster")),
              Tab(child: Text("Leave")),
            ],
          ),
        ),
        body: TabBarView(
          children: [AttendanceScreen(), RoosterScreen(), LeaveScreen()],
        ),
      ),
    );
  }
}
