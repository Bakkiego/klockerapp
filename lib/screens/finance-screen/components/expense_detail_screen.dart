import 'package:flutter/material.dart';

import 'edit_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  // Mock data representing a single selected expense
  final Map<String, String> expenseDetails;

  const ExpenseDetailScreen({
    super.key,
    // Require the details to be passed when navigating to this screen
    required this.expenseDetails,
  });

  @override
  Widget build(BuildContext context) {
    // Extract required data, using safe defaults
    final payee = expenseDetails['payee'] ?? 'N/A';
    final amount = expenseDetails['amount'] ?? '0.00';
    final date = expenseDetails['date'] ?? 'N/A';
    final account = expenseDetails['account'] ?? 'N/A'; // Payer Account
    final category = expenseDetails['category'] ?? 'N/A';
    final ref = expenseDetails['ref'] ?? 'N/A';
    final payment = expenseDetails['payment'] ?? 'N/A'; // Payment Method

    return Scaffold(
      appBar: AppBar(
        title: Text(payee), // Use Payee name as title
        actions: [
          // Action button for editing the expense
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Navigate to the Edit Expense screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditExpenseScreen(
                    initialExpenseData: {
                      "payee": "Jessica",
                      "amount": "49700.00",
                      "category": "Cash",
                      "payment": "Bank Transfer",
                      "date": "Sep 3, 2025",
                      "ref": "-",
                    },
                  ),
                ),
              );
              print('Edit expense tapped');
            },
          ),
          // Action button for deleting the expense
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // TODO: Show delete confirmation dialog
              print('Delete expense tapped');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Prominent Amount/Summary Block ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                children: [
                  const Text(
                    'Expense Amount',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$$amount',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paid on $date',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. Payee and Transaction Details Section ---
            const Text(
              'Transaction Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            _buildDetailRow(
              context,
              icon: Icons.person_outline,
              label: 'Payee',
              value: payee,
            ),
            _buildDetailRow(
              context,
              icon: Icons.category_outlined,
              label: 'Category',
              value: category,
            ),
            _buildDetailRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: date,
            ),

            const SizedBox(height: 24),

            // --- 3. Payment Information Section ---
            const Text(
              'Payment Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            _buildDetailRow(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payer Account',
              value: account,
            ),
            _buildDetailRow(
              context,
              icon: Icons.credit_card_outlined,
              label: 'Payment Method',
              value: payment,
            ),
            _buildDetailRow(
              context,
              icon: Icons.numbers,
              label: 'Reference #',
              value: ref,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Reusable widget to display a single detail row
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// Example usage when navigating from the Expense List screen:
/*
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ExpenseDetailScreen(
      expenseDetails: {
        "account": "-",
        "payee": "Jessica",
        "amount": "49,700.00",
        "category": "Cash",
        "ref": "-",
        "payment": "Bank Transfer",
        "date": "Sep 3, 2025"
      },
    ),
  ),
);
*/
