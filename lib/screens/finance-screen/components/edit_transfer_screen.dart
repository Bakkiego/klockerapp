import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED
import '../../../supabase/repo/supabase_service.dart';

class EditTransferScreen extends StatefulWidget {
  final Map<String, dynamic> initialTransferData;

  const EditTransferScreen({super.key, required this.initialTransferData});

  @override
  State<EditTransferScreen> createState() => _EditTransferScreenState();
}

class _EditTransferScreenState extends State<EditTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _refController;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController(
      text: widget.initialTransferData['ref']?.toString() ?? '',
    );

    try {
      final dateStr = widget.initialTransferData['transfer_date']?.toString();
      _selectedDate = dateStr != null
          ? DateTime.parse(dateStr)
          : DateTime.now();
    } catch (_) {
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
        await SupabaseService().updateFinancialTransfer(
          id: widget.initialTransferData['id'],
          date: formattedDate,
          ref: _refController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Updated successfully!'),
              backgroundColor: Colors.blue,
            ),
          );
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
    // 🚀 Grabs the live currency symbol from settings!
    final currency = context.watch<UserProvider>().currencySymbol;

    final amountStr =
        widget.initialTransferData['amount']?.toString() ?? '0.00';
    final fromAccount =
        widget.initialTransferData['from_account']?['name'] ?? 'Account';
    final toAccount =
        widget.initialTransferData['to_account']?['name'] ?? 'Account';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transfer Details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Locked Ledger Data Display
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "LOCKED LEDGER DATA",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Amount"),
                      Text(
                        // 🚀 CHANGED: Using dynamic currency
                        "$currency$amountStr",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("From"),
                      Text(
                        fromAccount,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("To"),
                      Text(
                        toAccount,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Editable Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Editable Ref
            TextFormField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: 'Reference #',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _saveChanges,
              icon: const Icon(Icons.save),
              label: Text(
                _isSubmitting ? 'Saving...' : 'Save Changes',
                style: const TextStyle(fontSize: 18),
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
    );
  }
}
