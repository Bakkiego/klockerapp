import 'package:flutter/material.dart';

class AddPayerScreen extends StatefulWidget {
  const AddPayerScreen({super.key});

  @override
  State<AddPayerScreen> createState() => _AddPayerScreenState();
}

class _AddPayerScreenState extends State<AddPayerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for Payer details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _submitNewPayer() {
    if (_formKey.currentState!.validate()) {
      final newPayerData = {
        'name': _nameController.text,
        'accountNumber': _accountNumberController.text,
        'bankName': _bankNameController.text,
      };

      // TODO: Implement logic to save newPayerData to your backend
      print("New Payer Submitted: $newPayerData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payer added successfully!')),
      );
      Navigator.pop(context); // Go back to the main list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Payer')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payer Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Payer Name (e.g., Company Account)',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter payer name' : null,
              ),
              const SizedBox(height: 16),

              // Account Number
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Account Number'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter account number' : null,
              ),
              const SizedBox(height: 16),

              // Bank Name/Source
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name/Source',
                ),
              ),

              const SizedBox(height: 48),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitNewPayer,
                icon: const Icon(Icons.save),
                label: const Text('Add Payer', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
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
