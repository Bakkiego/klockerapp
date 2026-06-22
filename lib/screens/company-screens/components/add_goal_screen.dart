import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedEmployeeId;

  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchTeam();
  }

  Future<void> _fetchTeam() async {
    try {
      final team = await SupabaseService().getTeamMembers();
      if (mounted)
        setState(() {
          _employees = team;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGoal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        await SupabaseService().addGoal(
          title: _titleController.text.trim(),
          employeeId: _selectedEmployeeId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal Created!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Goal')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Title (e.g., Increase Sales by 10%)',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Assign To (Optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    hint: const Text("Company-Wide Goal (Unassigned)"),
                    value: _selectedEmployeeId,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("Company-Wide / Department"),
                      ),
                      ..._employees.map(
                        (emp) => DropdownMenuItem<String>(
                          value: emp['id'],
                          child: Text("${emp['full_name']}"),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedEmployeeId = val),
                  ),

                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitGoal,
                    icon: const Icon(Icons.rocket_launch),
                    label: Text(
                      _isSubmitting ? 'Creating...' : 'Create Goal',
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
}
