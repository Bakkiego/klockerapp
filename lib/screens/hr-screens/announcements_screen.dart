import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/k_text_input_field.dart';
import '../employee-screens/components/employee_screen_components/data_collector_list.dart';
import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final DataCollectorList dataCollectorList = DataCollectorList();
  DateTime _selectedDate = DateTime.now();

  // --- This is the function that will handle the date picking ---
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        // Use a controller to update the TextField's text
        dataCollectorList.dateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Announcements')),
      body: Column(
        children: [
          KTextInputField(
            labelText: "Announcement",
            hintText: "Enter Transfer Employee Branch",
            icon: Icons.business,
          ),
          TextField(
            // Use a controller to display the date
            decoration: const InputDecoration(
              labelText: "Start Date",
              prefixIcon: Icon(Icons.date_range),
            ),
            readOnly: true,
            onTap: _selectDate,
            controller: dataCollectorList
                .dateController, // Use the function passed from the outside
          ),
          TextField(
            // Use a controller to display the date
            decoration: const InputDecoration(
              labelText: "End Date",
              prefixIcon: Icon(Icons.date_range),
            ),
            readOnly: true,
            onTap: _selectDate,
            controller: dataCollectorList
                .dateController, // Use the function passed from the outside
          ),
        ],
      ),
    );
  }
}
