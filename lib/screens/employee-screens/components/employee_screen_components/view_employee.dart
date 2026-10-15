import 'package:flutter/material.dart';
import 'package:klockerapp/screens/employee-screens/components/employee_screen_components/view_employee_detail.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';
import 'package:klockerapp/utils/widgets/k_filter_pills.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // Helpers
  // ==========================================

  void _showSnack(String message, {bool isError = false, int seconds = 4}) {
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
        duration: Duration(seconds: seconds),
      ),
    );
  }

  /// First letter for the avatar. `name[0]` throws a RangeError on an empty
  /// string, which a profile saved with a blank name produces.
  static String _initial(dynamic name) {
    final text = name?.toString().trim() ?? '';
    return text.isEmpty ? 'U' : text[0].toUpperCase();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getEmployees();
      if (!mounted) return;
      setState(() {
        _allEmployees = data;
        // One setState instead of a setState nested inside a setState.
        _filteredEmployees = _computeFiltered();
      });
    } catch (e) {
      debugPrint("Error fetching employees: $e");
      _showSnack("Couldn't load employees: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Pure — works out the visible list without touching state, so callers
  /// decide when to rebuild.
  List<Map<String, dynamic>> _computeFiltered() {
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
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      results = results.where((user) {
        final name = (user["full_name"] ?? "").toString().toLowerCase();
        final email = (user["email"] ?? "").toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    return results;
  }

  void _applyFilters() {
    setState(() => _filteredEmployees = _computeFiltered());
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
          _filteredEmployees = _computeFiltered();
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
      if (newStatus == 'approved') {
        _showSnack(
          emailSent
              ? 'Employee approved and notified by email.'
              : 'Employee approved, but $emailProblem. '
                    'Let them know they can now sign in.',
        );
      } else {
        _showSnack('Employee rejected.');
      }
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
        _showSnack(friendly, isError: true, seconds: 5);
      }
    }
  }

  // ==========================================
  // Build
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final userProvider = context.watch<UserProvider>();
    final canManageEmployees = userProvider.can('manage_employees');

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBar(
            controller: _searchController,
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
            hintText: "Search name or email...",
            leading: const Padding(
              padding: EdgeInsets.only(left: 12.0, right: 8.0),
              child: Icon(Icons.search),
            ),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _applyFilters();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          const SeatUsageBanner(),
          const SizedBox(height: 16),

          // Same pill row as the attendance and leave screens.
          KFilterPills(
            filters: _filterOptions,
            selected: _statusFilter,
            onSelected: (filter) {
              _statusFilter = filter;
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.trim().isNotEmpty || _statusFilter != 'All'
                          ? "No employees match this filter."
                          : "No employees found.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredEmployees.length,
                    itemBuilder: (context, index) => _buildEmployeeTile(
                      theme,
                      _filteredEmployees[index],
                      canManageEmployees,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTile(
    ThemeData theme,
    Map<String, dynamic> employee,
    bool canManageEmployees,
  ) {
    final scheme = theme.colorScheme;

    final String? avatarUrl = employee['avatar_url'];
    final String status = employee['approval_status'] ?? 'approved';

    // 🚀 UPGRADED: Bulletproof check for empty roles
    final String roleStr = employee['role']?.toString() ?? 'Employee';
    final bool isAdmin = roleStr.toLowerCase() == 'admin';

    // Safely checks if it is null OR just a blank string
    final dynamic customRoleId = employee['custom_role_id'];
    final bool hasNoCustomRole =
        customRoleId == null || customRoleId.toString().trim().isEmpty;

    final bool needsPermissions = isAdmin && hasNoCustomRole;

    final String? jobTitle = employee['job_title']?.toString();
    final String email = (employee['email']?.toString().trim() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: scheme.primaryContainer,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  _initial(employee['full_name']),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                employee['full_name'] ?? 'Unknown',
                style: theme.textTheme.titleSmall,
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
                jobTitle ?? employee['role'] ?? 'Employee',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: jobTitle != null
                      ? context.brandText
                      : scheme.onSurfaceVariant,
                  fontWeight: jobTitle != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: scheme.onErrorContainer,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Action required: assign a role",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.bold,
                        ),
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
                    icon: Icon(Icons.check_circle, color: context.brandText),
                    onPressed: () => _changeStatus(employee, 'approved'),
                    tooltip: "Approve",
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: scheme.error),
                    onPressed: () => _changeStatus(employee, 'rejected'),
                    tooltip: "Reject",
                  ),
                ],
              )
            : Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewEmployeeScreen(employee: employee),
            ),
          ).then((_) {
            if (mounted) _fetchEmployees();
          });
        },
      ),
    );
  }
}
