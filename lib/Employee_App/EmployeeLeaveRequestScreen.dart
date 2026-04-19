import 'package:flutter/material.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold is necessary here to provide the Material ancestor for InkWells/Buttons
      appBar: AppBar(
        title: const Text('Leave Requests'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- LEAVE BALANCE SUMMARY ---
              const LeaveBalanceSummary(),

              const SizedBox(height: 30),

              // --- ACTION BUTTON ---
              _buildNewRequestButton(context),

              const SizedBox(height: 40),

              const Text(
                "My Leave History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // --- LEAVE HISTORY LIST ---
              const LeaveHistoryList(),

              // Extra space at bottom to prevent the last card from feeling "stuck"
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewRequestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // This would navigate to your "Apply for Leave" form
        },
        icon: const Icon(Icons.add),
        label: const Text(
          "Request New Leave",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class LeaveBalanceSummary extends StatelessWidget {
  const LeaveBalanceSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ensure every card is wrapped in Expanded to take up equal width
        _buildBalanceCard("Annual", "12", Colors.blue),
        const SizedBox(width: 10),
        _buildBalanceCard("Sick", "5", Colors.red),
        const SizedBox(width: 10),
        _buildBalanceCard("Other", "2", Colors.orange),
      ],
    );
  }

  Widget _buildBalanceCard(String label, String days, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              days,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              "Days Left",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaveHistoryList extends StatelessWidget {
  const LeaveHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> leaveHistory = [
      {
        "type": "Annual",
        "date": "May 20 - May 22",
        "status": "Approved",
        "color": Colors.green,
      },
      {
        "type": "Sick",
        "date": "Apr 10",
        "status": "Pending",
        "color": Colors.orange,
      },
      {
        "type": "Personal",
        "date": "Mar 05",
        "status": "Rejected",
        "color": Colors.red,
      },
    ];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: leaveHistory.length,
      itemBuilder: (context, index) {
        final leave = leaveHistory[index];
        final Color statusColor = leave['color'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(Icons.beach_access, color: statusColor, size: 20),
            ),
            title: Text(
              leave['type'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(leave['date']),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                leave['status'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
