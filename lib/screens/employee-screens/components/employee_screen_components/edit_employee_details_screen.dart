import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Assuming this import contains the logic for the tiles
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/data_collector_list.dart';

import '../../../../supabase/repo/supabase_service.dart';

class EditEmployeeDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> employee; // Pass the employee map here

  const EditEmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EditEmployeeDetailsScreen> createState() => _EditEmployeeDetailScreen();
}

class _EditEmployeeDetailScreen extends State<EditEmployeeDetailsScreen> {
  final DataCollectorList dataCollectorList = DataCollectorList();
  final SupabaseService _service = SupabaseService();

  // 🚀 1. NEW: State variables for the Custom Role engine
  List<Map<String, dynamic>> _availableRoles = [];
  String? _selectedRoleId;
  String? _selectedRoleName;
  bool _isLoadingRoles = true;

  @override
  initState() {
    super.initState();
    // Pre-fill the controllers with the existing data from Supabase
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // 1. Fetch data from Supabase
      final branches = await _service.getBranchNames();
      final depts = await _service.getDepartmentNames();

      // 🚀 2. Fetch the NEW unified Tenant Roles instead of the old job titles
      final roles = await _service.getTenantRoles();

      if (mounted) {
        setState(() {
          // 3. Update the dynamic lists in the collector
          dataCollectorList.branchOptions = branches;
          dataCollectorList.deptOptions = depts;
          // We feed it an empty list so the old string-based dropdown doesn't crash or get confused
          dataCollectorList.jobTitleOptions = [];

          final employeeData = widget.employee;

          // Branch & Dept Logic
          String? currentBranch = employeeData['branch'];
          if (branches.contains(currentBranch)) {
            dataCollectorList.selectedBranch = currentBranch;
          }

          String? currentDept = employeeData['dept_name'];
          if (depts.contains(currentDept)) {
            dataCollectorList.selectedDept = currentDept;
          }

          // 4. Fill Text Controllers
          dataCollectorList.nameController.text =
              employeeData['full_name'] ?? '';
          dataCollectorList.emailController.text = employeeData['email'] ?? '';
          dataCollectorList.phoneController.text =
              employeeData['phone_num']?.toString() ?? '';
          dataCollectorList.addressController.text =
              employeeData['address'] ?? '';
          dataCollectorList.dateController.text =
              employeeData['hire_date'] ?? '';

          // 5. Set Legacy Dropdown Values
          dataCollectorList.selectedRole =
              employeeData['role']; // System Access

          // 🚀 6. Pre-select the employee's Custom Role if they already have one
          _availableRoles = roles;
          _isLoadingRoles = false;
          _selectedRoleId = employeeData['custom_role_id'];
          _selectedRoleName = employeeData['job_title'];
        });
      }
    } catch (e) {
      debugPrint("Error loading initial data: $e");
      if (mounted) setState(() => _isLoadingRoles = false);
    }
  }

  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        dataCollectorList.dateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String rawPhone = dataCollectorList.phoneController.text;
    String cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Employee Details')),
      body: Form(
        key: dataCollectorList.formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Personal Details Form
                ...dataCollectorList.personalTileBody,
                const SizedBox(height: 16),

                // Company Details Form
                ...dataCollectorList.getCompanyTileBody(
                  onDateTap: _selectDate,
                  onRefresh: () {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 24),

                // 🚀 7. NEW: The Dedicated Custom Role Dropdown
                _isLoadingRoles
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00A36C),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[900]?.withOpacity(0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Security & Permissions",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedRoleId,
                              decoration: InputDecoration(
                                labelText: "Assign Custom Role / Job Title",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFF00A36C),
                                ),
                              ),
                              hint: const Text("Select a custom role..."),
                              items: _availableRoles.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role['id'], // Saves the UUID
                                  child: Text(
                                    role['role_name'],
                                  ), // Shows the name
                                );
                              }).toList(),
                              onChanged: (String? newRoleId) {
                                setState(() {
                                  _selectedRoleId = newRoleId;
                                  // Find the matching name so we can save it as their display 'job_title'
                                  _selectedRoleName = _availableRoles
                                      .firstWhere(
                                        (r) => r['id'] == newRoleId,
                                      )['role_name'];
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A36C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (dataCollectorList.formKey.currentState!.validate()) {
                        try {
                          // 🚀 8. UPDATED: Inject the new role data into the update payload
                          final Map<String, dynamic> employeeUpdates = {
                            'full_name': dataCollectorList.nameController.text
                                .trim(),
                            'phone_num': int.tryParse(cleanPhone) ?? 0,
                            'address': dataCollectorList.addressController.text
                                .trim(),
                            'dept_name': dataCollectorList.selectedDept,
                            'branch': dataCollectorList.selectedBranch,
                            'hire_date': dataCollectorList.dateController.text
                                .trim(),
                            'role': dataCollectorList
                                .selectedRole, // Legacy Fallback
                            'custom_role_id':
                                _selectedRoleId, // 🚀 Saves the UUID to trigger permissions
                            'job_title':
                                _selectedRoleName, // 🚀 Saves the string so the UI Directory looks normal
                          };

                          await _service.updateEmployeeProfile(
                            employeeId: widget.employee['id'],
                            updates: employeeUpdates,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Employee updated successfully!'),
                                backgroundColor: Color(0xFF00A36C),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          debugPrint("Update error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
