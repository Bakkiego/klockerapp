import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';

class AddPayerScreen extends StatefulWidget {
  const AddPayerScreen({super.key});

  @override
  State<AddPayerScreen> createState() => _AddPayerScreenState();
}

class _AddPayerScreenState extends State<AddPayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitNewPayer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        await SupabaseService().addPayer(
          name: _nameController.text.trim(),
          bankName: _bankNameController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payer added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Trigger refresh
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Payer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Payer Name (e.g., Client/Company)',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) => v!.isEmpty ? 'Enter payer name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name / Source',
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitNewPayer,
              icon: const Icon(Icons.save),
              label: Text(
                _isSubmitting ? 'Saving...' : 'Add Payer',
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
