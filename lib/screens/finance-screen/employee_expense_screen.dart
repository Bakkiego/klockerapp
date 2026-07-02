import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

class EmployeeExpenseScreen extends StatefulWidget {
  const EmployeeExpenseScreen({super.key});

  @override
  State<EmployeeExpenseScreen> createState() => _EmployeeExpenseScreenState();
}

class _EmployeeExpenseScreenState extends State<EmployeeExpenseScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _myExpenses = [];

  // 🚀 NEW: Dynamic currency variable (defaults to $ if loading fails)
  String _currencySymbol = '\$';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // 1. 🚀 UPDATED: Fetch BOTH the expenses and the company settings in one go!
  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Run both database calls at the exact same time for speed
      final results = await Future.wait([
        SupabaseService().getMyExpenseClaims(),
        SupabaseService().getTenantSettings(),
      ]);

      final expensesData = results[0] as List<Map<String, dynamic>>;
      final tenantSettings = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _myExpenses = expensesData;

          // 🚀 Inject the company's chosen currency!
          if (tenantSettings != null && tenantSettings['currency'] != null) {
            _currencySymbol = tenantSettings['currency'];
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading data: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 2. Submit REAL data to Supabase
  Future<void> _submitClaim() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final double? amount = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid amount"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await SupabaseService().submitExpenseClaim(
        description: _titleController.text.trim(),
        amount: amount,
      );

      if (mounted) {
        Navigator.pop(context); // Close the bottom sheet
        _titleController.clear();
        _amountController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Claim submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the list to show the new pending claim!
        _fetchInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orange; // Pending
    }
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Submit Expense Claim",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Description (e.g. Client Dinner)",
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    // 🚀 UPDATED: Uses the dynamic currency symbol
                    decoration: InputDecoration(
                      labelText: "Amount",
                      prefixText: "$_currencySymbol ",
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Receipt uploads coming soon!"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text("Attach Receipt"),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setSheetState(() => _isSubmitting = true);
                            await _submitClaim();
                            if (mounted)
                              setSheetState(() => _isSubmitting = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A36C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Submit Claim",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Expenses"), centerTitle: true),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _myExpenses.isEmpty
          ? const Center(
              child: Text(
                "No expense claims yet.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myExpenses.length,
              itemBuilder: (context, index) {
                final exp = _myExpenses[index];
                final String title = exp['title'] ?? 'Unknown Expense';
                final double amount =
                    (exp['amount'] as num?)?.toDouble() ?? 0.0;
                final String status = exp['status'] ?? 'Pending';
                final String date = exp['claim_date'] ?? 'No Date';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(date),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 🚀 UPDATED: Uses the dynamic currency symbol
                        Text(
                          "$_currencySymbol${amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showAddExpenseSheet,
        backgroundColor: const Color(0xFF00A36C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New Claim"),
      ),
    );
  }
}
