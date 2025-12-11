import 'package:flutter/material.dart';

import 'components/add_salary_screen.dart';
import 'components/employee_salary_detail_screen.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final List<Map<String, String>> _mockEmployees = const [
    {
      "id": "#EMP0000001",
      "name": "Jessica",
      "payrollType": "Standard",
      "grossSalary": "50,000.00",
      "netSalary": "49,700.00",
    },
    {
      "id": "#EMP0000002",
      "name": "Raza",
      "payrollType": "Hourly",
      "grossSalary": "1,500.00",
      "netSalary": "1,450.00",
    },
    {
      "id": "#EMP0000003",
      "name": "Milo",
      "payrollType": "Contractor",
      "grossSalary": "12,000.00",
      "netSalary": "12,000.00",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Employee Salary')),

      body: Column(
        children: [
          // 1. Search Bar Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: "Search by Name or ID...",
              trailing: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.sort),
                ), // Sort Icon
              ],
            ),
          ),

          // 2. The Scrollable List of Employee Cards
          Expanded(
            child: ListView.builder(
              itemCount: _mockEmployees.length,
              itemBuilder: (context, index) {
                final employee = _mockEmployees[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeSalaryDetailScreen(
                          employeeDetails: employee,
                        ),
                      ),
                    );
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
                                    employee['name']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    employee['id']!,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  // Chip for Payroll Type
                                  Chip(
                                    label: Text(employee['payrollType']!),
                                    padding: EdgeInsets.zero,
                                    labelStyle: const TextStyle(fontSize: 12),
                                    backgroundColor: Colors.lightGreen.shade100,
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
                                  "\$${employee['netSalary']!}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: Colors.green, // Income/Salary color
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

      // 3. Floating Action Button (FAB) for adding new employees or running payroll
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AddSalaryRateScreen(), // <-- Added Navigation
            ),
          );
        },
        child: const Icon(Icons.person_add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
