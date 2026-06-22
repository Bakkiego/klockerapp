import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';

class EditPayerScreen extends StatefulWidget {
  final Map<String, dynamic> initialPayerData;

  const EditPayerScreen({super.key, required this.initialPayerData});

  @override
  State<EditPayerScreen> createState() => _EditPayerScreenState();
}

class _EditPayerScreenState extends State<EditPayerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bankNameController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialPayerData['name']?.toString() ?? '',
    );
    _bankNameController = TextEditingController(
      text: widget.initialPayerData['bank_name']?.toString() ?? '',
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        await SupabaseService().updatePayer(
          id: widget.initialPayerData['id'],
          name: _nameController.text.trim(),
          bankName: _bankNameController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payer updated!'),
              backgroundColor: Colors.green,
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this Payer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              setState(() => _isSubmitting = true);
              try {
                await SupabaseService().deletePayer(
                  widget.initialPayerData['id'],
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payer Deleted!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
              } finally {
                if (mounted) setState(() => _isSubmitting = false);
              }
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
      appBar: AppBar(title: const Text('Edit Payer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Payer Name',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
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
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _showDeleteConfirmation,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Delete Payer',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
