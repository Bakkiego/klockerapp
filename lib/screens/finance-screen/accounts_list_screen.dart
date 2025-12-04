import 'package:flutter/material.dart';

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts List')),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    hintText: "Account Name",
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
                        "Account Name $index",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Account Number ${1000 + index}"),
                          Text("Branch : Downtown LA"),
                          Text("Code: 09937"),
                        ],
                      ),
                      trailing: const Text(
                        "\$5,000.00",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}
