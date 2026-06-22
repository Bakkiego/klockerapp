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

  final TextEditingController _payeeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _refController = TextEditingController();

  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _availableAccounts = [];
  bool _isLoadingAccounts = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    try {
      final accounts = await SupabaseService().getAccounts();
      if (mounted) {
        setState(() {
          _availableAccounts = accounts;
          _isLoadingAccounts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAccounts = false);
    }
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _amountController.dispose();
    _paymentMethodController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final amount = double.parse(_amountController.text.replaceAll(',', ''));
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

        // 🚀 This automatically deducts from the bank balance via our SQL trigger!
        await SupabaseService().addExpense(
          accountId: _selectedAccountId!,
          payee: _payeeController.text.trim(),
          amount: amount,
          date: formattedDate,
          paymentMethod: _paymentMethodController.text.trim(),
          ref: _refController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense Recorded!'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, true); // Trigger refresh
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
      body: _isLoadingAccounts
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
                    items: _availableAccounts.map((account) {
                      return DropdownMenuItem<String>(
                        value: account['id'],
                        child: Text(account['name']),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedAccountId = val),
                    validator: (val) =>
                        val == null ? 'Select a source account' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Reason / Payee
                  TextFormField(
                    controller: _payeeController,
                    decoration: const InputDecoration(
                      labelText: 'Reason / Payee',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Amount (Styled for Expenses)
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$ ',
                      prefixIcon: Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Date Selection
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Expense',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Optional Details
                  TextFormField(
                    controller: _paymentMethodController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method (Optional)',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _refController,
                    decoration: const InputDecoration(
                      labelText: 'Reference # (Optional)',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 48),

                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitExpense,
                    icon: const Icon(Icons.outbox),
                    label: Text(
                      _isSubmitting ? 'Recording...' : 'Record Expense',
                      style: const TextStyle(fontSize: 18),
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
