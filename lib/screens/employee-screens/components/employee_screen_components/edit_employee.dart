import 'package:flutter/material.dart';
import 'employee_tile.dart';

class EditEmployee extends StatefulWidget {
  const EditEmployee({super.key});

  @override
  State<EditEmployee> createState() => _EditEmployeeState();
}

class _EditEmployeeState extends State<EditEmployee> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SearchBar(
                  hintText: "Employee name",
                  trailing: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        EmployeeTile(
          () {},
          "John",
          Row(
            mainAxisSize: MainAxisSize
                .min, // Prevents the Row from taking all available space
            children: const [
              Icon(Icons.edit_outlined), // First icon (e.g., Edit)
              SizedBox(width: 8), // Add some space between icons
              Icon(Icons.delete_outline, color: Colors.red),
            ],
          ),
        ),
      ],
    );
  }
}
