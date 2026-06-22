import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  double _score = 5.0; // Default middle score

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

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        await SupabaseService().addPerformanceReview(
          employeeId: _selectedEmployeeId!,
          score: _score,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review Logged!'),
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
      appBar: AppBar(title: const Text('Log Performance Review')),
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
                    "Select Team Member",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                    ),
                    hint: const Text("Choose Employee..."),
                    value: _selectedEmployeeId,
                    items: _employees
                        .map(
                          (emp) => DropdownMenuItem<String>(
                            value: emp['id'],
                            child: Text(
                              "${emp['full_name']} (${emp['job_title'] ?? 'Staff'})",
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedEmployeeId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    "Performance Score (1-10)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Score Slider
                  Row(
                    children: [
                      const Text(
                        "1",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Slider(
                          value: _score,
                          min: 1,
                          max: 10,
                          divisions: 18, // Allows for .5 increments (e.g. 8.5)
                          label: _score.toStringAsFixed(1),
                          activeColor: const Color(0xFF00A36C),
                          onChanged: (val) => setState(() => _score = val),
                        ),
                      ),
                      const Text(
                        "10",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      _score.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A36C),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReview,
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      _isSubmitting ? 'Saving...' : 'Submit Review',
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
