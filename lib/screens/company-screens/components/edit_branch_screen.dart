import 'package:flutter/material.dart';

class EditBranchScreen extends StatefulWidget {
  // Receives the current branch data to pre-fill the form
  final Map<String, String> initialBranchData;

  const EditBranchScreen({super.key, required this.initialBranchData});

  @override
  State<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends State<EditBranchScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for Branch details
  late TextEditingController _branchNameController;
  late TextEditingController _addressController;
  late TextEditingController _codeController;

  // State for operational status
  late bool _isOperational;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _branchNameController = TextEditingController(
      text: widget.initialBranchData['name'],
    );
    _addressController = TextEditingController(
      text: widget.initialBranchData['address'],
    );
    _codeController = TextEditingController(
      text: widget.initialBranchData['code'],
    );

    // Initialize status (default to true if data is missing or invalid)
    _isOperational =
        widget.initialBranchData['isOperational']?.toLowerCase() == 'true';
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _addressController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedBranchData = {
        'id': widget.initialBranchData['id'], // Crucial for database update
        'name': _branchNameController.text,
        'address': _addressController.text,
        'code': _codeController.text,
        'isOperational': _isOperational.toString(),
      };

      // TODO: Implement logic to update branchData in your backend
      print("Branch changes saved: $updatedBranchData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branch updated successfully!')),
      );
      Navigator.pop(context); // Go back to the main list/detail screen
    }
  }

  void _showDeleteConfirmation() {
    // Standard delete confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete the branch: ${widget.initialBranchData['name']}? This action cannot be undone.',
        ),
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
              ).showSnackBar(const SnackBar(content: Text('Branch Deleted!')));
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
    // Get the current theme's color for styling consistency
    final primaryColor =
        Theme.of(
          context,
        ).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
        Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Branch: ${widget.initialBranchData['name']}'),
      ),
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
                  labelText: 'Branch Name',
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
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Delete Button
              OutlinedButton.icon(
                onPressed: _showDeleteConfirmation,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Branch',
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
