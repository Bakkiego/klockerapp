import 'package:flutter/material.dart';

import 'components/edit_branch_screen.dart';

class BranchScreen extends StatelessWidget {
  const BranchScreen({super.key});

  final Map<String, String> exampleBranchData = const {
    "id":
        "BRANCH001", // A unique ID is crucial for the database UPDATE operation
    "name": "Branch Name",
    "address": "123 Main Street",
    "code": "BR001",
    "isOperational": "true",
    // Optional: useful for categorizing payers
  };

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
                  hintText: "Branch Name",
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
        SizedBox(height: 20),
        Expanded(
          // <-- This is NECESSARY to make the list take remaining space
          child: ListView.builder(
            itemCount: 5, // Replace with your actual accounts.length
            itemBuilder: (context, index) {
              // Create the Card UI proposed in the visualization for each item
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Card(
                  child: ListTile(
                    // ListTile works perfectly as the child of a Card/ListView item
                    // Note: If you want the visual from the example, you should use
                    // a Row with an Expanded widget inside the Card instead of a simple ListTile.

                    // Simple working structure with ListTile:
                    title: Text(
                      "Branch $index",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Location"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditBranchScreen(
                                  initialBranchData: Map.from(
                                    exampleBranchData,
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.edit),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
