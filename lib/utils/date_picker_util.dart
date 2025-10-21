import 'package:flutter/material.dart';

/// Shows a date picker dialog starting with the current date.
////// Returns the selected [DateTime], or null if the user cancels.
Future<DateTime?> selectDate(BuildContext context, DateTime initialDate) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000), // The earliest selectable date
    lastDate: DateTime(2100), // The latest selectable date
  );
  return pickedDate;
}
