import 'package:flutter/material.dart';

import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class TerminationScreen extends StatelessWidget {
  const TerminationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termination')),
      body: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [Icon(Icons.upload), Text("Termination Document")],
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Upload Document",
                style: TextStyle(fontSize: 18),
              ),
            ),
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
                child: const Text("Terminate", style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Process Termination",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
