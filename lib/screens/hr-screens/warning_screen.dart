import 'package:flutter/material.dart';

import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class WarningScreen extends StatelessWidget {
  const WarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warning')),
      body: Form(
        child: Column(
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
              TextButton(
                onPressed: () {},
                child: const Text("Select", style: TextStyle(fontSize: 18)),
              ),
            ),
            TextField(
              maxLines: null, // Allows for multiple lines of input
              keyboardType: TextInputType
                  .multiline, // Optimizes keyboard for multiline text
              decoration: const InputDecoration(
                labelText: 'Enter Warning Message',
                hintText: 'Type your detailed description here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*Implement warning count on each employee as you begin working on this feature.*/
