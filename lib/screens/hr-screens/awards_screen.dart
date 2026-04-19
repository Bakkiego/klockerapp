import 'package:flutter/material.dart';
import 'package:klockerapp/components/menu_expansion_tile.dart';
import '../employee-screens/components/employee_screen_components/employee_tile.dart';

class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> {
  // Keeping your exact variable name
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
      // backgroundColor: const Color(
      //   0xFFF8F9FA,
      // ), // Professional light grey background
      appBar: AppBar(
        title: const Text('Awards'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Award Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            // Your custom MenuExpansionTile
            MenuExpansionTile(
              awardsList,
              award_option_title,
              Icons.workspace_premium_outlined,
            ),

            const SizedBox(height: 30),

            const Text(
              "Search Employee",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            // Polished SearchBar
            SearchBar(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              side: WidgetStateProperty.all(
                BorderSide(color: Colors.grey.shade300),
              ),
              hintText: "Enter employee name...",
              padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              leading: const Icon(Icons.search, color: Colors.grey),
            ),

            const SizedBox(height: 25),

            const Text(
              "Search Results",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            // Using your EmployeeTile component
            EmployeeTile(
              () {},
              "John Doe",
              TextButton(
                onPressed: () {
                  // Instant feedback for the demo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Success: $award_option_title assigned to John Doe",
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF00A36C),
                    ),
                  );
                },
                child: const Text(
                  "Add",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A36C),
                  ),
                ),
              ),
              "Main Branch",
              "Senior Staff",
            ),
          ],
        ),
      ),
    );
  }
}
