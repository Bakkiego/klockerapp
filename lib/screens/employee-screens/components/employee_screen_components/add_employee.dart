import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/data_collector_list.dart';

class AddEmployee extends StatefulWidget {
  const AddEmployee({super.key});

  @override
  State<AddEmployee> createState() => _AddEmployeeState();
}

class _AddEmployeeState extends State<AddEmployee> {
  // DataCollectorList is still just a data provider.
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
    return Form(
      key: dataCollectorList.formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...dataCollectorList.personalTileBody,
              const SizedBox(height: 16),
              // --- Call the method and pass the date picking function ---
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
    );
  }
}
