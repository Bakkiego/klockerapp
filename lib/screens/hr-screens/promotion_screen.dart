import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/k_dropdown_field.dart';

import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class PromotionScreen extends StatelessWidget {
  const PromotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promotion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                child: const Text("Promote", style: TextStyle(fontSize: 18)),
              ),
            ),
            KDropDownField(
              items: ["Manager", "Head Chef", "C.O.0"],
              hintText: "Promotion Role",
            ),
          ],
        ),
      ),
    );
  }
}
