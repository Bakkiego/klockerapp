import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚀 ADDED
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 ADDED

// Assuming you have an EditSalaryRateScreen similar to the Add screen logic
import 'edit_salaryrate_screen.dart';

class EmployeeSalaryDetailScreen extends StatelessWidget {
  // Receives the employee's data map from the SalaryScreen list
  final Map<String, dynamic> employeeDetails;

  const EmployeeSalaryDetailScreen({super.key, required this.employeeDetails});

  // Helper to determine text color for income
  Color _getSalaryColor() {
    return Colors.green.shade700;
  }

  // Helper to navigate to the edit screen
  void _navigateToEditSalary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the details to the Edit screen for pre-filling
        builder: (context) =>
            EditSalaryRateScreen(initialSalaryData: employeeDetails),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryColor = _getSalaryColor();
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 🚀 Grabbing the live currency from the provider!
    final currency = context.watch<UserProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text('${employeeDetails['name']}\'s Salary Details'),
        actions: [
          // Quick Edit button in the AppBar for easy access
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _navigateToEditSalary(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Prominent Salary Overview Card ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NET PAY',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // 🚀 CHANGED: Using dynamic currency
                      '$currency${employeeDetails['netSalary'] ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: salaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Chip(
                      label: Text(
                        employeeDetails['payrollType'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: Colors.lightGreen.shade100,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- 2. Action Button (The primary edit button) ---
            ElevatedButton.icon(
              onPressed: () => _navigateToEditSalary(context),
              icon: const Icon(Icons.rate_review),
              label: const Text(
                'Edit Salary Rate',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // --- 3. Detailed Information Section ---
            const Text(
              'Detailed Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            _buildDetailRow(
              icon: Icons.badge_outlined,
              label: 'Employee ID',
              value: employeeDetails['id'] ?? 'N/A',
            ),

            _buildDetailRow(
              icon: Icons.money_off,
              label: 'Gross Salary (Before Deductions)',
              // 🚀 CHANGED: Using dynamic currency
              value: '$currency${employeeDetails['grossSalary'] ?? '0.00'}',
            ),

            _buildDetailRow(
              icon: Icons.date_range,
              label: 'Last Updated Date',
              value: employeeDetails['lastUpdated'] ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  // Reusable widget to display a single detail row with an icon
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
