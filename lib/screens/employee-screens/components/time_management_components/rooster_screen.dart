import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/assign_screen.dart';
import 'manage_shifts_screen.dart';

class ShiftDisplayClass {
  final String shiftName;
  final String time;
  final int assigneeCount;
  final Color accentColor;

  // Added a default value to accentColor to prevent 'Null' errors
  ShiftDisplayClass(
    this.shiftName,
    this.time,
    this.assigneeCount, [
    this.accentColor = Colors.green,
  ]);
}

class RoosterScreen extends StatefulWidget {
  const RoosterScreen({super.key});

  @override
  State<RoosterScreen> createState() => _RoosterScreenState();
}

class _RoosterScreenState extends State<RoosterScreen> {
  List<ShiftDisplayClass> shifts = [
    ShiftDisplayClass("Morning Shift", "08:00 - 12:00", 5, Colors.blue),
    ShiftDisplayClass("Afternoon Shift", "12:00 - 16:00", 3, Colors.orange),
    ShiftDisplayClass("Evening Shift", "16:00 - 20:00", 2, Colors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP DATE PICKER
            Container(
              height: 110, // Added explicit height to prevent 1px overflow
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DatePicker(
                DateTime.now(),
                initialSelectedDate: DateTime.now(),
                onDateChange: (date) => setState(() {}),
                selectionColor: const Color(0xFF00A36C),
                selectedTextColor: Colors.white,
                dayTextStyle: TextStyle(color: Colors.grey, fontSize: 12),
                dateTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 2. ACTION BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _quickAction(context, "Assign", Icons.person_add_alt_1, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssignScreen(),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  _quickAction(
                    context,
                    "Settings",
                    Icons.settings_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageShiftsScreen(),
                        ),
                      );
                    },
                    isSecondary: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. SHIFT TIMELINE
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: shifts.length,
                itemBuilder: (context, index) {
                  return _shiftTimelineItem(
                    shifts[index],
                    index == shifts.length - 1,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isSecondary = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSecondary ? Colors.transparent : const Color(0xFF00A36C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00A36C)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSecondary ? const Color(0xFF00A36C) : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSecondary ? const Color(0xFF00A36C) : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shiftTimelineItem(ShiftDisplayClass shift, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              shift.time.split(" ")[0],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Container(
              width: 2,
              height: 80,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: isLast ? Colors.transparent : Colors.grey.withOpacity(0.3),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                ),
              ],
              border: Border(
                left: BorderSide(
                  // Added safe check for accentColor
                  color: shift.accentColor ?? Colors.green,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.shiftName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${shift.assigneeCount} Employees Assigned",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
