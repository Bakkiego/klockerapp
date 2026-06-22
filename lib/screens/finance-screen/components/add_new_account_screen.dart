import 'package:flutter/material.dart';

import '../../../supabase/repo/supabase_service.dart';

class AddNewAccountScreen extends StatefulWidget {
  const AddNewAccountScreen({super.key});

  @override
  State<AddNewAccountScreen> createState() => _AddNewAccountScreenState();
}

class _AddNewAccountScreenState extends State<AddNewAccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _initialBalanceController =
      TextEditingController();

  // State for selection fields
  String? _selectedAccountType;

  // Mock list of account types (e.g., Bank, Cash, Credit Card, Investment)
  final List<String> _accountTypes = const [
    'Bank',
    'Cash',
    'Credit Card',
    'E-Wallet',
    'Investment',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submitNewAccount() async {
    // <-- Add async
    if (_formKey.currentState!.validate()) {
      try {
        final initialBalance =
            double.tryParse(_initialBalanceController.text) ?? 0.0;

        // 🚀 Call your new Supabase Service
        await SupabaseService().addAccount(
          name: _nameController.text.trim(),
          type: _selectedAccountType ?? 'Other',
          initialBalance: initialBalance,
          // You can add TextFields for these later, or auto-generate them!
          accountNumber: 'TBD',
          branch: 'Main',
          code: '000',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
            context,
            true,
          ); // <-- Pass 'true' back so the list knows to refresh!
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Account')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Account Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText:
                      'Account Name (e.g., Personal Savings, Petty Cash)',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter an account name' : null,
              ),
              const SizedBox(height: 16),

              // 2. Account Type Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                value: _selectedAccountType,
                items: _accountTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAccountType = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select an account type' : null,
              ),
              const SizedBox(height: 16),

              // 3. Initial Balance
              TextFormField(
                controller: _initialBalanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  prefixText: '\$',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter the initial balance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 48),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitNewAccount,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save New Account',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
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
