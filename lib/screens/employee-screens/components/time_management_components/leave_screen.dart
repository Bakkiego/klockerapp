import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  bool _isInitLoading = true;
  bool _isSubmitting = false;

  String? _selectedLeaveType;
  DateTimeRange? _selectedDateRange;

  // 🚀 Stores policy parameters fetched from Supabase
  List<Map<String, dynamic>> _allowanceOptions = [];

  @override
  void initState() {
    super.initState();
    _loadPolicyAllowances();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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

  Future<void> _loadPolicyAllowances() async {
    try {
      final allowances = await SupabaseService().getEmployeeLeaveAllowances();
      if (!mounted) return;
      setState(() {
        _allowanceOptions = allowances;
        if (allowances.isNotEmpty) {
          _selectedLeaveType = allowances.first['leave_type']?.toString();
        }
      });
    } catch (e) {
      _showSnack("Error loading policies: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isInitLoading = false);
    }
  }

  /// Quick utility to pull the current active selection's map data.
  ///
  /// This used to `firstWhere(..., orElse: () => {})`, which handed back an
  /// EMPTY map rather than null — so the `!= null` checks below passed and
  /// then `allowance['entitled_days'] as num` threw on the missing key.
  Map<String, dynamic>? get _currentSelectedAllowance {
    if (_selectedLeaveType == null) return null;
    for (final option in _allowanceOptions) {
      if (option['leave_type']?.toString() == _selectedLeaveType) {
        return option;
      }
    }
    return null;
  }

  /// Calendar days between the two dates, inclusive of both ends.
  ///
  /// NOTE: this counts weekends. If your leave policy deducts working days
  /// only, this number and `remaining_days` are measuring different things.
  int get _requestedDaysCount {
    if (_selectedDateRange == null) return 0;
    return _selectedDateRange!.end
            .difference(_selectedDateRange!.start)
            .inDays +
        1;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange,
      saveText: 'CONFIRM',
      // No `builder:` override. The old one forced a green app bar and
      // replaced colorScheme.surface with the scaffold background, which
      // rendered the picker unusable in dark mode. datePickerTheme in
      // k_theme.dart covers this — see the range fields noted in chat.
    );

    if (picked == null || !mounted) return;
    setState(() => _selectedDateRange = picked);
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateRange == null) {
      _showSnack("Please select the dates you need off.", isError: true);
      return;
    }
    if (_selectedLeaveType == null) {
      _showSnack("Please choose a leave type.", isError: true);
      return;
    }

    // 🚀 POLICY ENFORCEMENT CHECK: Prevent overflow request values
    final currentAlloc = _currentSelectedAllowance;
    if (currentAlloc != null) {
      final double remaining = _num(currentAlloc['remaining_days']);
      if (_requestedDaysCount > remaining) {
        _showSnack(
          "Insufficient balance. You requested $_requestedDaysCount days "
          "but only have ${remaining.toStringAsFixed(0)} left.",
          isError: true,
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final navigator = Navigator.of(context);

    try {
      await SupabaseService().submitLeaveRequest(
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        leaveType: _selectedLeaveType!,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;
      _showSnack("Leave request submitted.");
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      // Only reset here — on success this screen is already gone.
      setState(() => _isSubmitting = false);
      _showSnack("Error: $e", isError: true);
    }
  }

  // ==========================================
  // Build
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeAlloc = _currentSelectedAllowance;

    return Scaffold(
      appBar: AppBar(title: const Text("Request Time Off")),
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator())
          : _allowanceOptions.isEmpty
          ? _buildNoPoliciesState(theme)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // --- 1. DYNAMIC LEAVE TYPE DROPDOWN ---
                  _sectionLabel(theme, "Leave Type"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLeaveType,
                    isExpanded: true,
                    dropdownColor: scheme.surface,
                    items: _allowanceOptions
                        .map(
                          (opt) => DropdownMenuItem<String>(
                            value: opt['leave_type'].toString(),
                            child: Text(opt['leave_type'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedLeaveType = value),
                  ),
                  const SizedBox(height: 20),

                  // --- 🚀 NEW: DYNAMIC BALANCE VISUAL PREVIEW CARD ---
                  if (activeAlloc != null) ...[
                    _buildBalanceCard(theme, activeAlloc),
                    const SizedBox(height: 24),
                  ],

                  // --- 2. DATE RANGE PICKER ---
                  _sectionLabel(theme, "Dates Requested"),
                  const SizedBox(height: 8),
                  _buildDateField(theme),
                  const SizedBox(height: 24),

                  // --- 3. REASON TEXT BOX ---
                  _sectionLabel(theme, "Reason (Optional)"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Briefly explain why you need this time off...",
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- 4. SUBMIT BUTTON ---
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      child: _isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : const Text("Submit Request"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) =>
      Text(text, style: theme.textTheme.titleMedium);

  Widget _buildBalanceCard(ThemeData theme, Map<String, dynamic> alloc) {
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            theme,
            "Entitled",
            "${_num(alloc['entitled_days']).toStringAsFixed(0)} d",
            scheme.onSurface,
          ),
          _buildMetricItem(
            theme,
            "Used",
            "${_num(alloc['used_days']).toStringAsFixed(0)} d",
            context.status.pendingFg,
          ),
          _buildMetricItem(
            theme,
            "Available",
            "${_num(alloc['remaining_days']).toStringAsFixed(0)} d",
            context.brandText,
            isBoldMetric: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(ThemeData theme) {
    final scheme = theme.colorScheme;
    final hasRange = _selectedDateRange != null;

    return InkWell(
      onTap: _pickDateRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasRange
                        ? "${DateFormat('MMM dd').format(_selectedDateRange!.start)}  -  ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}"
                        : "Tap to select dates",
                    style: hasRange
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                  ),
                  if (hasRange) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Total request: $_requestedDaysCount days",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.brandText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasRange)
              IconButton(
                tooltip: "Clear dates",
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _selectedDateRange = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    ThemeData theme,
    String title,
    String data,
    Color displayColor, {
    bool isBoldMetric = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: isBoldMetric ? FontWeight.w900 : FontWeight.bold,
            color: displayColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNoPoliciesState(ThemeData theme) {
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: context.status.pendingFg,
            ),
            const SizedBox(height: 16),
            Text(
              "No Leave Policy Set",
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Your company hasn't set up leave allocation rules yet. "
              "Ask a workspace admin to add leave types before requesting time off.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
