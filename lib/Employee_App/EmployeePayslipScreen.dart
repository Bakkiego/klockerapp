import 'package:flutter/material.dart';

class EmployeePayslipScreen extends StatefulWidget {
  const EmployeePayslipScreen({super.key});

  @override
  State<EmployeePayslipScreen> createState() => _EmployeePayslipScreenState();
}

class _EmployeePayslipScreenState extends State<EmployeePayslipScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- FIX: Added Scaffold for Material ancestor and AppBar for navigation ---
      appBar: AppBar(
        title: const Text('Payslips'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- LATEST PAYSLIP (FEATURED) ---
              const Text(
                "Latest Payslip",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const LatestPayslipCard(),

              const SizedBox(height: 32),

              // --- HISTORY LIST ---
              const Text(
                "Payment History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const PayslipHistoryList(),

              // Spacing at the bottom for better scroll feel
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class LatestPayslipCard extends StatelessWidget {
  const LatestPayslipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.2),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            "March 2026",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            "£2,850.00",
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Net Pay",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Divider(color: theme.dividerColor.withOpacity(0.1)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat("Gross", "£3,400"),
              _buildMiniStat("Tax", "-£450"),
              _buildMiniStat("NI", "-£100"),
            ],
          ),
          const SizedBox(height: 25),
          // --- ElevatatedButton works now because of the Scaffold ---
          ElevatedButton.icon(
            onPressed: () {
              // Action for download
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text("Download PDF"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

class PayslipHistoryList extends StatelessWidget {
  const PayslipHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> payslips = [
      {"month": "February 2026", "amount": "£2,850.00", "date": "28 Feb"},
      {"month": "January 2026", "amount": "£2,700.00", "date": "31 Jan"},
      {"month": "December 2025", "amount": "£3,100.00", "date": "24 Dec"},
    ];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: payslips.length,
      itemBuilder: (context, index) {
        final item = payslips[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              item['month']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Paid on ${item['date']}"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item['amount']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () {
              // Action for history tap
            },
          ),
        );
      },
    );
  }
}
