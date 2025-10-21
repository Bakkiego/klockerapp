import 'package:flutter/material.dart';
import 'package:klockerapp/components/bottom_nav.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_summary.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  static String id = 'home_screen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          SearchBar(
            hintText: 'Type Feature',
            trailing: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.search_sharp),
              ),
            ],
          ),
          AttendanceSummary(),
          Divider(height: 2, color: Colors.grey, indent: 20, endIndent: 20),
          Expanded(
            child: CalendarDatePicker(
              initialDate: DateTime(2025, 2, 8),
              firstDate: DateTime(2025),
              lastDate: DateTime(2026),
              onDateChanged: (DateTime pickedDate) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
