import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import '../../../supabase/repo/supabase_service.dart';

class EditSalaryRateScreen extends StatefulWidget {
  final Map<String, dynamic> initialSalaryData;
  const EditSalaryRateScreen({super.key, required this.initialSalaryData});

  @override
  State<EditSalaryRateScreen> createState() => _EditSalaryRateScreenState();
}

class _EditSalaryRateScreenState extends State<EditSalaryRateScreen> {
  final SupabaseService _service = SupabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _grossSalaryController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _allowancesController;
  late TextEditingController _taxNumberController = TextEditingController();
  // 🚀 MULTIPLE DEDUCTIONS STATE
  List<Map<String, dynamic>> _deductionsList = [];
  final TextEditingController _newDedNameController = TextEditingController();
  final TextEditingController _newDedValueController = TextEditingController();
  String _newDedType = 'fixed';

  String? _selectedPayrollType;
  bool _isSubmitting = false;

  final List<String> _payrollTypes = const [
    'Standard (Monthly)',
    'Hourly',
    'Contractor (Fixed)',
    'Commission Based',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPayrollType = widget.initialSalaryData['payrollType'];
    if (!_payrollTypes.contains(_selectedPayrollType))
      _selectedPayrollType = _payrollTypes.first;
    _taxNumberController = TextEditingController(
      text: widget.initialSalaryData['taxNumber'] ?? '',
    );
    final gross = widget.initialSalaryData['grossSalary']?.toString() ?? '';
    _grossSalaryController = TextEditingController(text: gross);
    _hourlyRateController = TextEditingController(text: gross);

    final allowances = widget.initialSalaryData['allowances']?.toString() ?? '';
    _allowancesController = TextEditingController(text: allowances);

    // 🚀 LOAD EXISTING DEDUCTIONS ARRAY FROM DB
    if (widget.initialSalaryData['rawDeductions'] != null) {
      _deductionsList = List<Map<String, dynamic>>.from(
        widget.initialSalaryData['rawDeductions'],
      );
    }
  }

  @override
  void dispose() {
    _grossSalaryController.dispose();
    _hourlyRateController.dispose();
    _allowancesController.dispose();
    _newDedNameController.dispose();
    _newDedValueController.dispose();
    super.dispose();
  }

  void _addDeduction() {
    if (_newDedNameController.text.trim().isEmpty ||
        _newDedValueController.text.trim().isEmpty)
      return;
    final val = double.tryParse(_newDedValueController.text) ?? 0.0;
    if (val <= 0) return;

    setState(() {
      _deductionsList.add({
        'name': _newDedNameController.text.trim(),
        'type': _newDedType,
        'value': val,
      });
      _newDedNameController.clear();
      _newDedValueController.clear();
    });
  }

  Future<void> _submitSalaryRate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        String rateText = _selectedPayrollType == 'Hourly'
            ? _hourlyRateController.text
            : _grossSalaryController.text;
        double baseRate = double.tryParse(rateText) ?? 0.00;
        double allowancesVal =
            double.tryParse(_allowancesController.text) ?? 0.0;

        await _service.upsertSalaryConfig(
          profileId: widget.initialSalaryData['id'],
          payrollType: _selectedPayrollType!,
          baseRate: baseRate,
          structuredDeductions:
              _deductionsList, // 🚀 Passes the modified array!
          allowances: allowancesVal,
          taxNumber: _taxNumberController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Salary Updated!'),
              backgroundColor: Color(0xFF00A36C),
            ),
          );
          Navigator.pop(context);
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<UserProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Salary: ${widget.initialSalaryData['name']}'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payroll Type',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                value: _selectedPayrollType,
                items: _payrollTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedPayrollType = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _selectedPayrollType == 'Hourly'
                    ? _hourlyRateController
                    : _grossSalaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _selectedPayrollType == 'Hourly'
                      ? 'Hourly Rate'
                      : 'Gross Salary',
                  prefixText: '$currency ',
                  prefixIcon: Icon(
                    _selectedPayrollType == 'Hourly'
                        ? Icons.schedule
                        : Icons.attach_money,
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              const Divider(),
              TextFormField(
                controller: _allowancesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Default Allowances (Optional)',
                  prefixText: '$currency ',
                  prefixIcon: const Icon(Icons.card_giftcard),
                ),
              ),
              const SizedBox(height: 16),

              // 🚀 ADD THIS TAX NUMBER FIELD:
              TextFormField(
                controller: _taxNumberController,
                decoration: const InputDecoration(
                  labelText: 'Income Tax Number (SARS)',
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),

              // 🚀 DEDUCTIONS CONFIGURATOR
              const Text(
                "Recurring Deductions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _newDedNameController,
                      decoration: const InputDecoration(
                        labelText: "Deduction Name",
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newDedValueController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Value",
                              filled: true,
                              fillColor: Colors.transparent,
                              prefixText: _newDedType == 'fixed'
                                  ? '$currency '
                                  : null,
                              suffixText: _newDedType == 'percentage'
                                  ? ' %'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text("Fixed"),
                          selected: _newDedType == 'fixed',
                          onSelected: (val) {
                            if (val) setState(() => _newDedType = 'fixed');
                          },
                        ),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text("%"),
                          selected: _newDedType == 'percentage',
                          onSelected: (val) {
                            if (val) setState(() => _newDedType = 'percentage');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addDeduction,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Deduction"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 🚀 CURRENT DEDUCTIONS LIST
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _deductionsList.length,
                itemBuilder: (context, index) {
                  final item = _deductionsList[index];
                  final isPercent = item['type'] == 'percentage';
                  return Card(
                    elevation: 0,
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.red.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isPercent ? 'Percentage-based' : 'Fixed amount',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPercent
                                ? "${item['value']}%"
                                : "$currency${item['value']}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () =>
                                setState(() => _deductionsList.removeAt(index)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitSalaryRate,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSubmitting ? 'Saving...' : 'Update Salary',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF00A36C),
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
