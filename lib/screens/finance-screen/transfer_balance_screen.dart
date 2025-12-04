import 'package:flutter/material.dart';

class ManageTransferScreen extends StatefulWidget {
  const ManageTransferScreen({super.key});

  @override
  State<ManageTransferScreen> createState() => _ManageTransferScreenState();
}

class _ManageTransferScreenState extends State<ManageTransferScreen> {
  // Mock data for UI demonstration
  final List<Map<String, String>> _mockTransfers = const [
    {
      "from": "Savings (1234)",
      "to": "Checking (5678)",
      "amount": "1,500.00",
      "date": "Sep 15, 2025",
    },
    {
      "from": "Investment (9012)",
      "to": "Savings (1234)",
      "amount": "5,000.00",
      "date": "Aug 28, 2025",
    },
    {
      "from": "Checking (5678)",
      "to": "Savings (1234)",
      "amount": "250.00",
      "date": "Aug 10, 2025",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer History')),

      body: Column(
        children: [
          // 1. Search Bar Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: "Search by Account...",
              trailing: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list),
                ),
              ],
            ),
          ),

          // 2. The Scrollable List of Transfer Cards
          Expanded(
            child: ListView.builder(
              itemCount: _mockTransfers.length,
              itemBuilder: (context, index) {
                final transfer = _mockTransfers[index];

                return GestureDetector(
                  onTap: () {
                    // Placeholder for navigation to Transfer Detail Screen
                    print(
                      "Tapped on transfer: ${transfer['from']} to ${transfer['to']}",
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Side: Transfer Flow (FROM -> TO)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Visually represent the flow of money
                                  Text(
                                    transfer['from']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: Colors.blueAccent,
                                  ),
                                  Text(
                                    transfer['to']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    transfer['date']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right Side: Amount
                            Text(
                              "\$${transfer['amount']!}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: Colors
                                    .blueAccent, // Common color for transfers/internal movement
                              ),
                            ),
                          ],
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

      // 3. Floating Action Button (FAB) for adding new transfers
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Logic for navigating to the Add New Transfer form
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
