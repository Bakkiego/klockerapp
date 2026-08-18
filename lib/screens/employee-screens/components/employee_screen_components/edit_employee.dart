import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../models/app_enums.dart';
import '../../../../supabase/repo/supabase_service.dart';
import 'employee_tile.dart';
import 'edit_employee_details_screen.dart';

class EditEmployee extends StatefulWidget {
  const EditEmployee({super.key});

  @override
  State<EditEmployee> createState() => _EditEmployeeState();
}

class _EditEmployeeState extends State<EditEmployee> {
  final SupabaseService _service = SupabaseService();
  Future<List<Map<String, dynamic>>>? _employeesFuture;

  @override
  void initState() {
    super.initState();
    _employeesFuture = _service.getEmployees();
  }

  void _refreshList() {
    setState(() {
      _employeesFuture = _service.getEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
      child: Column(
        children: [
          // Instruction Header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Select an employee to modify their profile or remove them from the system.",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _employeesFuture,
              builder: (context, snapshot) {
                if (_employeesFuture == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                // 🚀 Grab the current user's role
                final currentUserRole = context.watch<UserProvider>().role;

                // 🚀 Filter out the Manager if the viewer is just an Admin
                final employeesList = (snapshot.data ?? []).where((emp) {
                  final empRole = emp['role']?.toString().toLowerCase() ?? '';
                  final isEmpManager =
                      empRole == 'manager' || empRole == 'super_admin';

                  // Hide them if the logged-in user is NOT the Master Key
                  if (isEmpManager && currentUserRole != userRole.Manager) {
                    return false;
                  }
                  return true;
                }).toList();

                if (employeesList.isEmpty) {
                  return const Center(
                    child: Text(
                      "No employees found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: employeesList.length,
                  itemBuilder: (context, index) {
                    final employee = employeesList[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[900]?.withOpacity(0.5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: EmployeeTile(
                          () {},
                          employee['full_name'] ?? "Unknown",
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditEmployeeDetailsScreen(
                                            employee: employee,
                                          ),
                                    ),
                                  ).then((_) => _refreshList());
                                },
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                                onPressed: () async {
                                  bool? confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Delete Employee?"),
                                      content: const Text(
                                        "This will permanently remove this employee from the system.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await _service.deleteEmployee(
                                        employee['id'],
                                      );
                                      _refreshList();
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Employee removed.'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint("Delete error: $e");
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          employee['branch'] ?? "No Branch Assigned",
                          employee['job_title'] ??
                              employee['role'] ??
                              "No Position",
                          employeeEmail: employee['email']?.toString(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
