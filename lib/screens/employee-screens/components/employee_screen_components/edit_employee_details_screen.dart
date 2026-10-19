import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/data_collector_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/leader_seats.dart';
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

  /// Roles that consume an admin/manager seat. Must match the
  /// in ('admin', 'manager') checks in leader_seats.sql.
  static const Set<String> _leaderRoles = {'admin', 'manager'};

  // 🚀 NEW: Controller for the ID Number
  final TextEditingController _idNumberController = TextEditingController();

  List<Map<String, dynamic>> _availableRoles = [];
  String? _selectedRoleId;
  bool _isLoadingRoles = true;
  bool _isSaving = false;

  /// Null when the seat RPC failed or isn't deployed. Treated as "no
  /// limit known", so the screen never blocks a save it can't justify —
  /// the trigger is the real gate either way.
  LeaderSeats? _seats;

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

  // ==========================================
  // Helpers
  // ==========================================

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError
              ? theme.textTheme.bodyMedium?.copyWith(color: scheme.onError)
              : null,
        ),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
  }

  bool _isLeaderRole(dynamic role) =>
      _leaderRoles.contains(role?.toString().toLowerCase().trim());

  /// Did this employee already hold a seat when the screen opened? If so,
  /// changing anything about them — including admin <-> manager — never
  /// consumes a new one, so it's never blocked. Mirrors the early return
  /// in enforce_leader_seats().
  bool get _alreadyHeldSeat => _isLeaderRole(widget.employee['role']);

  Future<void> _loadInitialData() async {
    try {
      final branches = await _service.getBranchNames();
      final depts = await _service.getDepartmentNames();
      final roles = await _service.getTenantRoles();
      final titles = await _service.getJobTitles();
      final seats = await _service.getLeaderSeats();

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
          _seats = seats;
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
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final name = controller.text.trim();
                      final messenger = ScaffoldMessenger.of(dialogContext);
                      final scheme = Theme.of(dialogContext).colorScheme;

                      try {
                        await _service.createJobTitle(name);
                        Navigator.pop(dialogContext, name);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              "Could not create title: $e",
                              style: TextStyle(color: scheme.onError),
                            ),
                            backgroundColor: scheme.error,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
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

  Future<void> _handleSave() async {
    if (!dataCollectorList.formKey.currentState!.validate()) return;

    final seats = _seats;
    final takingNewSeat =
        _isLeaderRole(dataCollectorList.selectedRole) && !_alreadyHeldSeat;

    // Stop here rather than let the trigger reject it — same rule, but
    // without a round trip and without the save half-looking like it
    // worked. The trigger still has the last word.
    if (takingNewSeat && seats != null && !seats.canAddLeader) {
      _showSnack(
        "Your ${seats.tier} plan includes ${seats.limit} admin/manager "
        "seats and all of them are in use. Change an existing admin or "
        "manager to Employee first, or upgrade your plan.",
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    // Read the phone field here, not in build(). It used to be captured
    // during the last build, so an edit made after that build was saved
    // with the previous value.
    final cleanPhone = dataCollectorList.phoneController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    try {
      final branchId = await _service.getBranchIdByName(
        dataCollectorList.selectedBranch,
      );
      final Map<String, dynamic> employeeUpdates = {
        'full_name': dataCollectorList.nameController.text.trim(),
        'phone_num': int.tryParse(cleanPhone) ?? 0,
        'address': dataCollectorList.addressController.text.trim(),
        'dept_name': dataCollectorList.selectedDept,
        'branch_id': branchId,
        'branch': dataCollectorList.selectedBranch,
        'hire_date': dataCollectorList.dateController.text.trim(),
        'role': dataCollectorList.selectedRole,
        'custom_role_id': _selectedRoleId,
        'job_title': dataCollectorList.selectedJobTitle,
        'identification_number': _idNumberController.text.trim(),
      };

      await _service.updateEmployeeProfile(
        employeeId: widget.employee['id'],
        updates: employeeUpdates,
      );

      if (!mounted) return;
      _showSnack('Employee updated successfully!');
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      // The seat trigger's message is already written for a customer to
      // read — the plan, the seat count and the two ways out. Don't bury
      // it under a generic error.
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack(e.message, isError: true);
    } catch (e) {
      debugPrint("Update error: $e");
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Error: $e', isError: true);
    }
  }

  // ==========================================
  // Build
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Security & Permissions",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_seats != null)
                              _buildSeatNotice(theme, _seats!),

                            DropdownButtonFormField<String>(
                              value: _selectedRoleId,
                              decoration: InputDecoration(
                                labelText: "Assign Custom Role / Job Title",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(
                                  Icons.shield_outlined,
                                  color: scheme.primary,
                                ),
                              ),
                              hint: const Text("Select a custom role..."),
                              items: [
                                // Without this there's no way to take a
                                // custom role back off an employee once
                                // it's been assigned.
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text("No custom role"),
                                ),
                                ..._availableRoles.map((role) {
                                  return DropdownMenuItem<String>(
                                    value: role['id'],
                                    child: Text(
                                      role['role_name']?.toString() ??
                                          'Unnamed role',
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (String? newRoleId) {
                                setState(() => _selectedRoleId = newRoleId);
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save Changes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.onPrimary,
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

  /// Seat usage, shown above the role controls. Only interesting when the
  /// tenant is at or over its cap, or close enough to care.
  Widget _buildSeatNotice(ThemeData theme, LeaderSeats seats) {
    if (seats.unlimited) return const SizedBox.shrink();

    final scheme = theme.colorScheme;
    final atCap = !seats.canAddLeader;

    // An employee who already holds a seat can always be edited, so don't
    // wave a warning at an admin who's just fixing someone's phone number.
    final warn = atCap && !_alreadyHeldSeat;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn ? scheme.errorContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warn ? Icons.info_outline : Icons.groups_outlined,
            size: 18,
            color: warn ? scheme.onErrorContainer : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seats.overCap
                      ? "${seats.used} admin/manager seats in use, ${seats.limit} included on ${seats.tier}"
                      : seats.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: warn
                        ? scheme.onErrorContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                if (warn) ...[
                  const SizedBox(height: 2),
                  Text(
                    "To make this employee an Admin or Manager, change an "
                    "existing one to Employee first, or upgrade your plan.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
