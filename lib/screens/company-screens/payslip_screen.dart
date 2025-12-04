import 'package:flutter/material.dart';
import '../employee-screens/components/time_management_components/custom_date_picker.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final List<Map<String, String>> _mockPayslips = const [
    {
      "id": "#EMP0000001",
      "name": "Jessica",
      "payrollType": "Standard",
      "salary": "50,000.00",
      "netSalary": "49,700.00",
      "status": "Paid",
    },
    {
      "id": "#EMP0000002",
      "name": "Raza",
      "payrollType": "Hourly",
      "salary": "1,500.00",
      "netSalary": "1,450.00",
      "status": "Pending",
    },
    {
      "id": "#EMP0000003",
      "name": "Milo",
      "payrollType": "Contractor",
      "salary": "12,000.00",
      "netSalary": "12,000.00",
      "status": "Failed",
    },
  ];

  // State for the selected period (Mocking DEC 2025 based on web UI)
  String _selectedMonth = "DEC";
  String _selectedYear = "2025";

  // Helper to get the chip color based on the status
  Color _getStatusColor(String status) {
    switch (status) {
      case "Paid":
        return Colors.green.shade600;
      case "Pending":
        return Colors.orange.shade600;
      case "Failed":
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Employee Payslip')),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Month/Year Selector and Bulk Action Buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Combined Period Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payroll Period',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CustomDatePicker(),
                  ],
                ),

                const SizedBox(height: 12),

                // Export and Bulk Payment Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.file_download),
                        label: const Text(
                          'Export',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ), // Export
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.payment),
                        label: const Text(
                          'Bulk Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ), // Bulk Payment
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Highlighted action
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SearchBar(
              hintText: "Search by Employee Name or ID...",
              trailing: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
              ],
            ),
          ),

          // 3. The Scrollable List of Payslip Cards
          Expanded(
            child: ListView.builder(
              itemCount: _mockPayslips.length,
              itemBuilder: (context, index) {
                final employee = _mockPayslips[index];
                final statusColor = _getStatusColor(employee['status']!);

                return GestureDetector(
                  onTap: () {
                    // Navigate to Payslip Detail Screen (View Action)
                    print("Tapped on employee: ${employee['name']!}");
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Side: Name, ID, Payroll Type
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    employee['name']!, // NAME
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    employee['id']!, // EMPLOYEE ID
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  // Chip for Payroll Status
                                  Chip(
                                    label: Text(
                                      employee['status']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor:
                                        statusColor, // Status color coding
                                    padding: EdgeInsets.zero,
                                    labelStyle: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // Right Side: Net Salary
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "NET SALARY",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "\$${employee['netSalary']!}", // NET SALARY
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // No FAB needed here, as primary actions are the Bulk Payment/Export buttons.
    );
  }
}
