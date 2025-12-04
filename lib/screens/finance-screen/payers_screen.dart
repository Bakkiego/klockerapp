import 'package:flutter/material.dart';

class PayersScreen extends StatelessWidget {
  const PayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payers')),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    hintText: "Payer Name",
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
                        "Payer Name $index",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Payees Name ${1000 + index}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
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
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}
