import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// NOTE: In a real app, you would create a dedicated set of controllers
// and potentially a service class to handle expense data.
// For this UI, we'll use local TextControllers initialized with mock data.

class EditExpenseScreen extends StatefulWidget {
  // Pass the current expense data into the screen to pre-fill the form
  final Map<String, String> initialExpenseData;

  const EditExpenseScreen({super.key, required this.initialExpenseData});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for all editable fields
  late TextEditingController _payeeController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _paymentController;
  late TextEditingController _dateController;
  late TextEditingController _refController;

  // State for date picker
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with the existing expense data
    _payeeController = TextEditingController(
      text: widget.initialExpenseData['payee'],
    );
    _amountController = TextEditingController(
      text: widget.initialExpenseData['amount'],
    );
    _categoryController = TextEditingController(
      text: widget.initialExpenseData['category'],
    );
    _paymentController = TextEditingController(
      text: widget.initialExpenseData['payment'],
    );
    _refController = TextEditingController(
      text: widget.initialExpenseData['ref'],
    );

    // Handle Date initialization
    _dateController = TextEditingController(
      text: widget.initialExpenseData['date'],
    );
    try {
      _selectedDate = DateFormat('MMM d, yyyy').parse(
        widget.initialExpenseData['date'] ??
            DateFormat('MMM d, yyyy').format(DateTime.now()),
      );
    } catch (e) {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers to free up memory
    _payeeController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _paymentController.dispose();
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
      // 1. Collect all updated data from controllers
      final updatedData = {
        'payee': _payeeController.text,
        'amount': _amountController.text,
        'category': _categoryController.text,
        'payment': _paymentController.text,
        'date': _dateController.text,
        'ref': _refController.text,
      };

      // 2. TODO: Implement logic to send updatedData to your backend/service
      print("Saving changes: $updatedData");

      // 3. Provide feedback and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated successfully!')),
      );
      Navigator.pop(context); // Go back to the Detail screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payee
              TextFormField(
                controller: _payeeController,
                decoration: const InputDecoration(labelText: 'Payee Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter payee name' : null,
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) => value!.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 16),

              // Category (Can be converted to a Dropdown in a real app)
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),

              // Payment Method
              TextFormField(
                controller: _paymentController,
                decoration: const InputDecoration(labelText: 'Payment Method'),
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

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Changes',
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

// Example usage to navigate from the ExpenseDetailScreen:
/*
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditExpenseScreen(
      initialExpenseData: {
        "payee": "Jessica",
        "amount": "49700.00",
        "category": "Cash",
        "payment": "Bank Transfer",
        "date": "Sep 3, 2025",
        "ref": "-",
      },
    ),
  ),
);
*/
