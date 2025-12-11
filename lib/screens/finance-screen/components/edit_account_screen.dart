import 'package:flutter/material.dart';

class EditAccountScreen extends StatefulWidget {
  // Receives the current account data to pre-fill the form
  final Map<String, String> initialAccountData;

  const EditAccountScreen({super.key, required this.initialAccountData});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _initialBalanceController;
  late TextEditingController _branchController;
  late TextEditingController _codeController;

  // State for selection fields
  late String _selectedAccountType;

  // Mock list of account types
  final List<String> _accountTypes = const [
    'Bank',
    'Cash',
    'Credit Card',
    'E-Wallet',
    'Investment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _nameController = TextEditingController(
      text: widget.initialAccountData['name'],
    );
    _initialBalanceController = TextEditingController(
      text: widget.initialAccountData['balance'],
    );
    _branchController = TextEditingController(
      text: widget.initialAccountData['branch'],
    );
    _codeController = TextEditingController(
      text: widget.initialAccountData['code'],
    );

    // Initialize selected type
    _selectedAccountType =
        widget.initialAccountData['type'] ?? _accountTypes.first;
    if (!_accountTypes.contains(_selectedAccountType)) {
      _selectedAccountType =
          _accountTypes.first; // Default if type is not in list
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _branchController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedAccountData = {
        'id': widget
            .initialAccountData['id'], // Important for updating the correct record
        'name': _nameController.text,
        'type': _selectedAccountType,
        'balance': _initialBalanceController.text,
        'branch': _branchController.text,
        'code': _codeController.text,
      };

      // TODO: Implement logic to update account data in your backend
      print("Account changes saved: $updatedAccountData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully!')),
      );
      Navigator.pop(context); // Go back to the previous screen (Detail or List)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.initialAccountData['name']}')),
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
                  labelText: 'Account Name',
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
                    _selectedAccountType = newValue!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select an account type' : null,
              ),
              const SizedBox(height: 16),

              // 3. Initial/Current Balance (often restricted in real apps, but editable here)
              TextFormField(
                controller: _initialBalanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Balance',
                  prefixText: '\$',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) => value!.isEmpty ? 'Enter balance' : null,
              ),
              const SizedBox(height: 16),

              // 4. Branch Name
              TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(labelText: 'Branch Name'),
              ),
              const SizedBox(height: 16),

              // 5. Code
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Code'),
              ),

              const SizedBox(height: 48),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.update),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
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
