import 'package:flutter/material.dart';

class AddSalaryRateScreen extends StatefulWidget {
  const AddSalaryRateScreen({super.key});

  @override
  State<AddSalaryRateScreen> createState() => _AddSalaryRateScreenState();
}

class _AddSalaryRateScreenState extends State<AddSalaryRateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for core fields
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _grossSalaryController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _effectiveDateController =
      TextEditingController();

  // Controllers for additional fields
  final TextEditingController _deductionsController = TextEditingController();
  final TextEditingController _allowancesController = TextEditingController();
  final TextEditingController _overtimeHoursController =
      TextEditingController();
  final TextEditingController _additionalPaymentsController =
      TextEditingController();

  // State for selection fields
  String? _selectedPayrollType;

  // Mock lists
  final List<String> _payrollTypes = const [
    'Standard (Monthly)',
    'Hourly',
    'Contractor (Fixed)',
    'Commission Based',
  ];
  final List<String> _mockEmployees = const [
    'Jessica (#EMP0000001)',
    'Raza (#EMP0000002)',
    'Milo (#EMP0000003)',
  ];

  @override
  void initState() {
    super.initState();
    _effectiveDateController.text = _formatDate(DateTime.now());
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _grossSalaryController.dispose();
    _hourlyRateController.dispose();
    _effectiveDateController.dispose();
    _deductionsController.dispose();
    _allowancesController.dispose();
    _overtimeHoursController.dispose();
    _additionalPaymentsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _effectiveDateController.text = _formatDate(picked);
      });
    }
  }

  void _submitSalaryRate() {
    if (_formKey.currentState!.validate()) {
      final newSalaryData = {
        'employee': _employeeNameController.text,
        'type': _selectedPayrollType,
        'grossSalary': _grossSalaryController.text,
        'hourlyRate': _hourlyRateController.text,
        'effectiveDate': _effectiveDateController.text,
        'deductions': _deductionsController.text,
        'allowances': _allowancesController.text,
        'overtimeHours': _overtimeHoursController.text,
        'additionalPayments': _additionalPaymentsController.text,
      };

      // UI Foundation complete: Print data instead of saving
      print("New Salary Rate Submitted: $newSalaryData");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salary rate UI data collected!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        Theme.of(
          context,
        ).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
        Colors.blue;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Salary Rate')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Employee Selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Employee',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                value: _employeeNameController.text.isNotEmpty
                    ? _employeeNameController.text
                    : null,
                items: _mockEmployees.map((String employee) {
                  return DropdownMenuItem<String>(
                    value: employee,
                    child: Text(employee),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _employeeNameController.text = newValue!;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Select an employee'
                    : null,
              ),
              const SizedBox(height: 16),

              // 2. Payroll Type Selection
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

              // 3. Gross Salary / Hourly Rate (Conditional Visibility)
              TextFormField(
                controller: _selectedPayrollType == 'Hourly'
                    ? _hourlyRateController
                    : _grossSalaryController,
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
                  if (value == null || value.isEmpty)
                    return 'Enter the required amount';
                  if (double.tryParse(value) == null)
                    return 'Enter a valid number';
                  return null;
                },
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

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- ADDITIONAL PAYROLL COMPONENTS ---

              // 5. Deductions (e.g., taxes, insurance)
              TextFormField(
                controller: _deductionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Deductions (Optional)',
                  hintText: 'e.g., 500.00',
                  prefixText: '\$',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Allowances (Optional)
              TextFormField(
                controller: _allowancesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Allowances (Optional)',
                  hintText: 'e.g., 250.00 (e.g., travel, housing)',
                  prefixText: '\$',
                  prefixIcon: Icon(Icons.card_giftcard),
                ),
              ),
              const SizedBox(height: 16),

              // 7. Overtime Hours/Pay (Optional)
              TextFormField(
                controller: _overtimeHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Overtime Hours/Amount (Optional)',
                  hintText: 'e.g., 10 hours or 150.00',
                  prefixIcon: Icon(Icons.timer),
                ),
              ),
              const SizedBox(height: 16),

              // 8. Additional Payments (Optional)
              TextFormField(
                controller: _additionalPaymentsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Other Payments/Bonus (Optional)',
                  hintText: 'e.g., 1000.00 (e.g., bonus, commission)',
                  prefixText: '\$',
                  prefixIcon: Icon(Icons.add_shopping_cart),
                ),
              ),

              const SizedBox(height: 48),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitSalaryRate,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Salary Rate',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
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
