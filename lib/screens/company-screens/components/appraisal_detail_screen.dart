import 'package:flutter/material.dart';
import '../../../../supabase/repo/supabase_service.dart';

class AppraisalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appraisal;

  const AppraisalDetailScreen({super.key, required this.appraisal});

  @override
  State<AppraisalDetailScreen> createState() => _AppraisalDetailScreenState();
}

class _AppraisalDetailScreenState extends State<AppraisalDetailScreen> {
  final _feedbackController = TextEditingController();
  double _score = 3.0; // Default middle score
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if already completed
    if (widget.appraisal['comments'] != null) {
      _feedbackController.text = widget.appraisal['comments'];
    }
    if (widget.appraisal['score'] != null) {
      _score = (widget.appraisal['score'] as num).toDouble();
    }
  }

  Future<void> _completeAppraisal() async {
    setState(() => _isSaving = true);
    try {
      // 🚀 Pass the ID, the score, the comments, and update status to Completed
      await SupabaseService().updateAppraisal(
        appraisalId: widget.appraisal['id'],
        score: _score,
        comments: _feedbackController.text.trim(),
        status: 'Completed',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appraisal Completed!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Go back and trigger a refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeName =
        widget.appraisal['employee']?['full_name'] ?? 'Employee';
    final isCompleted = widget.appraisal['status'] == 'Completed';

    return Scaffold(
      appBar: AppBar(title: Text("$employeeName's Review")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00A36C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF00A36C)),
                  const SizedBox(width: 12),
                  Text(
                    widget.appraisal['review_period'] ?? 'Review',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "Overall Performance Score",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("1.0", style: TextStyle(color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: _score,
                    min: 1.0,
                    max: 5.0,
                    divisions: 8, // Allows half points like 3.5
                    label: _score.toStringAsFixed(1),
                    activeColor: const Color(0xFF00A36C),
                    onChanged: isCompleted
                        ? null
                        : (val) => setState(() => _score = val),
                  ),
                ),
                const Text("5.0", style: TextStyle(color: Colors.grey)),
              ],
            ),
            Center(
              child: Text(
                "Score: ${_score.toStringAsFixed(1)} / 5.0",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A36C),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              "Manager Comments & Feedback",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              enabled: !isCompleted,
              decoration: const InputDecoration(
                hintText:
                    "Enter constructive feedback, goals met, and areas for improvement...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 40),
            if (!isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _completeAppraisal,
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    _isSaving ? "Saving..." : "Finalize & Complete Appraisal",
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF00A36C),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
