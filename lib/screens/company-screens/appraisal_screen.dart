import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';
import 'components/add_appraisal_screen.dart';
import 'components/appraisal_detail_screen.dart'; // Ensure you create this next!

class AppraisalScreen extends StatefulWidget {
  const AppraisalScreen({super.key});

  @override
  State<AppraisalScreen> createState() => _AppraisalScreenState();
}

class _AppraisalScreenState extends State<AppraisalScreen> {
  List<Map<String, dynamic>> _appraisals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppraisals();
  }

  Future<void> _fetchAppraisals() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getAppraisals();
      if (mounted)
        setState(() {
          _appraisals = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Formal Appraisals",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _appraisals.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchAppraisals,
              color: const Color(0xFF00A36C),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _appraisals.length,
                itemBuilder: (context, index) {
                  // 🚀 Cast it explicitly to Map<String, dynamic>
                  final Map<String, dynamic> appraisal = _appraisals[index];

                  // Safely extract joined employee name
                  final employeeName =
                      appraisal['employee']?['full_name'] ?? 'Unknown Employee';

                  return _appraisalCard(
                    context,
                    employeeName,
                    appraisal['review_period'] ?? 'Review',
                    appraisal['status'] ?? 'Draft',
                    appraisal, // 🚀 NEW: We must pass the raw appraisal object down into the card!
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAppraisalScreen()),
          );
          if (result == true) _fetchAppraisals();
        },
        backgroundColor: const Color(0xFF00A36C),
        icon: const Icon(Icons.assignment, color: Colors.white),
        label: const Text(
          "New Appraisal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _appraisalCard(
    BuildContext context,
    String employee,
    String reviewType,
    String status,
    Map<String, dynamic> appraisal, // 🚀 NEW PARAMETER HERE
  ) {
    final theme = Theme.of(context);

    // Dynamic coloring based on status
    Color statusColor = Colors.orange;
    if (status == 'Completed') statusColor = Colors.green;
    if (status == 'Draft') statusColor = Colors.grey.shade600;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF00A36C),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          employee,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(reviewType),
            const SizedBox(height: 5),
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // 🚀 Now it has the object it needs to navigate!
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppraisalDetailScreen(appraisal: appraisal),
            ),
          );

          if (result == true) {
            _fetchAppraisals(); // Refresh list on return
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Appraisals Yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Start a formal review for your team.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
