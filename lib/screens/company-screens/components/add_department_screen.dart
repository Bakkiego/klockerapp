import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';

class AddDepartmentScreen extends StatefulWidget {
  const AddDepartmentScreen({super.key});

  @override
  State<AddDepartmentScreen> createState() => _AddDepartmentScreenState();
}

class _AddDepartmentScreenState extends State<AddDepartmentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _managerController = TextEditingController();

  String? _selectedBranchId;
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      // 🚀 Pulling the real branches from the database!
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

  Future<void> _submitNewDepartment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        await SupabaseService().addDepartment(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          branchId: _selectedBranchId!,
          managerName: _managerController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Department Added!'),
              backgroundColor: Color(0xFF00A36C),
            ),
          );
          Navigator.pop(context, true); // Go back and refresh
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
      appBar: AppBar(title: const Text('Add New Department')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _branches.isEmpty
          ? _buildNoBranchesState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Department Name (e.g. Sales)',
                      prefixIcon: Icon(Icons.business_center),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Department Code (e.g. SL-01)',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // 🚀 Dynamic Branch Selection 🚀
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
                    onPressed: _isSubmitting ? null : _submitNewDepartment,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _isSubmitting ? 'Saving...' : 'Save Department',
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
    );
  }

  Widget _buildNoBranchesState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              "No Branches Found",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "You must create at least one Branch before you can create a Department.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
