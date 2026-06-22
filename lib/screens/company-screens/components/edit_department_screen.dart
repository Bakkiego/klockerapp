import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';

class EditDepartmentScreen extends StatefulWidget {
  final Map<String, dynamic> initialDepartmentData;

  const EditDepartmentScreen({super.key, required this.initialDepartmentData});

  @override
  State<EditDepartmentScreen> createState() => _EditDepartmentScreenState();
}

class _EditDepartmentScreenState extends State<EditDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _managerController;

  String? _selectedBranchId;
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialDepartmentData['name']?.toString() ?? '',
    );
    _codeController = TextEditingController(
      text: widget.initialDepartmentData['code']?.toString() ?? '',
    );
    _managerController = TextEditingController(
      text: widget.initialDepartmentData['manager_name']?.toString() ?? '',
    );
    _selectedBranchId = widget.initialDepartmentData['branch_id']?.toString();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      final branches = await SupabaseService().getAdminBranches();
      if (mounted)
        setState(() {
          _branches = branches;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        await SupabaseService().updateDepartment(
          id: widget.initialDepartmentData['id'],
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          branchId: _selectedBranchId!,
          managerName: _managerController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Department Updated!'),
              backgroundColor: Color(0xFF00A36C),
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
      builder: (c) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this department?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              setState(() => _isSubmitting = true);
              try {
                await SupabaseService().deleteDepartment(
                  widget.initialDepartmentData['id'],
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Department Deleted!'),
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
      appBar: AppBar(title: const Text('Edit Department')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Department Name',
                      prefixIcon: Icon(Icons.business_center),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Department Code',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Assign to Branch',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    value: _selectedBranchId,
                    items: _branches
                        .map(
                          (branch) => DropdownMenuItem<String>(
                            value: branch['id'],
                            child: Text(branch['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBranchId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _managerController,
                    decoration: const InputDecoration(
                      labelText: 'Manager Name (Optional)',
                      prefixIcon: Icon(Icons.person),
                    ),
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
                      backgroundColor: const Color(0xFF00A36C),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _showDeleteConfirmation,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete Department',
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
