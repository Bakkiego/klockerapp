import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/assign_screen.dart';

import 'manage_shifts_screen.dart';

class ShiftDisplayClass {
  final String shiftName;
  final String time;
  final int assigneeCount;

  ShiftDisplayClass(this.shiftName, this.time, this.assigneeCount);
}

class RoosterScreen extends StatefulWidget {
  const RoosterScreen({super.key});

  @override
  State<RoosterScreen> createState() => _RoosterScreenState();
}

class _RoosterScreenState extends State<RoosterScreen> {
  List<ShiftDisplayClass> shifts = [
    ShiftDisplayClass("Morning Shift", "08:00 - 12:00", 5),
    ShiftDisplayClass("Afternoon Shift", "12:00 - 16:00", 3),
    ShiftDisplayClass("Evening Shift", "16:00 - 20:00", 2),
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: DatePicker(
              DateTime.now(),
              initialSelectedDate: DateTime.now(),
              onDateChange: (date) {
                // New date selected, update your shifts here
                setState(() {});
              },
              daysCount: 30,
              selectionColor: Colors.green, // Your accent color
              dayTextStyle: const TextStyle(fontSize: 18, color: Colors.green),
              monthTextStyle: const TextStyle(fontSize: 12),
              dateTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssignScreen(),
                      ),
                    );
                  },
                  child: Text('Assign Shifts', style: TextStyle(fontSize: 20)),
                ),
                const Spacer(), // This pushes the next button to the far end
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageShiftsScreen(),
                      ),
                    );
                  },
                  child: Text('Manage Shifts', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                return _shiftBuilder(shifts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _shiftBuilder(ShiftDisplayClass shift) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              shift.time,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            shift.shiftName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("Assignee"),
                        ],
                      ),
                    ),
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: Center(
                        child: Text(shift.assigneeCount.toString()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
