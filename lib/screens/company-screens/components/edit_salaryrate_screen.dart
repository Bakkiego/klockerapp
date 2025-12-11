import 'package:flutter/material.dart';

class EditSalaryRateScreen extends StatefulWidget {
  // Receives the existing employee's salary data
  final Map<String, String> initialSalaryData;

  const EditSalaryRateScreen({super.key, required this.initialSalaryData});

  @override
  State<EditSalaryRateScreen> createState() => _EditSalaryRateScreenState();
}

class _EditSalaryRateScreenState extends State<EditSalaryRateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _employeeNameController;
  late TextEditingController _grossSalaryController;
  late TextEditingController _netSalaryController;
  late TextEditingController _effectiveDateController;

  // State for selection fields
  late String? _selectedPayrollType;

  // Mock lists
  final List<String> _payrollTypes = const [
    'Standard (Monthly)',
    'Hourly',
    'Contractor (Fixed)',
    'Commission Based',
  ];

  // Note: Since this is an edit screen, we display the name/ID but usually don't let
  // the user change the employee itself. We just pass the name back for display purposes.
  late String _employeeIdName;

  // Helper to remove formatting for controllers
  String _cleanAmount(String? amount) {
    if (amount == null) return '';
    // Removes commas, currency symbols, and spaces
    return amount.replaceAll(',', '').replaceAll('\$', '').trim();
  }

  @override
  void initState() {
    super.initState();

    // Initialize data from the passed map
    _employeeIdName =
        '${widget.initialSalaryData['name']} (${widget.initialSalaryData['id']})';
    _selectedPayrollType = widget.initialSalaryData['payrollType'];

    // Initialize controllers with cleaned data
    _employeeNameController = TextEditingController(
      text: widget.initialSalaryData['name'],
    );
    _grossSalaryController = TextEditingController(
      text: _cleanAmount(widget.initialSalaryData['grossSalary']),
    );
    _netSalaryController = TextEditingController(
      text: _cleanAmount(widget.initialSalaryData['netSalary']),
    );

    // Assume an 'effectiveDate' field exists in the data map for a real application
    _effectiveDateController = TextEditingController(
      text: widget.initialSalaryData['effectiveDate'] ?? '2025-01-01',
    );

    // Ensure the payroll type is one of the valid options, otherwise default to the first
    if (!_payrollTypes.contains(_selectedPayrollType)) {
      _selectedPayrollType = _payrollTypes.first;
    }
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _grossSalaryController.dispose();
    _netSalaryController.dispose();
    _effectiveDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_effectiveDateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _effectiveDateController.text = _formatDate(picked);
      });
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedSalaryData = {
        'id': widget.initialSalaryData['id'], // Employee ID
        'type': _selectedPayrollType,
        'grossSalary': _grossSalaryController.text,
        'netSalary': _netSalaryController
            .text, // Often calculated, but editable here for flexibility
        'effectiveDate': _effectiveDateController.text,
      };

      // TODO: Implement logic to update salary data in your backend
      print("Salary Rate Updated: $updatedSalaryData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salary rate updated successfully!')),
      );
      // Pop twice: back from Edit -> Detail -> List
      Navigator.popUntil(
        context,
        (route) => route.isFirst || route.settings.name == '/salaryList',
      );
      // A more robust navigation would be needed here depending on your app structure
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Salary Deletion'),
        content: Text(
          'Are you sure you want to delete the current salary record for ${widget.initialSalaryData['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual salary record deletion logic
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to the detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Salary Record Deleted!')),
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
    final primaryColor =
        Theme.of(
          context,
        ).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
        Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Salary Rate: ${widget.initialSalaryData['name']}'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display Employee Name (Non-editable)
              ListTile(
                leading: const Icon(Icons.person, color: Colors.indigo),
                title: Text(
                  _employeeIdName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Employee cannot be changed here.'),
              ),
              const Divider(),
              const SizedBox(height: 16),

              // 1. Payroll Type Selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payroll Type',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                value: _selectedPayrollType,
                items: _payrollTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPayrollType = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select a payroll type' : null,
              ),
              const SizedBox(height: 16),

              // 2. Gross Salary / Hourly Rate
              TextFormField(
                controller:
                    _grossSalaryController, // Reuse controller for Gross/Hourly
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _selectedPayrollType == 'Hourly'
                      ? 'Hourly Rate'
                      : 'Gross Salary (Annual/Fixed)',
                  prefixText: '\$',
                  prefixIcon: Icon(
                    _selectedPayrollType == 'Hourly'
                        ? Icons.schedule
                        : Icons.attach_money,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter the amount';
                  if (double.tryParse(value) == null)
                    return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Net Salary (Optional: Can be calculated but included for completeness)
              TextFormField(
                controller: _netSalaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Net Salary (After Deductions)',
                  prefixText: '\$',
                  prefixIcon: Icon(Icons.paid_outlined),
                ),
                // Validation can be complex here; simple number check for now
                validator: (value) =>
                    (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null)
                    ? 'Enter a valid number'
                    : null,
              ),
              const SizedBox(height: 16),

              // 4. Effective Date
              TextFormField(
                controller: _effectiveDateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(
                  labelText: 'Effective Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Select effective date' : null,
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
                  'Delete Salary Record',
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
