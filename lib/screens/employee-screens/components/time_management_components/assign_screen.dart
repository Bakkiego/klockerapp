import 'package:flutter/material.dart';
import '../time_management_components/utils/multi_select_calendar.dart';

class AssignScreen extends StatefulWidget {
  const AssignScreen({super.key});

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  // State to hold the dates selected via the custom calendar for bulk actions
  List<DateTime> _bulkAssignmentDates = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Shift Assignment')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informational message
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Long-Press a day below to start Multi-Select Mode for bulk assignment.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),

            // CUSTOM MULTI-SELECT CALENDAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MultiSelectCalendar(
                  initialSelectedDates: _bulkAssignmentDates,
                  highlightColor: Colors.lightGreen,
                  onDatesChanged: (newDates) {
                    // This callback runs every time the selection changes in the calendar
                    setState(() {
                      _bulkAssignmentDates = newDates;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
