import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import '../../../supabase/repo/supabase_service.dart';
import 'edit_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> expenseDetails; // 🚀 Updated to dynamic

  const ExpenseDetailScreen({super.key, required this.expenseDetails});

  @override
  Widget build(BuildContext context) {
    // 🚀 Grabs the live currency symbol from settings!
    final currency = context.watch<UserProvider>().currencySymbol;

    final payee = expenseDetails['payee']?.toString() ?? 'N/A';
    final amount = expenseDetails['amount']?.toString() ?? '0.00';
    final account =
        expenseDetails['accounts']?['name']?.toString() ?? 'Unknown Account';
    final ref = expenseDetails['ref']?.toString() ?? '-';
    final payment = expenseDetails['payment_method']?.toString() ?? 'Other';

    String dateStr = expenseDetails['expense_date']?.toString() ?? 'N/A';
    try {
      if (dateStr != 'N/A') {
        dateStr = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
      }
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Text(payee),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditExpenseScreen(initialExpenseData: expenseDetails),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              // Quick inline delete confirmation
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text("Delete Expense"),
                  content: const Text("Are you sure? This cannot be undone."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await SupabaseService().deleteExpense(expenseDetails['id']);
                if (context.mounted)
                  Navigator.pop(context, true); // Pop back and refresh list
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Prominent Amount Block ---
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
                    // 🚀 CHANGED: Using dynamic currency instead of hardcoded $
                    '$currency$amount',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paid on $dateStr',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. Details Section ---
            const Text(
              'Transaction Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.person_outline,
              label: 'Reason/Payee',
              value: payee,
            ),
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: dateStr,
            ),
            const SizedBox(height: 24),

            // --- 3. Payment Section ---
            const Text(
              'Payment Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payer Account',
              value: account,
            ),
            _buildDetailRow(
              icon: Icons.credit_card_outlined,
              label: 'Payment Method',
              value: payment,
            ),
            _buildDetailRow(
              icon: Icons.numbers,
              label: 'Reference #',
              value: ref,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
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
