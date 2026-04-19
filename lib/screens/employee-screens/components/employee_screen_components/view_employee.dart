import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/view_employee_detail.dart';
import '../../../../supabase/repo/supabase_service.dart';

class ViewEmployee extends StatefulWidget {
  const ViewEmployee({super.key});

  @override
  State<ViewEmployee> createState() => _ViewEmployeeState();
}

class _ViewEmployeeState extends State<ViewEmployee> {
  final SupabaseService _service = SupabaseService();

  // 1. Data storage
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  // 2. Fetch logic
  Future<void> _fetchEmployees() async {
    try {
      final data = await _service.getEmployees();
      setState(() {
        _allEmployees = data;
        _filteredEmployees = data; // Initially, filtered list is the full list
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching employees: $e");
    }
  }

  // 3. Search logic
  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allEmployees;
    } else {
      results = _allEmployees
          .where(
            (user) => user["full_name"].toLowerCase().contains(
              enteredKeyword.toLowerCase(),
            ),
          )
          .toList();
    }

    setState(() {
      _filteredEmployees = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          // --- Search Bar Row ---
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    controller: _searchController, // Connect the controller
                    onChanged: (value) =>
                        _runFilter(value), // Filter as you type
                    hintText: "Employee name",
                    trailing: [const Icon(Icons.search)],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.filter_list_outlined, size: 35),
              ),
            ],
          ),

          // --- The Employee List ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : _filteredEmployees.isEmpty
                ? const Center(child: Text("No employees found."))
                : ListView.builder(
                    itemCount: _filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = _filteredEmployees[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF00A36C,
                          ).withOpacity(0.1),
                          child: Text(
                            employee['full_name']?[0].toUpperCase() ?? 'U',
                          ),
                        ),
                        title: Text(
                          employee['full_name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(employee['role'] ?? 'Employee'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ViewEmployeeScreen(employee: employee),
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
