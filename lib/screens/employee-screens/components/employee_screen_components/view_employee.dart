import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/view_employee_detail.dart';
import 'package:klockerapp/utils/widgets/k_status_badge.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../models/app_enums.dart';
import '../../../../supabase/repo/supabase_service.dart';
import 'email_service.dart';
import 'package:klockerapp/screens/employee-screens/components/seat_usage_banner.dart';

class ViewEmployee extends StatefulWidget {
  const ViewEmployee({super.key});

  @override
  State<ViewEmployee> createState() => _ViewEmployeeState();
}

class _ViewEmployeeState extends State<ViewEmployee> {
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  String _statusFilter = "All";
  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getEmployees();
      if (mounted) {
        setState(() {
          _allEmployees = data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching employees: $e");
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> results = _allEmployees;

    // 🚀 NEW: Cloak the Manager from Admins
    final currentUserRole = context.read<UserProvider>().role;
    results = results.where((emp) {
      final empRole = emp['role']?.toString().toLowerCase() ?? '';
      final isEmpManager = empRole == 'manager' || empRole == 'super_admin';

      if (isEmpManager && currentUserRole != userRole.Manager) {
        return false;
      }
      return true;
    }).toList();

    // 1. Filter by Status Pill
    if (_statusFilter != 'All') {
      results = results.where((user) {
        final status =
            user['approval_status']?.toString().toLowerCase() ?? 'approved';
        return status == _statusFilter.toLowerCase();
      }).toList();
    }

    // 2. Filter by Search Text
    if (_searchQuery.isNotEmpty) {
      results = results.where((user) {
        final name = (user["full_name"] ?? "").toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredEmployees = results;
    });
  }

  Future<void> _changeStatus(
    Map<String, dynamic> employee,
    String newStatus,
  ) async {
    final String employeeId = employee['id'];
    final String employeeEmail = (employee['email'] ?? '').toString().trim();
    final String employeeName = employee['full_name'] ?? 'Employee';

    try {
      // 1. Database first. If the seat-limit trigger rejects this, we
      //    throw here and nothing below runs — no state change, no email.
      await _service.updateEmployeeApprovalStatus(employeeId, newStatus);

      // 2. Only now is the change real, so reflect it locally.
      if (mounted) {
        setState(() {
          final index = _allEmployees.indexWhere((e) => e['id'] == employeeId);
          if (index != -1) {
            _allEmployees[index]['approval_status'] = newStatus;
          }
          _applyFilters();
        });
      }

      // 3. Email last, and only on approval.
      bool emailSent = false;
      String? emailProblem;

      if (newStatus == 'approved') {
        if (employeeEmail.isEmpty) {
          emailProblem = 'no email address on file';
        } else {
          emailSent = await EmailService.sendApprovalEmail(
            employeeEmail: employeeEmail,
            employeeName: employeeName,
          );
          if (!emailSent) emailProblem = 'the email could not be sent';
        }
      }

      if (!mounted) return;

      // Don't claim an email was sent when it wasn't — sendApprovalEmail
      // returns false rather than throwing, so the old message was
      // unconditional.
      final String message;
      final Color colour;

      if (newStatus == 'approved') {
        if (emailSent) {
          message = 'Employee approved and notified by email.';
          colour = const Color(0xFF00A36C);
        } else {
          message =
              'Employee approved, but $emailProblem. '
              'Let them know they can now sign in.';
          colour = Colors.orange;
        }
      } else {
        message = 'Employee rejected.';
        colour = Colors.orange;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: colour,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Status change error: $e');
      if (!mounted) return;

      final friendly = _service.describeSeatError(e);

      // A plan limit needs an action from them, not just an
      // acknowledgement, so it gets a dialog rather than a snackbar.
      if (friendly.contains('plan allows')) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Plan limit reached'),
            content: Text(friendly),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendly),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = context.watch<UserProvider>();
    final canManageEmployees = userProvider.can('manage_employees');

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    isDark ? Colors.grey[900] : Colors.white,
                  ),
                  hintText: "Search employee name...",
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 12.0, right: 8.0),
                    child: Icon(Icons.search, color: Colors.grey),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SeatUsageBanner(),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _statusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00A36C).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF00A36C) : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _statusFilter = filter;
                        _applyFilters();
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF00A36C)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : _filteredEmployees.isEmpty
                ? const Center(
                    child: Text(
                      "No employees found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = _filteredEmployees[index];
                      final String? avatarUrl = employee['avatar_url'];
                      final String status =
                          employee['approval_status'] ?? 'approved';

                      // 🚀 UPGRADED: Bulletproof check for empty roles
                      final String roleStr =
                          employee['role']?.toString() ?? 'Employee';
                      final bool isAdmin = roleStr.toLowerCase() == 'admin';

                      // Safely checks if it is null OR just a blank string
                      final dynamic customRoleId = employee['custom_role_id'];
                      final bool hasNoCustomRole =
                          customRoleId == null ||
                          customRoleId.toString().trim().isEmpty;

                      final bool needsPermissions = isAdmin && hasNoCustomRole;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[900]?.withOpacity(0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(
                              0xFF00A36C,
                            ).withOpacity(0.1),
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Text(
                                    employee['full_name']?[0].toUpperCase() ??
                                        'U',
                                    style: const TextStyle(
                                      color: Color(0xFF00A36C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  employee['full_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              KStatusBadge(status: status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee['job_title'] ??
                                      employee['role'] ??
                                      'Employee',
                                  style: TextStyle(
                                    color: employee['job_title'] != null
                                        ? const Color(0xFF00A36C)
                                        : Colors.grey,
                                    fontWeight: employee['job_title'] != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                if ((employee['email']?.toString().trim() ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    employee['email'].toString(),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (needsPermissions) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.red,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        "Action Required: Assign Role",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: (status == 'pending' && canManageEmployees)
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: () =>
                                          _changeStatus(employee, 'approved'),
                                      tooltip: "Approve",
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _changeStatus(employee, 'rejected'),
                                      tooltip: "Reject",
                                    ),
                                  ],
                                )
                              : Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ViewEmployeeScreen(employee: employee),
                              ),
                            ).then((_) {
                              _fetchEmployees();
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
