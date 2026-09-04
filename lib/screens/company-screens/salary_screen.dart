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
      if (mounted) {
        setState(() {
          _employees = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching payroll: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        // 🚀 SHOWS THE EXACT ERROR ON SCREEN
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Database Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final canManageSalaryConfigs = userProvider.can('manage_salary_configs');
    final currency = userProvider.currencySymbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Employee Salary')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: "Search by Name or ID...",
              trailing: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.sort)),
              ],
            ),
          ),

          // 🚀 THE FIX: Handles Loading and Empty States Correctly
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : _employees.isEmpty
                ? const Center(
                    child: Text(
                      "No employees or data found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      final String email = (employee['email'] ?? '')
                          .toString()
                          .trim();

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmployeeSalaryDetailScreen(
                                employeeDetails: employee,
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchPayrollData();
                          }
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          email.isEmpty
                                              ? 'No email on file'
                                              : email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Chip(
                                          label: Text(employee['payrollType']!),
                                          padding: EdgeInsets.zero,
                                          labelStyle: const TextStyle(
                                            fontSize: 12,
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      ],
                                    ),
                                  ),
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
      floatingActionButton: canManageSalaryConfigs
          ? FloatingActionButton(
              heroTag: null,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSalaryRateScreen(),
                  ),
                );
                if (result == true) {
                  _fetchPayrollData();
                }
              },
              child: const Icon(Icons.person_add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
