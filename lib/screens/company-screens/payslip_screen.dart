import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';
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

  static const _months = [
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    // The Theme override is gone. It replaced the app bar and colour scheme
    // with hardcoded values, which is the same pattern that rendered the
    // calendar unreadable in dark mode. datePickerTheme covers it now.
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
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

  String _periodLabel() {
    final d = _selectedDateRange.start;
    return "${_months[d.month - 1]} ${d.year}";
  }

  void _showBulkStatusUpdateDialog() {
    final TextEditingController bulkMonthController = TextEditingController(
      text: _periodLabel(),
    );

    String selectedStatus = 'Paid';
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;

            return AlertDialog(
              title: const Text("Bulk Status Update"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "This will update the status of every payslip generated "
                    "for this period.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: bulkMonthController,
                    decoration: const InputDecoration(
                      labelText: "Payroll Period (e.g. March 2026)",
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: "New Status"),
                    items: ['Pending', 'Paid', 'Cancelled']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedStatus = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          if (bulkMonthController.text.trim().isEmpty) return;
                          setDialogState(() => isUpdating = true);

                          final navigator = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          final period = bulkMonthController.text.trim();

                          try {
                            await SupabaseService().bulkUpdatePayslipStatus(
                              period,
                              selectedStatus,
                            );
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  "All $period payslips marked $selectedStatus",
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isUpdating = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: scheme.error,
                              ),
                            );
                          }
                        },
                  child: isUpdating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Text("Update All"),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => bulkMonthController.dispose());
  }

  void _showRunPayrollDialog() {
    _monthController.text = _periodLabel();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;

            return AlertDialog(
              title: const Text("Run Monthly Payroll"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "This will calculate salaries and send payslips to every "
                    "active employee's app.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _monthController,
                    decoration: const InputDecoration(
                      labelText: "Payroll Period",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isRunningPayroll
                      ? null
                      : () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _isRunningPayroll
                      ? null
                      : () async {
                          if (_monthController.text.trim().isEmpty) return;
                          setDialogState(() => _isRunningPayroll = true);

                          final navigator = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          final period = _monthController.text.trim();

                          try {
                            await SupabaseService().runMonthlyPayroll(period);
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text("Payslips for $period generated"),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => _isRunningPayroll = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: scheme.error,
                              ),
                            );
                          }
                        },
                  child: _isRunningPayroll
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
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
    final scheme = theme.colorScheme;

    final userProvider = context.watch<UserProvider>();
    final canRunPayroll = userProvider.can('run_payroll');
    final currency = userProvider.currencySymbol;

    final summaryList = _payrollSummary.values.toList();
    summaryList.sort((a, b) => a['name'].compareTo(b['name']));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payroll Report"),
        centerTitle: true,
        actions: [
          if (canRunPayroll)
            IconButton(
              tooltip: "Bulk Update Status",
              icon: const Icon(Icons.checklist_rtl),
              onPressed: _showBulkStatusUpdateDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. DATE FILTER BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: scheme.surfaceContainer,
            child: Row(
              children: [
                Icon(Icons.date_range, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${DateFormat('MMM dd').format(_selectedDateRange.start)} - "
                    "${DateFormat('MMM dd, yyyy').format(_selectedDateRange.end)}",
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: _pickDateRange,
                  child: const Text("CHANGE"),
                ),
              ],
            ),
          ),

          // --- 2. SUMMARY LIST ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : summaryList.isEmpty
                ? Center(
                    child: Text(
                      "No payroll data found for this period.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: summaryList.length,
                    itemBuilder: (context, index) {
                      final emp = summaryList[index];
                      final isHourly = emp['is_hourly'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: scheme.primaryContainer,
                                  backgroundImage: emp['avatar_url'] != null
                                      ? NetworkImage(emp['avatar_url'])
                                      : null,
                                  child: emp['avatar_url'] == null
                                      ? Text(
                                          emp['name'][0].toUpperCase(),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                color:
                                                    scheme.onPrimaryContainer,
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
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      isHourly
                                          ? Text(
                                              "${emp['shifts_count']} completed shifts",
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                  ),
                                            )
                                          : Text(
                                              "Monthly salaried",
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: context.brandText,
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
                                    color: scheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        isHourly
                                            ? "Tracked Time"
                                            : "Base Salary",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: scheme.onPrimaryContainer,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isHourly
                                            ? _formatDuration(
                                                emp['total_minutes'],
                                              )
                                            : "$currency${emp['base_rate'].toStringAsFixed(0)}",
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: scheme.onPrimaryContainer,
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

      floatingActionButton: canRunPayroll
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _showRunPayrollDialog,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text("Run Payroll"),
            )
          : null,
    );
  }
}
