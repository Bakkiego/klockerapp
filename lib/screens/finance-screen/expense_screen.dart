import 'package:flutter/material.dart';

// 1. Simple Data Model for an Expense (Optional, but good practice)
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  // Sample Data List based on the web UI and typical expenses
  final List<Map<String, String>> _mockExpenses = const [
    {
      "payee": "Jessica",
      "amount": "49,700.00",
      "category": "Cash",
      "date": "Sep 3, 2025",
    },
    {
      "payee": "Gas Station",
      "amount": "65.50",
      "category": "Fuel",
      "date": "Sep 5, 2025",
    },
    {
      "payee": "ACME Suppliers",
      "amount": "1,250.00",
      "category": "Inventory",
      "date": "Sep 1, 2025",
    },
    {
      "payee": "Jane Doe",
      "amount": "450.00",
      "category": "Office Supplies",
      "date": "Aug 29, 2025",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),

      body: Column(
        children: [
          // 1. Search Bar Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: "Search by Payee or Category...",
              trailing: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list),
                ),
              ],
            ),
          ),

          // 2. The Scrollable List of Expense Cards
          Expanded(
            child: ListView.builder(
              itemCount: _mockExpenses.length,
              itemBuilder: (context, index) {
                final expense = _mockExpenses[index];

                return GestureDetector(
                  onTap: () {
                    // Placeholder for navigation to Expense Detail Screen
                    print("Tapped on expense: ${expense['payee']}");
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
                            // Left Side: Payee, Date, Category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense['payee']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    expense['date']!,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  // Chip for Category visualization
                                  Chip(
                                    label: Text(expense['category']!),
                                    padding: EdgeInsets.zero,
                                    labelStyle: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // Right Side: Amount
                            Text(
                              "\$${expense['amount']!}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: Colors.red, // Expense color
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

      // 3. Floating Action Button (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Logic for navigating to the Add New Expense form
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
