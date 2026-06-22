import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/user_provider.dart';
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

      if (user != null) {
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
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching payslips: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00A36C)),
        ),
      );
    }

    if (_payslips.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'My Payslips',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            "No payslips generated yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final latestPayslip = _payslips.first;
    final history = _payslips.length > 1 ? _payslips.sublist(1) : [];

    final currency = context.watch<UserProvider>().currencySymbol;
    final companyName = context.read<UserProvider>().companyName;
    final employeeName = context.read<UserProvider>().fullName ?? "Employee";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'My Payslips',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        // 🚀 WEB FIX: Center and Constrain the width
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Latest Payslip",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.blueGrey,
                      letterSpacing: 1.1,
                    ),
                  ),
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
                    Text(
                      "Payment History",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.blueGrey,
                        letterSpacing: 1.1,
                      ),
                    ),
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
      ),
    );
  }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🚀 DECIMAL FIX: Format all values to exactly 2 decimal places
    final netPay =
        (double.tryParse(payslip['net_pay']?.toString() ?? '0') ?? 0.0)
            .toStringAsFixed(2);
    final grossPayVal =
        double.tryParse(payslip['gross_pay']?.toString() ?? '0') ?? 0.0;
    final totalTaxVal =
        double.tryParse(payslip['tax']?.toString() ?? '0') ?? 0.0;
    final totalDedVal =
        double.tryParse(payslip['deductions']?.toString() ?? '0') ?? 0.0;

    final String currentStatus = payslip['status'] ?? 'Pending';
    final bool isPaid = currentStatus.toLowerCase() == 'paid';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- NET PAY ---
                const Text(
                  "NET PAY",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "$currency$netPay",
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00A36C),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey.withOpacity(0.1), height: 1),

          // --- 🚀 DYNAMIC ITEMIZED BREAKDOWN ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[900]?.withOpacity(0.5)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Earnings",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildListRow(
                  "Gross Pay",
                  "+ $currency${grossPayVal.toStringAsFixed(2)}",
                  isPositive: true,
                ),

                const SizedBox(height: 16),
                const Text(
                  "Deductions",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),

                if (totalTaxVal > 0)
                  _buildListRow(
                    "Tax (PAYE)",
                    "- $currency${totalTaxVal.toStringAsFixed(2)}",
                    isPositive: false,
                  ),

                // Map through actual deduction rules (like UIF)
                ...deductionRules.map((rule) {
                  double ruleAmount = 0.0;
                  if (rule['type'] == 'percentage') {
                    ruleAmount =
                        grossPayVal *
                        ((double.tryParse(rule['value'].toString()) ?? 0.0) /
                            100);
                  } else {
                    ruleAmount =
                        double.tryParse(rule['value'].toString()) ?? 0.0;
                  }

                  return _buildListRow(
                    rule['name'] ?? "Deduction",
                    "- $currency${ruleAmount.toStringAsFixed(2)}",
                    isPositive: false,
                  );
                }),

                if (deductionRules.isEmpty &&
                    totalTaxVal == 0 &&
                    totalDedVal > 0)
                  _buildListRow(
                    "Other Deductions",
                    "- $currency${totalDedVal.toStringAsFixed(2)}",
                    isPositive: false,
                  ),

                const SizedBox(height: 16),
                Divider(color: Colors.grey.withOpacity(0.2)),
                const SizedBox(height: 16),

                // --- EXPORT BUTTON ---
                ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Generating Official PDF..."),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    await PdfService.generateAndSharePayslip(
                      payslip: payslip,
                      employeeName: employeeName,
                      companyName: companyName,
                      currencySymbol: currency,
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    "Download Payslip PDF",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(
    String title,
    String amount, {
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? const Color(0xFF00A36C) : Colors.redAccent,
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
  final List<dynamic> history;
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
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final isPaid = (item['status'] ?? '').toLowerCase() == 'paid';

        // 🚀 DECIMAL FIX FOR HISTORY LIST TOO
        final netPayStr =
            (double.tryParse(item['net_pay']?.toString() ?? '0') ?? 0.0)
                .toStringAsFixed(2);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: isPaid
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.pending_actions,
                color: isPaid ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              item['month_year'] ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Status: ${item['status'] ?? 'Pending'}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$currency$netPayStr",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.grey),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Downloading PDF..."),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    await PdfService.generateAndSharePayslip(
                      payslip: item,
                      employeeName: employeeName,
                      companyName: companyName,
                      currencySymbol: currency,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
