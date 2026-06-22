import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import '../../../supabase/repo/supabase_service.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> initialExpenseData;

  const EditExpenseScreen({super.key, required this.initialExpenseData});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _payeeController;
  late TextEditingController _paymentMethodController;
  late TextEditingController _refController;

  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _payeeController = TextEditingController(
      text: widget.initialExpenseData['payee']?.toString() ?? '',
    );
    _paymentMethodController = TextEditingController(
      text: widget.initialExpenseData['payment_method']?.toString() ?? '',
    );
    _refController = TextEditingController(
      text: widget.initialExpenseData['ref']?.toString() ?? '',
    );

    try {
      final dateStr = widget.initialExpenseData['expense_date']?.toString();
      _selectedDate = dateStr != null
          ? DateTime.parse(dateStr)
          : DateTime.now();
    } catch (_) {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _paymentMethodController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

        // You'll need to add an updateExpense method in your SupabaseService
        // to update the 'payee', 'expense_date', 'payment_method', and 'ref' columns.
        await SupabaseService().updateExpense(
          id: widget.initialExpenseData['id'],
          payee: _payeeController.text.trim(),
          date: formattedDate,
          paymentMethod: _paymentMethodController.text.trim(),
          ref: _refController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully!'),
              backgroundColor: Colors.red,
            ),
          );
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
    // 🚀 Grabs the live currency symbol from settings!
    final currency = context.watch<UserProvider>().currencySymbol;

    // We display the amount as read-only text, as changing amounts on posted expenses
    // usually requires a void/re-issue to keep bank balances perfectly synced.
    final amountStr = widget.initialExpenseData['amount']?.toString() ?? '0.00';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense Details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Amount Display (Read Only)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Posted Amount",
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  Text(
                    // 🚀 CHANGED: Using dynamic currency
                    "$currency$amountStr",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Payee
            TextFormField(
              controller: _payeeController,
              decoration: const InputDecoration(
                labelText: 'Reason / Payee',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Date
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

            // Payment Method
            TextFormField(
              controller: _paymentMethodController,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 16),

            // Reference #
            TextFormField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: 'Reference #',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _saveChanges,
              icon: const Icon(Icons.save),
              label: Text(
                _isSubmitting ? 'Saving...' : 'Save Changes',
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
