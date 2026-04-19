// file: lib/screens/employee-screens/components/employee_screen_components/edit_employee_details_screen.dart

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

  @override
  initState() {
    super.initState();
    final data = widget.employee;
    // Pre-fill the controllers with the existing data from Supabase
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // 1. Fetch branches from Supabase
      final branches = await _service.getBranchNames();
      final depts = await _service.getDepartmentNames();

      if (mounted) {
        setState(() {
          // 2. Update the dynamic list in the collector
          dataCollectorList.branchOptions = branches;
          dataCollectorList.deptOptions = depts;

          final employeeData = widget.employee;

          String? currentBranch = employeeData['branch'];
          if (branches.contains(currentBranch)) {
            dataCollectorList.selectedBranch = currentBranch;
          }

          String? currentDept = employeeData['dept_name'];
          if (depts.contains(currentDept)) {
            dataCollectorList.selectedDept = currentDept;
          }

          // 3. Fill Text Controllers
          dataCollectorList.nameController.text =
              employeeData['full_name'] ?? '';
          dataCollectorList.emailController.text = employeeData['email'] ?? '';
          dataCollectorList.phoneController.text =
              employeeData['phone_num']?.toString() ?? '';
          dataCollectorList.addressController.text =
              employeeData['address'] ?? '';

          // 4. Set Dropdown Values (Ensure keys match your DB exactly)
          dataCollectorList.selectedRole = employeeData['role'];

          // 5. Set Date
          dataCollectorList.dateController.text =
              employeeData['hire_date'] ?? '';
        });
      }
    } catch (e) {
      print("Error loading initial data: $e");
    }
  }

  void _handleSave() async {
    if (dataCollectorList.formKey.currentState!.validate()) {
      try {
        await _service.updateEmployeeProfile(
          employeeId: widget.employee['id'],
          updates: {
            'full_name': dataCollectorList.nameController.text,
            'hire_date': dataCollectorList.dateController.text,
            'role': 'employee', // Or get from a dropdown
            // Add branch/department logic here
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee Updated Successfully!')),
          );
          Navigator.pop(context); // Go back to the list
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
                // Assuming these lists contain the ExpansionTile(s)
                ...dataCollectorList.personalTileBody,
                const SizedBox(height: 16),
                ...dataCollectorList.getCompanyTileBody(
                  onDateTap: _selectDate,
                  onRefresh: () {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (dataCollectorList.formKey.currentState!.validate()) {
                      try {
                        // Create the map of changes
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
                          'avatar_url': widget.employee['avatar_url'],
                          'role': dataCollectorList.selectedRole,
                        };

                        // Use your EXISTING function
                        await _service.updateEmployeeProfile(
                          employeeId: widget.employee['id'],
                          updates: employeeUpdates,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Employee updated!')),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        print("Update error: $e");
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
