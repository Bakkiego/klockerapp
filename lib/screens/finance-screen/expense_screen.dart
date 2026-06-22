import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import '../../../supabase/repo/supabase_service.dart';
import 'components/expense_detail_screen.dart';
import 'components/add_expense_screen.dart'; // Ensure you create this file!

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getExpenses();
      if (mounted)
        setState(() {
          _expenses = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Grabs the live currency symbol from settings!
    final currency = context.watch<UserProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              hintText: "Search Expenses...",
              trailing: [const Icon(Icons.search, color: Colors.grey)],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  )
                : _expenses.isEmpty
                ? const Center(child: Text("No expenses recorded yet."))
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _expenses[index];

                      // Format date nicely
                      String dateStr =
                          expense['expense_date']?.toString() ?? '';
                      try {
                        if (dateStr.isNotEmpty) {
                          dateStr = DateFormat(
                            'MMM dd, yyyy',
                          ).format(DateTime.parse(dateStr));
                        }
                      } catch (_) {}

                      final amountStr = expense['amount']?.toString() ?? '0.00';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpenseDetailScreen(
                                  expenseDetails: expense,
                                ),
                              ),
                            );
                            if (result == true) _fetchExpenses();
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Colors.red,
                            ),
                          ),
                          title: Text(
                            expense['payee'] ?? 'Unknown Cost',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            dateStr,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Text(
                            // 🚀 CHANGED: Using dynamic currency
                            "-$currency$amountStr",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
          if (result == true) _fetchExpenses();
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        label: const Text(
          "Add Expense",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
