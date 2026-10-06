import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/user_provider.dart';
import '../utils/custom_theme/k_palette.dart';
import '../utils/pdf_service.dart';

class EmployeePayslipScreen extends StatefulWidget {
  const EmployeePayslipScreen({super.key});

  @override
  State<EmployeePayslipScreen> createState() => _EmployeePayslipScreenState();
}

class _EmployeePayslipScreenState extends State<EmployeePayslipScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _payslips = [];
  List<dynamic> _myDeductionRules = []; // 🚀 To hold dynamic deduction rules

  @override
  void initState() {
    super.initState();
    _fetchPayslips();
  }

  Future<void> _fetchPayslips() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      // No session — nothing to fetch, but the `finally` below still has to
      // clear the spinner. The old version left it spinning forever.
      if (user == null) return;

      // 1. Fetch Payslips
      final data = await SupabaseService().getMyPayslips();

      // 2. Fetch the user's specific deduction rules to show in the breakdown
      final profile = await supabase
          .from('profiles')
          .select('salary_configs(default_deductions)')
          .eq('id', user.id)
          .maybeSingle();

      List<dynamic> rules = [];
      if (profile != null && profile['salary_configs'] != null) {
        final configs = profile['salary_configs'];
        if (configs is List && configs.isNotEmpty) {
          rules = configs[0]['default_deductions'] ?? [];
        } else if (configs is Map) {
          rules = configs['default_deductions'] ?? [];
        }
      }

      if (mounted) {
        setState(() {
          _payslips = data;
          _myDeductionRules = rules;
        });
      }
    } catch (e) {
      debugPrint("Error fetching payslips: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Read once, unconditionally — watching inside an `if` means the screen
    // wouldn't rebuild on a currency change while the list is empty.
    final userProvider = context.watch<UserProvider>();
    final currency = userProvider.currencySymbol;
    final companyName = userProvider.companyName;
    final employeeName = userProvider.fullName ?? "Employee";

    final Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_payslips.isEmpty) {
      body = Center(
        child: Text(
          "No payslips generated yet.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      final latestPayslip = _payslips.first;
      final history = _payslips.skip(1).toList();

      body = SafeArea(
        // 🚀 WEB FIX: Center and Constrain the width
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(theme, "Latest Payslip"),
                  const SizedBox(height: 12),

                  LatestPayslipCard(
                    payslip: latestPayslip,
                    currency: currency,
                    companyName: companyName,
                    employeeName: employeeName,
                    deductionRules:
                        _myDeductionRules, // 🚀 Pass rules to the card
                  ),

                  const SizedBox(height: 32),

                  if (history.isNotEmpty) ...[
                    _sectionLabel(theme, "Payment History"),
                    const SizedBox(height: 12),

                    PayslipHistoryList(
                      history: history,
                      currency: currency,
                      companyName: companyName,
                      employeeName: employeeName,
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // One Scaffold instead of three near-identical ones.
    return Scaffold(
      appBar: AppBar(title: const Text('My Payslips')),
      body: body,
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(
    text,
    style: theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 1.1,
    ),
  );
}

// ==========================================
// --- LATEST PAYSLIP CARD WIDGET ---
// ==========================================
class LatestPayslipCard extends StatelessWidget {
  final Map<String, dynamic> payslip;
  final String currency;
  final String? companyName;
  final String employeeName;
  final List<dynamic> deductionRules;

  const LatestPayslipCard({
    super.key,
    required this.payslip,
    required this.currency,
    required this.companyName,
    required this.employeeName,
    required this.deductionRules,
  });

  static double _num(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // 🚀 DECIMAL FIX: Format all values to exactly 2 decimal places
    final netPay = _num(payslip['net_pay']).toStringAsFixed(2);
    final grossPayVal = _num(payslip['gross_pay']);
    final totalTaxVal = _num(payslip['tax']);
    final totalDedVal = _num(payslip['deductions']);

    final String currentStatus = payslip['status'] ?? 'Pending';
    final (statusBg, statusFg) = context.status.forStatus(currentStatus);
    final isPaid = currentStatus.toLowerCase() == 'paid';

    // Build the deduction rows once so the amounts can be reconciled against
    // the stored total below.
    final deductionRows = <Widget>[];
    double itemisedDeductions = 0.0;

    for (final rule in deductionRules) {
      final double ruleValue = _num(rule['value']);
      final double ruleAmount = rule['type'] == 'percentage'
          ? grossPayVal * (ruleValue / 100)
          : ruleValue;

      itemisedDeductions += ruleAmount;
      deductionRows.add(
        _buildListRow(
          context,
          rule['name'] ?? "Deduction",
          "- $currency${ruleAmount.toStringAsFixed(2)}",
          isPositive: false,
        ),
      );
    }

    // Anything in payslip.deductions that the rules don't account for.
    final remainder = totalDedVal - itemisedDeductions;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // --- HEADER: MONTH & STATUS ---
          Padding(
            padding: const EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            child: Column(
              children: [
                Text(
                  payslip['month_year'] ?? "Current Month",
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Container(
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
                        isPaid ? Icons.check_circle : Icons.pending_actions,
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- NET PAY ---
                Text(
                  "NET PAY",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "$currency$netPay",
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: context.brandText,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // --- 🚀 DYNAMIC ITEMIZED BREAKDOWN ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: scheme.surfaceContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _breakdownHeading(theme, "Earnings"),
                const SizedBox(height: 8),
                _buildListRow(
                  context,
                  "Gross Pay",
                  "+ $currency${grossPayVal.toStringAsFixed(2)}",
                  isPositive: true,
                ),

                const SizedBox(height: 16),
                _breakdownHeading(theme, "Deductions"),
                const SizedBox(height: 8),

                if (totalTaxVal > 0)
                  _buildListRow(
                    context,
                    "Tax (PAYE)",
                    "- $currency${totalTaxVal.toStringAsFixed(2)}",
                    isPositive: false,
                  ),

                // Map through actual deduction rules (like UIF)
                ...deductionRows,

                if (remainder > 0.01)
                  _buildListRow(
                    context,
                    "Other Deductions",
                    "- $currency${remainder.toStringAsFixed(2)}",
                    isPositive: false,
                  ),

                if (totalTaxVal == 0 &&
                    deductionRows.isEmpty &&
                    remainder <= 0.01)
                  Text(
                    "No deductions on this payslip.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // --- EXPORT BUTTON ---
                ElevatedButton.icon(
                  onPressed: () => _downloadPdf(context, payslip),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text("Download Payslip PDF"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownHeading(ThemeData theme, String text) => Text(
    text,
    style: theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );

  Future<void> _downloadPdf(
    BuildContext context,
    Map<String, dynamic> slip,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final errorStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: scheme.onError);

    messenger.showSnackBar(
      const SnackBar(
        content: Text("Generating Official PDF..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await PdfService.generateAndSharePayslip(
        payslip: slip,
        employeeName: employeeName,
        companyName: companyName,
        currencySymbol: currency,
      );
    } catch (e) {
      // Previously unguarded — a PDF failure threw into the void and the
      // employee just saw nothing happen.
      debugPrint("Payslip PDF failed: $e");
      messenger.showSnackBar(
        SnackBar(
          content: Text("Couldn't generate the PDF.", style: errorStyle),
          backgroundColor: scheme.error,
        ),
      );
    }
  }

  Widget _buildListRow(
    BuildContext context,
    String title,
    String amount, {
    required bool isPositive,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPositive ? context.brandText : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// --- PAYSLIP HISTORY LIST WIDGET ---
// ==========================================
class PayslipHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final String currency;
  final String? companyName;
  final String employeeName;

  const PayslipHistoryList({
    super.key,
    required this.history,
    required this.currency,
    required this.companyName,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final status = (item['status'] ?? 'Pending').toString();
        final isPaid = status.toLowerCase() == 'paid';
        final (statusBg, statusFg) = context.status.forStatus(status);

        // 🚀 DECIMAL FIX FOR HISTORY LIST TOO
        final netPayStr =
            (double.tryParse(item['net_pay']?.toString() ?? '0') ?? 0.0)
                .toStringAsFixed(2);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: statusBg,
              child: Icon(
                isPaid ? Icons.check_circle : Icons.pending_actions,
                color: statusFg,
                size: 20,
              ),
            ),
            title: Text(
              item['month_year'] ?? "Unknown",
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text("Status: $status"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("$currency$netPayStr", style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: "Download PDF",
                  icon: Icon(
                    Icons.download_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                  onPressed: () => _downloadPdf(context, item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadPdf(
    BuildContext context,
    Map<String, dynamic> slip,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final errorStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: scheme.onError);

    messenger.showSnackBar(
      const SnackBar(
        content: Text("Downloading PDF..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await PdfService.generateAndSharePayslip(
        payslip: slip,
        employeeName: employeeName,
        companyName: companyName,
        currencySymbol: currency,
      );
    } catch (e) {
      debugPrint("Payslip PDF failed: $e");
      messenger.showSnackBar(
        SnackBar(
          content: Text("Couldn't generate the PDF.", style: errorStyle),
          backgroundColor: scheme.error,
        ),
      );
    }
  }
}
