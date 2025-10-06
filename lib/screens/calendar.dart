import 'package:flutter/material.dart';

class Calendar extends StatelessWidget {
  const Calendar({super.key});

  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker(
      initialDate: DateTime(2025, 2, 8),
      firstDate: DateTime(2025),
      lastDate: DateTime(2026),
      onDateChanged: (DateTime pickedDate) {},
    );
  }
}
