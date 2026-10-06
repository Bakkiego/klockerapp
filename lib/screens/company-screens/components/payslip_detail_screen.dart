import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/custom_theme/k_palette.dart';
import '../../../utils/pdf_service.dart';

class PayslipDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employeeSummary;
  final DateTimeRange dateRange;

  const PayslipDetailScreen({
    super.key,
    required this.employeeSummary,
    required this.dateRange,
  });

  @override
  State<PayslipDetailScreen> createState() => _PayslipDetailScreenState();
}

class _PayslipDetailScreenState extends State<PayslipDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _lineItems = [];
  Map<String, dynamic>? _officialPayslip;
  String? _avatarUrl;

  bool _isHourly = true;
  double _baseRate = 0.0;
  double _defaultAllowances = 0.0;
  List<dynamic> _defaultDeductions = [];

  static const _statuses = ['Pending', 'Paid', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
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

  static double _num(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  Future<void> _fetchDetails() async {
    try {
      final String? targetId = widget.employeeSummary['real_profile_id'];
      if (targetId == null) {
        throw Exception("Profile ID is missing from summary");
      }

      final client = Supabase.instance.client;

      final items = await SupabaseService().getIndividualPayslipDetails(
        profileId: targetId,
        startDate: widget.dateRange.start,
        endDate: widget.dateRange.end,
      );

      final latestPayslip = await SupabaseService().getLatestPayslipForEmployee(
        targetId,
      );

      final profile = await client
          .from('profiles')
          .select(
            'avatar_url, salary_configs(pay_type, base_rate, default_allowances, default_deductions)',
          )
          .eq('id', targetId)
          .maybeSingle();

      if (profile != null) {
        _avatarUrl = profile['avatar_url'];
        final configs = profile['salary_configs'];

        if (configs != null) {
          Map<String, dynamic>? activeConfig;

          if (configs is List && configs.isNotEmpty && configs[0] != null) {
            activeConfig = Map<String, dynamic>.from(configs[0]);
          } else if (configs is Map) {
            activeConfig = Map<String, dynamic>.from(configs);
          }

          if (activeConfig != null) {
            _isHourly =
                (activeConfig['pay_type']?.toString().toLowerCase() ??
                    'hourly') ==
                'hourly';
            _baseRate = _num(activeConfig['base_rate']);
            _defaultAllowances = _num(activeConfig['default_allowances']);
            _defaultDeductions =
                activeConfig['default_deductions'] as List<dynamic>? ?? [];
          } else {
            _isHourly = true;
            _baseRate = 0.0;
            _defaultAllowances = 0.0;
            _defaultDeductions = [];
          }
        }
      }

      if (mounted) {
        setState(() {
          _lineItems = items;
          _officialPayslip = latestPayslip;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnack("Error loading records: $e", isError: true);
        });
      }
    }
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  // ==========================================
  // Status change
  // ==========================================

  void _showStatusChangeDialog(String payslipId, String currentStatus) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final status = ctx.status;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Update Payslip Status",
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                // One loop instead of three near-identical ListTiles.
                ..._statuses.map((option) {
                  final (_, fg) = status.forStatus(option);
                  final isCurrent =
                      currentStatus.toLowerCase() == option.toLowerCase();

                  return ListTile(
                    leading: Icon(_statusIcon(option), color: fg),
                    title: Text(option),
                    trailing: isCurrent
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: isCurrent
                        ? null
                        : () => _updateStatus(payslipId, option),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _statusIcon(String status) => switch (status.toLowerCase()) {
    'paid' => Icons.check_circle,
    'cancelled' => Icons.cancel,
    _ => Icons.pending_actions,
  };

  Future<void> _updateStatus(String payslipId, String newStatus) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);
    try {
      await SupabaseService().updatePayslipStatus(payslipId, newStatus);
      await _fetchDetails();
      _showSnack("Status updated to $newStatus");
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack("Error: $e", isError: true);
    }
  }

  // ==========================================
  // Add adjustment
  // ==========================================

  void _showAddAdjustmentDialog() {
    final currency = context.read<UserProvider>().currencySymbol;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    bool isDeduction = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final status = ctx.status;

            return AlertDialog(
              title: const Text("Add Adjustment"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Bonus (+)"),
                          selected: !isDeduction,
                          selectedColor: status.approvedBg,
                          onSelected: isSubmitting
                              ? null
                              : (_) =>
                                    setDialogState(() => isDeduction = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Deduction (-)"),
                          selected: isDeduction,
                          selectedColor: status.rejectedBg,
                          onSelected: isSubmitting
                              ? null
                              : (_) => setDialogState(() => isDeduction = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Item Name (e.g., Uniform, Bonus)",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: "Amount",
                      prefixText: "$currency ",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final amount = double.tryParse(
                            amountController.text.trim().replaceAll(',', '.'),
                          );

                          // These used to `return` silently, so a mistyped
                          // amount looked like a dead button.
                          if (name.isEmpty) {
                            _showSnack("Give the adjustment a name.");
                            return;
                          }
                          if (amount == null || amount <= 0) {
                            _showSnack("Enter an amount greater than zero.");
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            await SupabaseService().addManualPayslipItem(
                              profileId:
                                  widget.employeeSummary['real_profile_id'],
                              itemName: name,
                              amount: amount,
                              isDeduction: isDeduction,
                            );

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            setState(() => _isLoading = true);
                            await _fetchDetails();
                          } catch (e) {
                            _showSnack("Error: $e", isError: true);
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(ctx).colorScheme.onPrimary,
                          ),
                        )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
      // Fresh on every open, previously never released.
    ).then((_) {
      nameController.dispose();
      amountController.dispose();
    });
  }

  // ==========================================
  // Official payslip card
  // ==========================================

  Widget _buildFinancialCard(
    BuildContext context,
    Map<String, dynamic> payslip,
    String currency,
    bool canRunPayroll, // 🚀 Passed in for Bouncer checks
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Was `payslip['net_pay'].toString()`, which rendered "1234.5".
    final netPay = _num(payslip['net_pay']).toStringAsFixed(2);
    final String currentStatus = payslip['status'] ?? 'Pending';
    final (statusBg, statusFg) = context.status.forStatus(currentStatus);
    final isPaid = currentStatus.toLowerCase() == 'paid';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Generated Official Payslip",
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // 🚀 GRANULAR SECURITY: Only Payroll Managers can click to change the status
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: canRunPayroll
                  ? () => _showStatusChangeDialog(payslip['id'], currentStatus)
                  : null, // Locks the click
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle : _statusIcon(currentStatus),
                      size: 16,
                      color: statusFg,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentStatus.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusFg,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (canRunPayroll) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 18, color: statusFg),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              "$currency$netPay",
              style: theme.textTheme.displaySmall?.copyWith(
                color: context.brandText,
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _exportPdf(payslip, currency),
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text("Export Official PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(Map<String, dynamic> payslip, String currency) async {
    // Read the provider before the await, not after.
    final realCompanyName = context.read<UserProvider>().companyName;
    _showSnack("Generating PDF...");

    try {
      await PdfService.generateAndSharePayslip(
        payslip: payslip,
        employeeName: widget.employeeSummary['name'],
        companyName: realCompanyName,
        currencySymbol: currency,
        itemizedBreakdown: _lineItems,
      );
    } catch (e) {
      debugPrint("Payslip PDF failed: $e");
      _showSnack("Couldn't generate the PDF.", isError: true);
    }
  }

  // ==========================================
  // Build
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // 🚀 EXACT MATCHES for your database keys!
    final userProvider = context.watch<UserProvider>();
    final canManagePayslipItems = userProvider.can('manage_payslip_items');
    final canRunPayroll = userProvider.can('run_payroll');

    final currency = userProvider.currencySymbol;
    final emp = widget.employeeSummary;

    final totalMinutes = emp['total_minutes'] ?? 0;
    final shiftsCount = emp['shifts_count'] ?? 0;

    double baselineGross = 0.0;
    if (_isHourly) {
      baselineGross = (totalMinutes / 60.0) * _baseRate;
    } else {
      baselineGross = _baseRate;
    }

    baselineGross += _defaultAllowances;

    double baselineDeductions = 0.0;
    for (var rule in _defaultDeductions) {
      double value = _num(rule['value']);
      if (rule['type'] == 'percentage') {
        baselineDeductions += (baselineGross * (value / 100));
      } else {
        baselineDeductions += value;
      }
    }

    double totalNetPay = baselineGross - baselineDeductions;

    for (var item in _lineItems) {
      double amount = _num(item['amount']);
      if (item['is_deduction'] == true) {
        totalNetPay -= amount;
      } else {
        totalNetPay += amount;
      }
    }

    if (totalNetPay < 0) totalNetPay = 0.0;

    final netSalary = totalNetPay.toStringAsFixed(2);
    final String currentPeriod =
        "${DateFormat('MMM d').format(widget.dateRange.start)} - ${DateFormat('MMM d, yyyy').format(widget.dateRange.end)}";

    return Scaffold(
      appBar: AppBar(title: Text("${emp['name']}'s Details")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          // 🚀 THE ULTIMATE SCROLL FIX: CustomScrollView binds everything together perfectly
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // 1. TOP SUMMARY CARD
                      _buildSummaryHeader(
                        theme: theme,
                        name: emp['name']?.toString() ?? '',
                        netSalary: netSalary,
                        currency: currency,
                        period: currentPeriod,
                        shiftsCount: shiftsCount,
                        totalMinutes: totalMinutes,
                      ),

                      // 2. OFFICIAL PAYSLIP CARD
                      if (_officialPayslip != null)
                        _buildFinancialCard(
                          context,
                          _officialPayslip!,
                          currency,
                          canRunPayroll,
                        ),

                      // 3. ITEMIZED BREAKDOWN HEADER
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: 8.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "One-off Adjustments Registry",
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),

                // 4. THE LINE ITEMS LIST (Using SliverList for perfect scrolling)
                if (_lineItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          "No manual adjustments found for this period.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildLineItem(theme, _lineItems[index], currency),
                      childCount: _lineItems.length,
                    ),
                  ),

                // Padding at the bottom so the FAB doesn't cover the last item
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

      // 🚀 GRANULAR SECURITY: Hide the add button entirely if they lack permission
      floatingActionButton: canManagePayslipItems
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _showAddAdjustmentDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add Adjustment"),
            )
          : null,
    );
  }

  Widget _buildSummaryHeader({
    required ThemeData theme,
    required String name,
    required String netSalary,
    required String currency,
    required String period,
    required dynamic shiftsCount,
    required int totalMinutes,
  }) {
    final scheme = theme.colorScheme;
    // An employee with an empty name used to crash here on name[0].
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(24),
      color: scheme.primaryContainer,
      width: double.infinity,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.surface,
            backgroundImage: _avatarUrl != null
                ? NetworkImage(_avatarUrl!)
                : null,
            child: _avatarUrl == null
                ? Text(
                    initial,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: context.brandText,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            "REAL-TIME ESTIMATE",
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            "$currency$netSalary",
            style: theme.textTheme.displayMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            period,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryChip(theme, Icons.calendar_today, "$shiftsCount Shifts"),
              _summaryChip(
                theme,
                _isHourly
                    ? Icons.timer_outlined
                    : Icons.monetization_on_outlined,
                _isHourly
                    ? _formatDuration(totalMinutes)
                    : "Salary Base Contract",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(ThemeData theme, IconData icon, String label) => Chip(
    avatar: Icon(icon, size: 14, color: context.brandText),
    backgroundColor: theme.colorScheme.surface,
    label: Text(label, style: theme.textTheme.labelMedium),
  );

  Widget _buildLineItem(
    ThemeData theme,
    Map<String, dynamic> item,
    String currency,
  ) {
    final isDeduction = item['is_deduction'] == true;
    final amount = _num(item['amount']).toStringAsFixed(2);
    final status = context.status;

    final (bg, fg) = isDeduction
        ? (status.rejectedBg, status.rejectedFg)
        : (status.approvedBg, status.approvedFg);

    final String date = item['created_at'] != null
        ? DateFormat(
            'MMM dd, yyyy',
          ).format(DateTime.parse(item['created_at']).toLocal())
        : DateFormat('MMM dd, yyyy').format(DateTime.now());

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: bg,
        child: Icon(isDeduction ? Icons.remove : Icons.add, color: fg),
      ),
      title: Text(
        item['item_name'] ?? 'Manual Item',
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(date),
      trailing: Text(
        "${isDeduction ? '-' : '+'}$currency$amount",
        style: theme.textTheme.titleMedium?.copyWith(
          color: isDeduction ? theme.colorScheme.error : context.brandText,
        ),
      ),
    );
  }
}
