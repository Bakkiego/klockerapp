import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditTransferScreen extends StatefulWidget {
  // Pass the current transfer data into the screen to pre-fill the form
  final Map<String, String> initialTransferData;

  const EditTransferScreen({super.key, required this.initialTransferData});

  @override
  State<EditTransferScreen> createState() => _EditTransferScreenState();
}

class _EditTransferScreenState extends State<EditTransferScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers and State for editable fields
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _refController;

  // Since FROM and TO accounts are often selected from a list,
  // we'll mock them with strings for simplicity in this UI code.
  late String _selectedFromAccount;
  late String _selectedToAccount;

  late DateTime _selectedDate;

  // Mock list of available accounts for dropdown/selection
  final List<String> _availableAccounts = const [
    'Primary Savings (1234)',
    'Checking (5678)',
    'Investment Portfolio (9012)',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers and state with the existing transfer data
    _amountController = TextEditingController(
      text: widget.initialTransferData['amount'],
    );
    _refController = TextEditingController(
      text: widget.initialTransferData['ref'],
    );
    _dateController = TextEditingController(
      text: widget.initialTransferData['date'],
    );

    _selectedFromAccount =
        widget.initialTransferData['from'] ?? _availableAccounts.first;
    _selectedToAccount =
        widget.initialTransferData['to'] ?? _availableAccounts.first;

    // Handle Date initialization
    try {
      // Assuming date format is 'Sep 15, 2025' (MMM d, yyyy) from our mock
      _selectedDate = DateFormat('MMM d, yyyy').parse(
        widget.initialTransferData['date'] ??
            DateFormat('MMM d, yyyy').format(DateTime.now()),
      );
    } catch (e) {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _amountController.dispose();
    _dateController.dispose();
    _refController.dispose();
    super.dispose();
  }

  // Function to handle the date picking
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('MMM d, yyyy').format(_selectedDate);
      });
    }
  }

  // Function to handle saving the changes
  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // 1. Collect all updated data
      final updatedData = {
        'from': _selectedFromAccount,
        'to': _selectedToAccount,
        'amount': _amountController.text,
        'date': _dateController.text,
        'ref': _refController.text,
        // Include other fields like paymentMethod if editable
      };

      // 2. TODO: Implement logic to send updatedData to your backend/service
      print("Saving transfer changes: $updatedData");

      // 3. Provide feedback and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer updated successfully!')),
      );
      Navigator.pop(context); // Go back to the Detail screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transfer')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Transfer Accounts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // FROM Account Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Transfer From Account',
                ),
                value: _selectedFromAccount,
                items: _availableAccounts.map((String account) {
                  return DropdownMenuItem<String>(
                    value: account,
                    child: Text(account),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFromAccount = newValue!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select source account' : null,
              ),
              const SizedBox(height: 16),

              // TO Account Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Transfer To Account',
                ),
                value: _selectedToAccount,
                items: _availableAccounts.map((String account) {
                  return DropdownMenuItem<String>(
                    value: account,
                    child: Text(account),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedToAccount = newValue!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select destination account' : null,
              ),

              const SizedBox(height: 32),

              const Text(
                'Transfer Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter transfer amount' : null,
              ),
              const SizedBox(height: 16),

              // Date Picker Field
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) => value!.isEmpty ? 'Select a date' : null,
              ),
              const SizedBox(height: 16),

              // Reference #
              TextFormField(
                controller: _refController,
                decoration: const InputDecoration(
                  labelText: 'Reference # (Optional)',
                ),
              ),

              const SizedBox(height: 48),

              // Save Button
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Save Transfer Changes',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Example usage to navigate from the TransferDetailScreen:
/*
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditTransferScreen(
      initialTransferData: {
        "from": "Primary Savings (1234)",
        "to": "Investment Portfolio (9012)",
        "amount": "1,500.00",
        "date": "Sep 15, 2025",
        "paymentMethod": "Bank Transfer",
        "ref": "TRN-98765-ABC",
      },
    ),
  ),
);
*/
