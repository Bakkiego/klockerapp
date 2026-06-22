import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'components/payslip_detail_screen.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  bool _isLoading = true;
  bool _isRunningPayroll = false;
  final TextEditingController _monthController = TextEditingController();

  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  Map<String, Map<String, dynamic>> _payrollSummary = {};

  @override
  void initState() {
    super.initState();
    _fetchAndCalculatePayroll();
  }

  @override
  void dispose() {
    _monthController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndCalculatePayroll() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final profile = await client
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .single();
      final tenantId = profile['tenant_id'];

      final employees = await client
          .from('profiles')
          .select(
            'id, full_name, avatar_url, salary_configs!inner(pay_type, base_rate)',
          )
          .eq('tenant_id', tenantId)
          .neq('id', user.id)
          .isFilter('deleted_at', null);

      final startString = DateTime(
        _selectedDateRange.start.year,
        _selectedDateRange.start.month,
        _selectedDateRange.start.day,
      ).toUtc().toIso8601String();
      final endString = DateTime(
        _selectedDateRange.end.year,
        _selectedDateRange.end.month,
        _selectedDateRange.end.day,
        23,
        59,
        59,
      ).toUtc().toIso8601String();

      final attendance = await client
          .from('attendance')
          .select('profile_id, clock_in, clock_out')
          .eq('tenant_id', tenantId)
          .gte('clock_in', startString)
          .lte('clock_in', endString)
          .not('clock_out', 'is', null);

      Map<String, Map<String, dynamic>> summary = {};

      for (var emp in employees) {
        final configs = emp['salary_configs'];
        Map<String, dynamic>? activeConfig;

        if (configs is List && configs.isNotEmpty && configs[0] != null) {
          activeConfig = Map<String, dynamic>.from(configs[0]);
        } else if (configs is Map) {
          activeConfig = Map<String, dynamic>.from(configs);
        }

        final bool isHourly = activeConfig != null
            ? (activeConfig['pay_type']?.toString().toLowerCase() ??
                      'hourly') ==
                  'hourly'
            : true;

        final double baseRate = activeConfig != null
            ? (double.tryParse(activeConfig['base_rate']?.toString() ?? '0') ??
                  0.0)
            : 0.0;

        summary[emp['id']] = {
          'profile_id': emp['id'],
          'name': emp['full_name'] ?? 'Unknown Employee',
          'avatar_url': emp['avatar_url'],
          'is_hourly': isHourly,
          'base_rate': baseRate,
          'total_minutes': 0,
          'shifts_count': 0,
        };
      }

      for (var record in attendance) {
        final profileId = record['profile_id'];
        if (summary.containsKey(profileId)) {
          final inTime = DateTime.parse(record['clock_in']).toLocal();
          final outTime = DateTime.parse(record['clock_out']).toLocal();
          summary[profileId]!['total_minutes'] += outTime
              .difference(inTime)
              .inMinutes;
          summary[profileId]!['shifts_count'] += 1;
        }
      }

      summary.removeWhere(
        (key, value) =>
            value['is_hourly'] == true && value['shifts_count'] == 0,
      );

      if (mounted) setState(() => _payrollSummary = summary);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final theme = Theme.of(context);
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF00A36C),
              foregroundColor: Colors.white,
            ),
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF00A36C),
              onPrimary: Colors.white,
              surface: theme.scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _fetchAndCalculatePayroll();
    }
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  void _showBulkStatusUpdateDialog() {
    final TextEditingController bulkMonthController = TextEditingController();
    final targetDate = _selectedDateRange.start;
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    bulkMonthController.text =
        "${months[targetDate.month - 1]} ${targetDate.year}";

    String selectedStatus = 'Paid';
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Bulk Status Update",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "This will instantly update the status of EVERY payslip generated for this period.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: bulkMonthController,
                    decoration: const InputDecoration(
                      labelText: "Payroll Period (e.g. March 2026)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: "New Status",
                      border: OutlineInputBorder(),
                    ),
                    items: ['Pending', 'Paid', 'Cancelled']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedStatus = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          if (bulkMonthController.text.trim().isEmpty) return;
                          setDialogState(() => isUpdating = true);
                          try {
                            await SupabaseService().bulkUpdatePayslipStatus(
                              bulkMonthController.text.trim(),
                              selectedStatus,
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Success! All ${bulkMonthController.text} payslips marked as $selectedStatus.",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                          } finally {
                            if (mounted)
                              setDialogState(() => isUpdating = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    foregroundColor: Colors.white,
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Update All"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRunPayrollDialog() {
    final targetDate = _selectedDateRange.start;
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    _monthController.text =
        "${months[targetDate.month - 1]} ${targetDate.year}";

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Run Monthly Payroll",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "This will calculate salaries and instantly send payslips to all active employees' apps.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _monthController,
                    decoration: const InputDecoration(
                      labelText: "Payroll Period",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isRunningPayroll
                      ? null
                      : () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isRunningPayroll
                      ? null
                      : () async {
                          if (_monthController.text.trim().isEmpty) return;
                          setDialogState(() => _isRunningPayroll = true);
                          try {
                            await SupabaseService().runMonthlyPayroll(
                              _monthController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Success! Payslips for ${_monthController.text} generated.",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                          } finally {
                            if (mounted)
                              setDialogState(() => _isRunningPayroll = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    foregroundColor: Colors.white,
                  ),
                  child: _isRunningPayroll
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Generate Payslips"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🚀 EXACT MATCH for your database key!
    final userProvider = context.watch<UserProvider>();
    final canRunPayroll = userProvider.can('run_payroll');
    final currency = userProvider.currencySymbol;

    final summaryList = _payrollSummary.values.toList();
    summaryList.sort((a, b) => a['name'].compareTo(b['name']));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Payroll Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // 🚀 GRANULAR SECURITY: Hide Bulk Update
          if (canRunPayroll)
            IconButton(
              tooltip: "Bulk Update Status",
              icon: const Icon(Icons.checklist_rtl, color: Color(0xFF00A36C)),
              onPressed: _showBulkStatusUpdateDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. DATE FILTER BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Color(0xFF00A36C)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${DateFormat('MMM dd').format(_selectedDateRange.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange.end)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _pickDateRange,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00A36C),
                  ),
                  child: const Text("CHANGE"),
                ),
              ],
            ),
          ),

          // --- 2. SUMMARY LIST ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : summaryList.isEmpty
                ? const Center(
                    child: Text(
                      "No payroll data found for this period.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: summaryList.length,
                    itemBuilder: (context, index) {
                      final emp = summaryList[index];
                      final isHourly = emp['is_hourly'] == true;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PayslipDetailScreen(
                                employeeSummary: {
                                  'real_profile_id': emp['profile_id'],
                                  'name': emp['name'],
                                  'net_salary': 0.00,
                                },
                                dateRange: _selectedDateRange,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          color: isDark
                              ? theme.colorScheme.surface
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(
                                    0xFF00A36C,
                                  ).withOpacity(0.2),
                                  backgroundImage: emp['avatar_url'] != null
                                      ? NetworkImage(emp['avatar_url'])
                                      : null,
                                  child: emp['avatar_url'] == null
                                      ? Text(
                                          emp['name'][0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00A36C),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emp['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      isHourly
                                          ? Text(
                                              "${emp['shifts_count']} Completed Shifts",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            )
                                          : const Text(
                                              "Monthly Salaried",
                                              style: TextStyle(
                                                color: Color(0xFF00A36C),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00A36C,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        isHourly
                                            ? "Tracked Time"
                                            : "Base Salary",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF00A36C),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isHourly
                                            ? _formatDuration(
                                                emp['total_minutes'],
                                              )
                                            : "$currency${emp['base_rate'].toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF00A36C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🚀 GRANULAR SECURITY: Hide the critical "Run Payroll" button
      floatingActionButton: canRunPayroll
          ? FloatingActionButton.extended(
              onPressed: _showRunPayrollDialog,
              backgroundColor: const Color(0xFF00A36C),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                "Run Payroll",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
