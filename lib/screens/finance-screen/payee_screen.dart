import 'package:flutter/material.dart';
import 'package:klockerapp/screens/finance-screen/components/add_payee_screen.dart';

import 'components/edit_payee_screen.dart';

class PayeeScreen extends StatefulWidget {
  const PayeeScreen({super.key});

  @override
  State<PayeeScreen> createState() => _PayeeScreenState();
}

class _PayeeScreenState extends State<PayeeScreen> {
  final Map<String, String> examplePayerData = const {
    "id":
        "PAYER001", // A unique ID is crucial for the database UPDATE operation
    "name": "Acme Corp Payroll Account",
    "accountNumber": "9876543210",
    "bankName": "First Global Bank",
    "type": "External", // Optional: useful for categorizing payers
  };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payees')),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    hintText: "Payee Name",
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
                        "Payee Name $index",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Account Number ${1000 + index}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditPayeeScreen(
                                    initialPayerData: {
                                      "id": "PAYER001",
                                      "name": "Acme Corp Payroll Account",
                                      "accountNumber": "9876543210",
                                      "bankName": "First Global Bank",
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.delete),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPayeeScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
