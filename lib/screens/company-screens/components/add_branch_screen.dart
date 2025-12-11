import 'package:flutter/material.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for Branch details
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  // State for operational status
  bool _isOperational = true;

  @override
  void dispose() {
    _branchNameController.dispose();
    _addressController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submitNewBranch() {
    if (_formKey.currentState!.validate()) {
      final newBranchData = {
        'name': _branchNameController.text,
        'address': _addressController.text,
        'code': _codeController.text,
        'isOperational': _isOperational.toString(),
      };

      // TODO: Implement logic to save newBranchData to your backend
      print("New Branch Submitted: $newBranchData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branch added successfully!')),
      );
      Navigator.pop(context); // Go back to the main list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Branch')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Branch Name
              TextFormField(
                controller: _branchNameController,
                decoration: const InputDecoration(
                  labelText: 'Branch Name (e.g., Downtown LA, HQ Branch)',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter branch name' : null,
              ),
              const SizedBox(height: 16),

              // 2. Branch Code
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Branch Code/Identifier',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter a branch code' : null,
              ),
              const SizedBox(height: 16),

              // 3. Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter the branch address' : null,
              ),
              const SizedBox(height: 24),

              // 4. Status Toggle
              SwitchListTile(
                title: const Text('Operational Status'),
                subtitle: Text(
                  _isOperational
                      ? 'Branch is currently active'
                      : 'Branch is temporarily inactive',
                ),
                value: _isOperational,
                onChanged: (bool newValue) {
                  setState(() {
                    _isOperational = newValue;
                  });
                },
                secondary: Icon(
                  _isOperational
                      ? Icons.check_circle
                      : Icons.pause_circle_outline,
                  color: _isOperational ? Colors.green : Colors.orange,
                ),
              ),

              const SizedBox(height: 48),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitNewBranch,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save New Branch',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
