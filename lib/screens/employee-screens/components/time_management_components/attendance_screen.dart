import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_specifics.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_summary.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/custom_date_picker.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDatePicker(),
            AttendanceSummary(),
            Text("Attendance"),
            AttendanceSpecifics(),
          ],
        ),
      ),
    );
  }
}
