import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/custom_date_picker.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';
import 'leave_settings_screen.dart'; // 🚀 IMPORT SETTINGS SCREEN

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allRequests = [];

  // --- Track the date AND if the filter is active ---
  DateTime _selectedDate = DateTime.now();
  bool _isDateFilterActive = false;

  // The active pill filter
  String _selectedFilter = 'Pending';
  final List<String> _filters = ['Pending', 'Approved', 'Rejected', 'All'];

  // The search bar was previously decorative — no controller, no handler.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
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

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      // Fetches EVERYTHING
      final requests = await SupabaseService().getAllCompanyLeaveRequests();
      if (mounted) setState(() => _allRequests = requests);
    } catch (e) {
      if (mounted) _showSnack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDecision(String requestId, String decision) async {
    // Captured up front: after the dialog is popped, looking these up off
    // `context` is a race against the widget still being mounted.
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await SupabaseService().updateLeaveStatus(requestId, decision);

      navigator.pop(); // Close loading dialog
      if (!mounted) return;

      _showSnack("Request $decision.");
      _fetchRequests(); // Refresh the list
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      _showSnack("Error: $e", isError: true);
    }
  }

  // --- 🚀 DUAL-FILTERING ENGINE ---
  List<Map<String, dynamic>> get _filteredRequests {
    final query = _searchQuery.trim().toLowerCase();

    return _allRequests.where((req) {
      // 1. Status Check
      bool matchesStatus =
          _selectedFilter == 'All' ||
          (req['status'] ?? '').toString().toLowerCase() ==
              _selectedFilter.toLowerCase();

      // 2. Date Check (Only applies if they explicitly picked a date)
      bool matchesDate = true;
      if (_isDateFilterActive &&
          req['start_date'] != null &&
          req['end_date'] != null) {
        // Strip times to compare pure calendar days
        DateTime target = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        DateTime start = DateTime.parse(req['start_date']);
        DateTime end = DateTime.parse(req['end_date']);

        DateTime cleanStart = DateTime(start.year, start.month, start.day);
        DateTime cleanEnd = DateTime(end.year, end.month, end.day);

        // Does the target date fall on or between the start and end dates?
        matchesDate = !target.isBefore(cleanStart) && !target.isAfter(cleanEnd);
      }

      // 3. Text Check (employee name or leave type)
      bool matchesQuery = true;
      if (query.isNotEmpty) {
        final name = (req['profiles']?['full_name'] ?? '')
            .toString()
            .toLowerCase();
        final type = (req['leave_type'] ?? '').toString().toLowerCase();
        matchesQuery = name.contains(query) || type.contains(query);
      }

      return matchesStatus && matchesDate && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // 🚀 CHECK PERMISSION FOR LEAVE POLICIES
    final userProvider = context.watch<UserProvider>();
    final canManagePolicies = userProvider.can('manage_leave_policies');

    // Computed once — the getter walks the whole list, and the old code
    // called it twice per build.
    final requests = _filteredRequests;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP DATE PICKER & SETTINGS ICON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                children: [
                  // 🚀 FIXED: Standard Expanded to lock DatePicker firmly in place
                  Expanded(
                    child: CustomDatePicker(
                      initialDate: _selectedDate,
                      onDateSelected: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                          _isDateFilterActive = true;
                        });
                      },
                    ),
                  ),

                  if (_isDateFilterActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: "Clear date filter",
                        icon: Icon(
                          Icons.close_rounded,
                          color: scheme.onErrorContainer,
                        ),
                        onPressed: () {
                          setState(() {
                            _isDateFilterActive = false;
                            _selectedDate = DateTime.now();
                          });
                        },
                      ),
                    ),
                  ],

                  // 🚀 HIDE SETTINGS IF THEY DON'T HAVE PERMISSION
                  if (canManagePolicies) ...[
                    const SizedBox(width: 8),
                    // 🚀 FIXED OVERFLOW: The Settings Button
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LeaveSettingsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // 🚀 MAGIC FIX: mainAxisSize limits the row to strictly what it needs
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.settings,
                              color: scheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Settings",
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      controller: _searchController,
                      hintText: "Search requests...",
                      leading: const Icon(Icons.search, size: 20),
                      trailing: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.filter_list_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // 3. THE SLEEK PILL FILTERS
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(
                        right: 10,
                        top: 5,
                        bottom: 5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? scheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? scheme.primary : scheme.outline,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. DYNAMIC REQUESTS LIST
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchRequests,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (requests.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  _emptyMessage(),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),

                          ...requests.map((req) {
                            final startDate = DateTime.parse(req['start_date']);
                            final endDate = DateTime.parse(req['end_date']);

                            return _buildManagerActionCard(
                              requestId: req['id'],
                              name:
                                  req['profiles']?['full_name'] ??
                                  'Unknown Employee',
                              type: req['leave_type'] ?? 'Leave',
                              days: "${req['total_days']} Days",
                              date:
                                  "${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}",
                              status: req['status'] ?? 'pending',
                              // 🚀 Pulls the real avatar, or leaves it null if they don't have one
                              imageUrl: req['profiles']?['avatar_url'],
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyMessage() {
    final status = _selectedFilter.toLowerCase();
    if (_searchQuery.trim().isNotEmpty) {
      return "No $status requests match \"${_searchQuery.trim()}\".";
    }
    if (_isDateFilterActive) {
      return "No $status requests on this date.";
    }
    return "No $status requests.";
  }

  // --- SMART FOOTER WIDGET ---
  Widget _buildManagerActionCard({
    required String requestId,
    required String name,
    required String type,
    required String days,
    required String date,
    required String status,
    String? imageUrl, // 🚀 Made this nullable (String?)
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPending = status.toLowerCase() == 'pending';

    // One lookup instead of an isApproved ternary on every colour below —
    // and it covers statuses beyond approved/rejected if any ever appear.
    final (statusBg, statusFg) = context.status.forStatus(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // 🚀 DYNAMIC AVATAR LOGIC
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl == null
                      ? Icon(Icons.person, color: scheme.onPrimaryContainer)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium),
                      Text(
                        type,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  days,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: context.brandText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _handleDecision(requestId, 'rejected'),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleDecision(requestId, 'approved'),
                      child: const Text("Approve"),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      status.toLowerCase() == 'approved'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: statusFg,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusLabel(status),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: statusFg,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }
}
