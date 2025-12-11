import 'package:flutter/material.dart';

class AddDepartmentScreen extends StatefulWidget {
  const AddDepartmentScreen({super.key});

  @override
  State<AddDepartmentScreen> createState() => _AddDepartmentScreenState();
}

class _AddDepartmentScreenState extends State<AddDepartmentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for Department details
  final TextEditingController _departmentNameController =
      TextEditingController();
  final TextEditingController _departmentCodeController =
      TextEditingController();

  // State for selection fields (e.g., Department Manager)
  String? _selectedManager;

  // Mock list of potential managers
  final List<String> _availableManagers = const [
    'Sarah Connor',
    'John Smith',
    'Linda Ray',
    'Michael Chen',
  ];

  @override
  void dispose() {
    _departmentNameController.dispose();
    _departmentCodeController.dispose();
    super.dispose();
  }

  void _submitNewDepartment() {
    if (_formKey.currentState!.validate()) {
      final newDepartmentData = {
        'name': _departmentNameController.text,
        'code': _departmentCodeController.text,
        'manager': _selectedManager,
      };

      // TODO: Implement logic to save newDepartmentData to your backend
      print("New Department Submitted: $newDepartmentData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department added successfully!')),
      );
      Navigator.pop(context); // Go back to the main list
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme's primary color for styling consistency
    final primaryColor =
        Theme.of(
          context,
        ).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
        Colors.blue;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Department')),
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
                  labelText: 'Department Name (e.g., Marketing, HR)',
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
                  // Style the border based on the app's theme
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
                // Optional: Manager assignment might not be required initially
                // validator: (value) => value == null ? 'Select a manager' : null,
              ),

              const SizedBox(height: 48),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitNewDepartment,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save New Department',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryColor,
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
