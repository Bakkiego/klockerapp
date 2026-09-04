import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/data_collector_list.dart';
import '../../../../supabase/repo/supabase_service.dart';

class EditEmployeeDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EditEmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EditEmployeeDetailsScreen> createState() => _EditEmployeeDetailScreen();
}

class _EditEmployeeDetailScreen extends State<EditEmployeeDetailsScreen> {
  final DataCollectorList dataCollectorList = DataCollectorList();
  final SupabaseService _service = SupabaseService();

  // 🚀 NEW: Controller for the ID Number
  final TextEditingController _idNumberController = TextEditingController();

  List<Map<String, dynamic>> _availableRoles = [];
  String? _selectedRoleId;
  String? _selectedRoleName;
  bool _isLoadingRoles = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final branches = await _service.getBranchNames();
      final depts = await _service.getDepartmentNames();
      final roles = await _service.getTenantRoles();
      final titles = await _service.getJobTitles();

      if (mounted) {
        setState(() {
          dataCollectorList.branchOptions = branches;
          dataCollectorList.deptOptions = depts;
          dataCollectorList.jobTitleOptions = titles;

          final employeeData = widget.employee;
          final currentTitle = employeeData['job_title'];
          if (titles.contains(currentTitle)) {
            dataCollectorList.selectedJobTitle = currentTitle;
          }

          String? currentBranch = employeeData['branch'];
          if (branches.contains(currentBranch)) {
            dataCollectorList.selectedBranch = currentBranch;
          }

          String? currentDept = employeeData['dept_name'];
          if (depts.contains(currentDept)) {
            dataCollectorList.selectedDept = currentDept;
          }

          dataCollectorList.nameController.text =
              employeeData['full_name'] ?? '';
          dataCollectorList.emailController.text = employeeData['email'] ?? '';
          dataCollectorList.phoneController.text =
              employeeData['phone_num']?.toString() ?? '';
          dataCollectorList.addressController.text =
              employeeData['address'] ?? '';
          dataCollectorList.dateController.text =
              employeeData['hire_date'] ?? '';

          // 🚀 NEW: Pre-fill the ID Number from the database
          _idNumberController.text =
              employeeData['identification_number'] ?? '';

          dataCollectorList.selectedRole = employeeData['role'];

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

  Future<void> _showCreateJobTitleDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final created = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("New job title"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Title name",
                hintText: "e.g. Chef, Supervisor, Driver",
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                final name = v?.trim() ?? '';
                if (name.isEmpty) return 'Enter a title name';
                if (name.length < 2) return 'That looks too short';
                // The table has a unique constraint on (tenant_id,
                // title_name), so catch duplicates before the round trip.
                final exists = dataCollectorList.jobTitleOptions.any(
                  (t) => t.toLowerCase() == name.toLowerCase(),
                );
                if (exists) return 'That title already exists';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A36C),
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final name = controller.text.trim();
                      final messenger = ScaffoldMessenger.of(dialogContext);

                      try {
                        await _service.createJobTitle(name);
                        Navigator.pop(dialogContext, name);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text("Could not create title: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Create"),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (created == null || !mounted) return;

    // Refresh the list from the server so we stay in step with the table,
    // then select what was just created.
    final titles = await _service.getJobTitles();
    if (!mounted) return;
    setState(() {
      dataCollectorList.jobTitleOptions = titles;
      dataCollectorList.selectedJobTitle = created;
    });
  }

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
                ...dataCollectorList.personalTileBody,
                const SizedBox(height: 16),

                // 🚀 NEW: Standalone ID Number Field
                TextFormField(
                  controller: _idNumberController,
                  decoration: InputDecoration(
                    labelText: 'ID Number (Identification)',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ...dataCollectorList.getCompanyTileBody(
                  onDateTap: _selectDate,
                  onRefresh: () {
                    setState(() {});
                  },
                  onCreateJobTitle: _showCreateJobTitleDialog,
                ),
                const SizedBox(height: 24),

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
                                  value: role['id'],
                                  child: Text(role['role_name']),
                                );
                              }).toList(),
                              onChanged: (String? newRoleId) {
                                setState(() {
                                  _selectedRoleId = newRoleId;
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
                          final branchId = await _service.getBranchIdByName(
                            dataCollectorList.selectedBranch,
                          );
                          final Map<String, dynamic> employeeUpdates = {
                            'full_name': dataCollectorList.nameController.text
                                .trim(),
                            'phone_num': int.tryParse(cleanPhone) ?? 0,
                            'address': dataCollectorList.addressController.text
                                .trim(),
                            'dept_name': dataCollectorList.selectedDept,
                            'branch_id': branchId,
                            'branch': dataCollectorList.selectedBranch,
                            'hire_date': dataCollectorList.dateController.text
                                .trim(),
                            'role': dataCollectorList.selectedRole,
                            'custom_role_id': _selectedRoleId,
                            'job_title': dataCollectorList.selectedJobTitle,
                            'identification_number': _idNumberController.text
                                .trim(),
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
