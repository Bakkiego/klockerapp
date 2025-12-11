import 'package:flutter/material.dart';

class EditDepartmentScreen extends StatefulWidget {
  // Receives the current department data to pre-fill the form
  final Map<String, String> initialDepartmentData;

  const EditDepartmentScreen({super.key, required this.initialDepartmentData});

  @override
  State<EditDepartmentScreen> createState() => _EditDepartmentScreenState();
}

class _EditDepartmentScreenState extends State<EditDepartmentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for Department details
  late TextEditingController _departmentNameController;
  late TextEditingController _departmentCodeController;

  // State for selection fields (Department Manager)
  late String? _selectedManager;

  // Mock list of potential managers
  final List<String> _availableManagers = const [
    'Sarah Connor',
    'John Smith',
    'Linda Ray',
    'Michael Chen',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _departmentNameController = TextEditingController(
      text: widget.initialDepartmentData['name'],
    );
    _departmentCodeController = TextEditingController(
      text: widget.initialDepartmentData['code'],
    );

    // Initialize selected manager (handle case where data might not be in the mock list)
    _selectedManager = widget.initialDepartmentData['manager'];
    if (_selectedManager != null &&
        !_availableManagers.contains(_selectedManager)) {
      // If the current manager is not in the list, we might reset it or add them temporarily
      _selectedManager = null;
    }
  }

  @override
  void dispose() {
    _departmentNameController.dispose();
    _departmentCodeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedDepartmentData = {
        'id': widget.initialDepartmentData['id'], // Crucial for database update
        'name': _departmentNameController.text,
        'code': _departmentCodeController.text,
        'manager': _selectedManager,
      };

      // TODO: Implement logic to update departmentData in your backend
      print("Department changes saved: $updatedDepartmentData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department updated successfully!')),
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
          'Are you sure you want to delete the department: ${widget.initialDepartmentData['name']}? This action cannot be undone.',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Department Deleted!')),
              );
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
        title: Text('Edit Department: ${widget.initialDepartmentData['name']}'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Department Name
              TextFormField(
                controller: _departmentNameController,
                decoration: const InputDecoration(
                  labelText: 'Department Name',
                  prefixIcon: Icon(Icons.business_center_outlined),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter department name' : null,
              ),
              const SizedBox(height: 16),

              // 2. Department Code
              TextFormField(
                controller: _departmentCodeController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Department Code/ID',
                  prefixIcon: Icon(Icons.tag),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Enter a department code' : null,
              ),
              const SizedBox(height: 16),

              // 3. Manager Assignment (Dropdown)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Assign Manager',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                value: _selectedManager,
                items: _availableManagers.map((String manager) {
                  return DropdownMenuItem<String>(
                    value: manager,
                    child: Text(manager),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedManager = newValue;
                  });
                },
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
                  'Delete Department',
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
