import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/custom_date_picker.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      // Fetches EVERYTHING
      final requests = await SupabaseService().getAllCompanyLeaveRequests();
      if (mounted) setState(() => _allRequests = requests);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDecision(String requestId, String decision) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00A36C)),
        ),
      );

      await SupabaseService().updateLeaveStatus(requestId, decision);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Request $decision!"),
            backgroundColor: decision == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
      _fetchRequests(); // Refresh the list
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- 🚀 DUAL-FILTERING ENGINE ---
  List<Map<String, dynamic>> get _filteredRequests {
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
        matchesDate =
            (target.isAtSameMomentAs(cleanStart) ||
                target.isAfter(cleanStart)) &&
            (target.isAtSameMomentAs(cleanEnd) || target.isBefore(cleanEnd));
      }

      return matchesStatus && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🚀 CHECK PERMISSION FOR LEAVE POLICIES
    final userProvider = context.watch<UserProvider>();
    final canManagePolicies = userProvider.can('manage_leave_policies');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.redAccent,
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
                          color: const Color(0xFF00A36C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00A36C).withOpacity(0.3),
                          ),
                        ),
                        // 🚀 MAGIC FIX: mainAxisSize limits the row to strictly what it needs
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.settings,
                              color: Color(0xFF00A36C),
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Settings",
                              style: TextStyle(
                                color: Color(0xFF00A36C),
                                fontWeight: FontWeight.bold,
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
                      elevation: WidgetStateProperty.all(0),
                      backgroundColor: WidgetStateProperty.all(
                        isDark ? Colors.grey[900] : Colors.grey[100],
                      ),
                      hintText: "Search requests...",
                      leading: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A36C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.filter_list_outlined,
                      color: Color(0xFF00A36C),
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
                        color: isSelected
                            ? const Color(0xFF00A36C)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00A36C)
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00A36C),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF00A36C),
                      onRefresh: _fetchRequests,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_filteredRequests.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  _isDateFilterActive
                                      ? "No ${_selectedFilter.toLowerCase()} requests on this date."
                                      : "No ${_selectedFilter.toLowerCase()} requests.",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),

                          ..._filteredRequests.map((req) {
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
    final isDark = theme.brightness == Brightness.dark;
    final isPending = status.toLowerCase() == 'pending';
    final isApproved = status.toLowerCase() == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 🚀 DYNAMIC AVATAR LOGIC
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF00A36C).withOpacity(0.2),
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl == null
                    ? const Icon(Icons.person, color: Color(0xFF00A36C))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      type,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                days,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A36C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      "Reject",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleDecision(requestId, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A36C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Approve",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isApproved
                    ? const Color(0xFF00A36C).withOpacity(0.1)
                    : Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isApproved ? Icons.check_circle : Icons.cancel,
                    color: isApproved
                        ? const Color(0xFF00A36C)
                        : Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isApproved ? "Approved" : "Rejected",
                    style: TextStyle(
                      color: isApproved
                          ? const Color(0xFF00A36C)
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
