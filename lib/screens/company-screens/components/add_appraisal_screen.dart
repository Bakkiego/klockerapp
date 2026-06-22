import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';

class AddAppraisalScreen extends StatefulWidget {
  const AddAppraisalScreen({super.key});

  @override
  State<AddAppraisalScreen> createState() => _AddAppraisalScreenState();
}

class _AddAppraisalScreenState extends State<AddAppraisalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewPeriodController = TextEditingController();

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
      // Re-using the getTeamMembers method we made in the previous step!
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

  Future<void> _initiateAppraisal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        await SupabaseService().createAppraisal(
          employeeId: _selectedEmployeeId!,
          reviewPeriod: _reviewPeriodController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appraisal Draft Created!'),
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
      appBar: AppBar(title: const Text('Initiate Appraisal')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    "Select Employee",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded:
                        true, // 🚀 1. Forces dropdown to obey screen width
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                    ),
                    hint: const Text("Choose Team Member..."),
                    value: _selectedEmployeeId,
                    items: _employees
                        .map(
                          (emp) => DropdownMenuItem<String>(
                            value: emp['id'],
                            child: Text(
                              "${emp['full_name']} (${emp['job_title'] ?? 'Staff'})",
                              overflow: TextOverflow
                                  .ellipsis, // 🚀 2. Adds "..." if too long
                              maxLines: 1, // 🚀 3. Keeps it on one line
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedEmployeeId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Review Period",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reviewPeriodController,
                    decoration: const InputDecoration(
                      hintText: "e.g., Annual Review 2026, Q3 Probation",
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _initiateAppraisal,
                    icon: const Icon(Icons.edit_document),
                    label: Text(
                      _isSubmitting
                          ? 'Starting Draft...'
                          : 'Start Appraisal Draft',
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
