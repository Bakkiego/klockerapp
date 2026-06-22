import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';

import '../../supabase/repo/supabase_service.dart';
import 'components/add_salary_screen.dart';
import 'components/employee_salary_detail_screen.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayrollData();
  }

  Future<void> _fetchPayrollData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getPayrollOverview();
      setState(() {
        _employees = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching payroll: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 THE BOUNCER: Check if they are allowed to manage salary configs
    final userProvider = context.watch<UserProvider>();
    final canManageSalaryConfigs = userProvider.can('manage_salary_configs');

    // Grab the live currency symbol from settings!
    final currency = userProvider.currencySymbol;

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
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final employee = _employees[index];
                final String rawId = employee['id']?.toString() ?? '';
                final String displayId = rawId.length > 5
                    ? '${rawId.substring(0, 5)}...'
                    : rawId;

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
                                    'ID: #$displayId',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Chip for Payroll Type
                                  Chip(
                                    label: Text(employee['payrollType']!),
                                    padding: EdgeInsets.zero,
                                    labelStyle: const TextStyle(fontSize: 12),
                                    backgroundColor: Colors.green,
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
                                  "$currency${employee['netSalary']!}",
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

      // 🚀 GRANULAR SECURITY: Hide the FAB if they lack the configuration permission
      floatingActionButton: canManageSalaryConfigs
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSalaryRateScreen(),
                  ),
                );
                _fetchPayrollData();
              },
              child: const Icon(Icons.person_add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
