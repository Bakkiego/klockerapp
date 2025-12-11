// file: lib/screens/employee-screens/components/employee_screen_components/edit_employee_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Assuming this import contains the logic for the tiles
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/data_collector_list.dart';

class EditEmployeeDetailsScreen extends StatefulWidget {
  const EditEmployeeDetailsScreen({super.key});

  @override
  State<EditEmployeeDetailsScreen> createState() => _EditEmployeeDetailScreen();
}

class _EditEmployeeDetailScreen extends State<EditEmployeeDetailsScreen> {
  final DataCollectorList dataCollectorList = DataCollectorList();
  DateTime _selectedDate = DateTime.now();

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
        dataCollectorList.dateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 FIX: Wrap the entire screen content in a Scaffold
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Employee Details')),
      body: Form(
        key: dataCollectorList.formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Assuming these lists contain the ExpansionTile(s)
                ...dataCollectorList.personalTileBody,
                const SizedBox(height: 16),
                ...dataCollectorList.getCompanyTileBody(onDateTap: _selectDate),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (dataCollectorList.formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Processing Data')),
                      );
                    }
                  },
                  child: const Text('Add Employee'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
