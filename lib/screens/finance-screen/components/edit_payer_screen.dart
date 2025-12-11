import 'package:flutter/material.dart';

class EditPayerScreen extends StatefulWidget {
  // Pass the current payer data into the screen to pre-fill the form
  final Map<String, String> initialPayerData;

  const EditPayerScreen({super.key, required this.initialPayerData});

  @override
  State<EditPayerScreen> createState() => _EditPayerScreenState();
}

class _EditPayerScreenState extends State<EditPayerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for Payer details
  late TextEditingController _nameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the existing payer data
    _nameController = TextEditingController(
      text: widget.initialPayerData['name'],
    );
    _accountNumberController = TextEditingController(
      text: widget.initialPayerData['accountNumber'],
    );
    _bankNameController = TextEditingController(
      text: widget.initialPayerData['bankName'],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedPayerData = {
        'name': _nameController.text,
        'accountNumber': _accountNumberController.text,
        'bankName': _bankNameController.text,
        // Include any required ID for the update operation
      };

      // TODO: Implement logic to UPDATE the payer data in your backend
      print("Payer changes saved: $updatedPayerData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payer updated successfully!')),
      );
      Navigator.pop(context); // Go back to the main list
    }
  }

  void _showDeleteConfirmation() {
    // Standard delete confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this Payer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual delete logic
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to the list screen
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Payer Deleted!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Payer: ${widget.initialPayerData['name']}'),
      ),
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
                decoration: const InputDecoration(labelText: 'Payer Name'),
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

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Delete Button
              OutlinedButton.icon(
                onPressed: _showDeleteConfirmation,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Payer',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
