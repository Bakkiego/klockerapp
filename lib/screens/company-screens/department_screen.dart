import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 Added for Permissions
import '../../../supabase/repo/supabase_service.dart'; // Adjust path if needed
import 'components/add_department_screen.dart';
import 'components/edit_department_screen.dart';

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getDepartments();
      if (mounted) {
        setState(() {
          _departments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 THE BOUNCER: Check if they are allowed to manage departments
    final userProvider = context.watch<UserProvider>();
    final canManageDepartments = userProvider.can('manage_departments');

    // Real-time search filtering
    final filteredDepartments = _departments
        .where(
          (d) => d['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,

      // 🚀 GRANULAR SECURITY: Hide the Add button if they lack permission
      floatingActionButton: canManageDepartments
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Navigates to Add Screen and refreshes list when returning!
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddDepartmentScreen(),
                  ),
                );
                if (result == true) _fetchDepartments();
              },
              backgroundColor: const Color(0xFF00A36C),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Department",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null, // Completely hides the FAB

      body: Column(
        children: [
          // Search Bar Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: "Search Departments...",
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              side: WidgetStateProperty.all(
                BorderSide(color: Colors.grey.withOpacity(0.5)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
              leading: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),

          // Department List Section
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchDepartments,
                    color: const Color(0xFF00A36C),
                    child: filteredDepartments.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filteredDepartments.length,
                            itemBuilder: (context, index) {
                              final department = filteredDepartments[index];

                              // Safely parse the joined branch name and manager
                              final branchName =
                                  department['branches']?['name'] ??
                                  'Unknown Branch';
                              final managerName =
                                  department['manager_name'] ?? 'Unassigned';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 6.0,
                                ),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(
                                        0xFF00A36C,
                                      ).withOpacity(0.1),
                                      child: const Icon(
                                        Icons.people_alt_outlined,
                                        color: Color(0xFF00A36C),
                                      ),
                                    ),

                                    title: Text(
                                      department['name'] ?? 'Unnamed',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Branch: $branchName",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          Text(
                                            "Manager: $managerName",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 🚀 GRANULAR SECURITY: Hide the Edit button if they lack permission
                                    trailing: canManageDepartments
                                        ? IconButton(
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditDepartmentScreen(
                                                        initialDepartmentData:
                                                            department,
                                                      ),
                                                ),
                                              );
                                              if (result == true)
                                                _fetchDepartments();
                                            },
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : null, // Return null to remove the trailing icon entirely
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_center_outlined,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Departments Found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Create departments to organize your employees.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
