import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

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
            _baseRate =
                double.tryParse(activeConfig['base_rate']?.toString() ?? '0') ??
                0.0;
            _defaultAllowances =
                double.tryParse(
                  activeConfig['default_allowances']?.toString() ?? '0',
                ) ??
                0.0;
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error loading records: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        });
      }
    }
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  void _showStatusChangeDialog(String payslipId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Update Payslip Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  title: const Text("Pending"),
                  trailing: currentStatus == 'Pending'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _updateStatus(payslipId, "Pending"),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text("Paid"),
                  trailing: currentStatus == 'Paid'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _updateStatus(payslipId, "Paid"),
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text("Cancelled"),
                  trailing: currentStatus == 'Cancelled'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _updateStatus(payslipId, "Cancelled"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(String payslipId, String newStatus) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);
    try {
      await SupabaseService().updatePayslipStatus(payslipId, newStatus);
      await _fetchDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to $newStatus"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddAdjustmentDialog() {
    final currency = context.read<UserProvider>().currencySymbol;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    bool isDeduction = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Add Adjustment",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Bonus (+)"),
                          selected: !isDeduction,
                          selectedColor: Colors.green.shade100,
                          onSelected: (val) =>
                              setDialogState(() => isDeduction = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Deduction (-)"),
                          selected: isDeduction,
                          selectedColor: Colors.red.shade100,
                          onSelected: (val) =>
                              setDialogState(() => isDeduction = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Item Name (e.g., Uniform, Bonus)",
                      border: OutlineInputBorder(),
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
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nameController.text.isEmpty ||
                              amountController.text.isEmpty)
                            return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await SupabaseService().addManualPayslipItem(
                              profileId:
                                  widget.employeeSummary['real_profile_id'],
                              itemName: nameController.text.trim(),
                              amount: double.parse(
                                amountController.text.trim(),
                              ),
                              isDeduction: isDeduction,
                            );

                            if (!mounted) return;
                            Navigator.pop(context);
                            setState(() => _isLoading = true);
                            await _fetchDetails();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFinancialCard(
    BuildContext context,
    Map<String, dynamic> payslip,
    String currency,
    bool canRunPayroll, // 🚀 Passed in for Bouncer checks
  ) {
    final theme = Theme.of(context);
    final netPay = payslip['net_pay']?.toString() ?? "0.00";
    final String currentStatus = payslip['status'] ?? 'Pending';
    final bool isPaid = currentStatus.toLowerCase() == 'paid';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Generated Official Payslip",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          // 🚀 GRANULAR SECURITY: Only Payroll Managers can click to change the status
          GestureDetector(
            onTap: canRunPayroll
                ? () => _showStatusChangeDialog(payslip['id'], currentStatus)
                : null, // Locks the click
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isPaid
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPaid
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaid ? Icons.check_circle : Icons.pending_actions,
                    size: 16,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentStatus.toUpperCase(),
                    style: TextStyle(
                      color: isPaid ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (canRunPayroll) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: isPaid ? Colors.green : Colors.orange,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            "$currency$netPay",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A36C),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Generating PDF..."),
                  duration: Duration(seconds: 1),
                ),
              );
              final realCompanyName = context.read<UserProvider>().companyName;

              await PdfService.generateAndSharePayslip(
                payslip: payslip,
                employeeName: widget.employeeSummary['name'],
                companyName: realCompanyName,
                currencySymbol: currency,
                itemizedBreakdown: _lineItems,
              );
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text("Export Official PDF"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      double value = double.tryParse(rule['value']?.toString() ?? '0') ?? 0.0;
      if (rule['type'] == 'percentage') {
        baselineDeductions += (baselineGross * (value / 100));
      } else {
        baselineDeductions += value;
      }
    }

    double totalNetPay = baselineGross - baselineDeductions;

    for (var item in _lineItems) {
      double amount = (item['amount'] as num).toDouble();
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
      appBar: AppBar(
        title: Text("${emp['name']}'s Details"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          // 🚀 THE ULTIMATE SCROLL FIX: CustomScrollView binds everything together perfectly
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // 1. TOP SUMMARY CARD
                      Container(
                        padding: const EdgeInsets.all(24),
                        color: const Color(0xFF00A36C).withOpacity(0.1),
                        width: double.infinity,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(
                                0xFF00A36C,
                              ).withOpacity(0.2),
                              backgroundImage: _avatarUrl != null
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                              child: _avatarUrl == null
                                  ? Text(
                                      emp['name'][0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00A36C),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "REAL-TIME ESTIMATE",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              "$currency$netSalary",
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF00A36C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentPeriod,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Chip(
                                  avatar: const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Color(0xFF00A36C),
                                  ),
                                  backgroundColor: Colors.white.withOpacity(
                                    0.6,
                                  ),
                                  label: Text(
                                    "$shiftsCount Shifts",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  avatar: Icon(
                                    _isHourly
                                        ? Icons.timer_outlined
                                        : Icons.monetization_on_outlined,
                                    size: 14,
                                    color: Color(0xFF00A36C),
                                  ),
                                  backgroundColor: Colors.white.withOpacity(
                                    0.6,
                                  ),
                                  label: Text(
                                    _isHourly
                                        ? _formatDuration(totalMinutes)
                                        : "Salary Base Contract",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                          children: const [
                            Icon(Icons.receipt_long, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              "One-off Adjustments Registry",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          "No manual adjustments found for this period.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _lineItems[index];
                      final isDeduction = item['is_deduction'] == true;
                      final amount = (item['amount'] as num)
                          .toDouble()
                          .toStringAsFixed(2);
                      final String date = item['created_at'] != null
                          ? DateFormat('MMM dd, yyyy').format(
                              DateTime.parse(item['created_at']).toLocal(),
                            )
                          : DateFormat('MMM dd, yyyy').format(DateTime.now());

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDeduction
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          child: Icon(
                            isDeduction ? Icons.remove : Icons.add,
                            color: isDeduction ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(
                          item['item_name'] ?? 'Manual Item',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(date),
                        trailing: Text(
                          "${isDeduction ? '-' : '+'}$currency$amount",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDeduction ? Colors.red : Colors.green,
                          ),
                        ),
                      );
                    }, childCount: _lineItems.length),
                  ),

                // Padding at the bottom so the FAB doesn't cover the last item
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

      // 🚀 GRANULAR SECURITY: Hide the add button entirely if they lack permission
      floatingActionButton: canManagePayslipItems
          ? FloatingActionButton.extended(
              onPressed: _showAddAdjustmentDialog,
              backgroundColor: const Color(0xFF00A36C),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Adjustment",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
