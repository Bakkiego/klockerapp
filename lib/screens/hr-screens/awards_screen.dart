import 'package:flutter/material.dart';
import 'package:klockerapp/components/menu_expansion_tile.dart';

import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> {
  String award_option_title = "Awards Options";
  @override
  Widget build(BuildContext context) {
    List<MenuExpansionOBJ> awardsList = [
      MenuExpansionOBJ(
        title: 'Manager of The Year',
        onTap: () {
          setState(() {
            award_option_title = "Manager of The Year";
          });
        },
      ),
      MenuExpansionOBJ(
        title: 'Employee of The Year',
        onTap: () {
          setState(() {
            award_option_title = "Employee of The Year";
          });
        },
      ),
      MenuExpansionOBJ(
        title: 'Cook of The Year',
        onTap: () {
          setState(() {
            award_option_title = "Cook of The Year";
          });
        },
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Awards')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Award Lists"),
            MenuExpansionTile(
              awardsList,
              award_option_title,
              Icons.keyboard_option_key,
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
                child: const Text("Add", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
