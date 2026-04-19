import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/custom_date_picker.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  State<EmployeeAttendanceScreen> createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    // --- FIX: Wrapped in Scaffold to provide the Material ancestor ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomDatePicker(),
              const SizedBox(height: 24),
              const EmployeePersonalSummary(),
              const SizedBox(height: 32),
              const Text(
                "My Attendance History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const EmployeeAttendanceLogs(),
            ],
          ),
        ),
      ),
    );
  }
}

class EmployeePersonalSummary extends StatelessWidget {
  const EmployeePersonalSummary({super.key});

  @override
  Widget build(BuildContext context) {
    // Using the same Wrap/Row logic as HR but with personal metrics
    return Row(
      children: [
        _buildMetricCard(
          context,
          "Hours",
          "156.5",
          Icons.access_time_filled,
          Colors.blue,
        ),
        const SizedBox(width: 10),
        _buildMetricCard(context, "Overtime", "8.2", Icons.bolt, Colors.purple),
        const SizedBox(width: 10),
        _buildMetricCard(
          context,
          "Punctual",
          "95%",
          Icons.verified_user,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeAttendanceLogs extends StatelessWidget {
  const EmployeeAttendanceLogs({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for the specific employee
    final List<Map<String, String>> myLogs = [
      {"date": "Apr 17", "in": "09:02", "out": "17:05", "status": "Present"},
      {"date": "Apr 16", "in": "09:15", "out": "17:00", "status": "Late"},
      {"date": "Apr 15", "in": "08:58", "out": "16:55", "status": "Present"},
    ];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: myLogs.length,
      itemBuilder: (context, index) {
        final log = myLogs[index];
        final bool isLate = log['status'] == "Late";

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isLate ? Colors.orange : Colors.green)
                  .withOpacity(0.2),
              child: Icon(
                isLate ? Icons.timer_outlined : Icons.check,
                color: isLate ? Colors.orange : Colors.green,
                size: 20,
              ),
            ),
            title: Text(
              log['date']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("In: ${log['in']}  •  Out: ${log['out']}"),
            trailing: Text(
              log['status']!,
              style: TextStyle(
                color: isLate ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
