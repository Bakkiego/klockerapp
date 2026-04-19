import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> allEmployees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;

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

  Future<void> _fetchData() async {
    final data = await _service.getEmployees();
    setState(() {
      allEmployees = data;
      filteredEmployees = data;
      isLoading = false;
    });
  }

  void _filterSearch(String query) {
    setState(() {
      filteredEmployees = allEmployees
          .where(
            (emp) =>
                emp['full_name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (emp['branch']?.toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ... (Search Bar code) ...
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _employeesFuture, // Now safe even if null
            builder: (context, snapshot) {
              // 1. Check if the future is actually provided yet
              if (_employeesFuture == null ||
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                );
              }

              // 2. Check for errors
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              // 3. Get the data
              final employeesList = snapshot.data ?? [];

              if (employeesList.isEmpty) {
                return const Center(child: Text("No employees found."));
              }

              return ListView.builder(
                itemCount: employeesList.length,
                itemBuilder: (context, index) {
                  final employee = employeesList[index];
                  return EmployeeTile(
                    () {},
                    employee['full_name'] ?? "Unknown",
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditEmployeeDetailsScreen(
                                  employee: employee,
                                ),
                              ),
                            ).then((_) => _refreshList());
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            // 1. Show a quick confirmation dialog
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

                            // 2. If they clicked 'Delete', run the service call
                            if (confirm == true) {
                              try {
                                await _service.deleteEmployee(employee['id']);
                                _refreshList(); // Update the UI immediately
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Employee removed.'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print("Delete error: $e");
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    employee['branch'] ?? "No Branch",
                    employee['role'] ?? "No Position",
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
