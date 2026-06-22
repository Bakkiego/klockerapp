import 'package:flutter/material.dart';

class AttendanceSummary extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const AttendanceSummary({super.key, required this.records});

  // 🚀 THE FIX: Helper method to count unique employees, not total shifts
  int _countUnique(String status) {
    return records
        .where((r) => r['status'] == status)
        // Try to use a unique ID like profile_id or employee_id. Fall back to name.
        .map((r) => r['profile_id'] ?? r['employee_id'] ?? r['name'])
        .toSet() // This is the magic part: it removes duplicate employees
        .length;
  }

  @override
  Widget build(BuildContext context) {
    // We now use the smart counter to get unique headcounts
    final presentCount = _countUnique('Present');
    final lateCount = _countUnique('Late');
    final absentCount = _countUnique('Absent');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSummaryCard(
                "Present",
                presentCount.toString(),
                Colors.green,
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                "Late",
                lateCount.toString(),
                Colors.orange,
                Icons.history_toggle_off,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                "Absent",
                absentCount.toString(),
                Colors.red,
                Icons.do_not_disturb_on_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
