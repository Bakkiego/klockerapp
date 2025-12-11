import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewDepositScreen extends StatefulWidget {
  const NewDepositScreen({super.key});

  @override
  State<NewDepositScreen> createState() => _NewDepositScreenState();
}

class _NewDepositScreenState extends State<NewDepositScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State for selection fields
  String? _selectedAccount;
  DateTime _selectedDate = DateTime.now();

  // Mock list of accounts for deposit
  final List<String> _availableAccounts = const [
    'Primary Savings (1234)',
    'Checking (5678)',
    'Business Account (9012)',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill the date field with today's date
    _dateController.text = DateFormat('MMM d, yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Date Picker Function ---
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Deposits are usually current or past dated
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('MMM d, yyyy').format(_selectedDate);
      });
    }
  }

  // Function to handle submitting the deposit
  void _submitDeposit() {
    if (_formKey.currentState!.validate()) {
      final depositData = {
        'account': _selectedAccount,
        'amount': _amountController.text,
        'date': _dateController.text,
        'notes': _notesController.text,
      };

      // TODO: Implement logic to send depositData to your backend
      print("New Deposit Submitted: $depositData");

      // Provide feedback and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deposit submitted successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Deposit')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Deposit Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // 1. Account Selection (Where the money is going)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Deposit To Account',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                value: _selectedAccount,
                items: _availableAccounts.map((String account) {
                  return DropdownMenuItem<String>(
                    value: account,
                    child: Text(account),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAccount = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select a destination account' : null,
              ),
              const SizedBox(height: 16),

              // 2. Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter deposit amount' : null,
              ),
              const SizedBox(height: 16),

              // 3. Date Picker Field
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Date of Deposit',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) => value!.isEmpty ? 'Select a date' : null,
              ),
              const SizedBox(height: 16),

              // 4. Notes/Description
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes/Reference (Optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                ),
              ),

              const SizedBox(height: 48),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitDeposit,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Record Deposit',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      Colors.green, // Use green for income/deposits
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
