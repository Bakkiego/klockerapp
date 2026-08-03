import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../supabase/repo/supabase_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _refController = TextEditingController();

  String? _selectedAccountId;
  String? _selectedCategory; // 🚀 Replaces Payee
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _availableAccounts = [];
  List<Map<String, dynamic>> _categories = []; // 🚀 Holds DB categories
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        SupabaseService().getAccounts(),
        SupabaseService().getExpenseCategories(), // Fetch manager's categories
      ]);
      if (mounted) {
        setState(() {
          _availableAccounts = results[0];
          _categories = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final amount = double.parse(_amountController.text.replaceAll(',', ''));
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

        // 🚀 Updated logic: passing category instead of payee
        await SupabaseService().addExpense(
          accountId: _selectedAccountId!,
          category: _selectedCategory!,
          amount: amount,
          date: formattedDate,
          paymentMethod: _paymentMethodController.text.trim(),
          ref: _refController.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Expense')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. Account Selection
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Pay From Account',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    value: _selectedAccountId,
                    items: _availableAccounts
                        .map(
                          (a) => DropdownMenuItem<String>(
                            value: a['id'],
                            child: Text(a['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedAccountId = val),
                    validator: (val) =>
                        val == null ? 'Select an account' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. 🚀 Dropdown replacing Payee/Description
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Expense Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    value: _selectedCategory,
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['category_name'],
                            child: Text(c['category_name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money, color: Colors.red),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Date Selection
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null)
                        setState(() => _selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Expense',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitExpense,
                    icon: const Icon(Icons.outbox),
                    label: Text(
                      _isSubmitting ? 'Recording...' : 'Record Expense',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
