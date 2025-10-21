import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/utils/date_picker_util.dart';

class CustomDatePicker extends StatefulWidget {
  const CustomDatePicker({super.key});

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Use an InkWell to make a non-button widget tappable
    return InkWell(
      onTap: () async {
        // Call the reusable service to get a new date
        final DateTime? pickedDate = await selectDate(context, _selectedDate);

        // If a date was picked, update the state to rebuild the widget
        if (pickedDate != null && pickedDate != _selectedDate) {
          setState(() {
            _selectedDate = pickedDate;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Keep the row compact
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20.0),
            const SizedBox(width: 8.0),
            // Format the date like in the picture "Wed, 07 Aug"
            Text(
              DateFormat('E, dd MMM').format(_selectedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4.0),
            const Icon(Icons.arrow_drop_down, size: 24.0),
          ],
        ),
      ),
    );
  }
}
