import 'package:flutter/material.dart';

import 'components/add_new_account_screen.dart';
// Note: We keep EditAccountScreen and AccountDetailScreen imports
// because the FAB and Card Tap still depend on the navigation logic.
import 'components/edit_account_screen.dart';
import 'components/account_detail_screen.dart';

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  // Mock data structure (Unchanged)
  final List<Map<String, String>> _mockAccounts = const [
    {
      "id": "ACC001",
      "name": "Primary Savings",
      "number": "1234",
      "branch": "Downtown LA",
      "code": "09937",
      "balance": "5,000.00",
    },
    {
      "id": "ACC002",
      "name":
          "Business Checking and Investment Fund Linked Account", // Longer Name
      "number": "5678",
      "branch": "Midtown NY",
      "code": "08001",
      "balance": "12,500.50",
    },
    {
      "id": "ACC003",
      "name": "MasterCard Credit",
      "number": "9012",
      "branch": "Online",
      "code": "00001",
      "balance": "-1,200.00",
    },
  ];

  // Helper methods (Navigation) remain the same
  void _navigateToDetailScreen(Map<String, String> accountData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Card Tap goes to Detail Screen for full actions
        builder: (context) => AccountDetailScreen(accountDetails: accountData),
      ),
    );
  }

  Color _getBalanceColor(String balanceText) {
    final cleanedBalance = balanceText.replaceAll(',', '').replaceAll('\$', '');
    final balance = double.tryParse(cleanedBalance) ?? 0.0;

    if (balance > 0) return Colors.green.shade700;
    if (balance < 0) return Colors.red.shade700;
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts List')),
      body: Column(
        children: [
          // Search Bar Section (Unchanged)
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
          const SizedBox(height: 20),

          // Accounts List Section (Modified ListTile)
          Expanded(
            child: ListView.builder(
              itemCount: _mockAccounts.length,
              itemBuilder: (context, index) {
                final account = _mockAccounts[index];
                final balanceColor = _getBalanceColor(account['balance']!);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Card(
                    elevation: 2,
                    child: GestureDetector(
                      // 1. GESTURE DETECTOR: Tapping the card body goes to the Detail View
                      onTap: () => _navigateToDetailScreen(account),

                      child: ListTile(
                        // Account Name
                        title: Text(
                          account['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        // Account Details
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Account Number ${account['number']!}"),
                            Text("Branch: ${account['branch']!}"),
                            Text("Code: ${account['code']!}"),
                          ],
                        ),

                        // 🚩 MODIFIED: Trailing section contains ONLY the balance
                        trailing: SizedBox(
                          width: 80, // Fixed width for consistent alignment
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Account Balance
                              Text(
                                "\$${account['balance']!}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: balanceColor,
                                ),
                              ),
                            ],
                          ),
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
      // FAB (Unchanged)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddNewAccountScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
