import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
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

  Future<void> _loadPolicyAllowances() async {
    try {
      final allowances = await SupabaseService().getEmployeeLeaveAllowances();
      if (mounted) {
        setState(() {
          _allowanceOptions = allowances;
          if (allowances.isNotEmpty) {
            _selectedLeaveType = allowances.first['leave_type'];
          }
          _isInitLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error launching policies: $e")));
      }
    }
  }

  // Quick utility to pull the current active selection's map data
  Map<String, dynamic>? get _currentSelectedAllowance {
    if (_selectedLeaveType == null) return null;
    return _allowanceOptions.firstWhere(
      (element) => element['leave_type'] == _selectedLeaveType,
      orElse: () => {},
    );
  }

  // Calculates requested business days (inclusive bounds)
  int get _requestedDaysCount {
    if (_selectedDateRange == null) return 0;
    return _selectedDateRange!.end
            .difference(_selectedDateRange!.start)
            .inDays +
        1;
  }

  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();
    final theme = Theme.of(context);

    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      saveText: 'CONFIRM',
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
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select the dates you need off."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 🚀 POLICY ENFORCEMENT CHECK: Prevent overflow request values
    final currentAlloc = _currentSelectedAllowance;
    if (currentAlloc != null) {
      final double remaining = (currentAlloc['remaining_days'] as num)
          .toDouble();
      if (_requestedDaysCount > remaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Insufficient Balance! You requested $_requestedDaysCount days but only have ${remaining.toStringAsFixed(0)} left.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      await SupabaseService().submitLeaveRequest(
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        leaveType: _selectedLeaveType!,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Leave Request Submitted!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeAlloc = _currentSelectedAllowance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Request Time Off",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isInitLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _allowanceOptions.isEmpty
          ? _buildNoPoliciesState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // --- 1. DYNAMIC LEAVE TYPE DROPDOWN ---
                  const Text(
                    "Leave Type",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLeaveType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.05),
                    ),
                    items: _allowanceOptions
                        .map(
                          (opt) => DropdownMenuItem<String>(
                            value: opt['leave_type'].toString(),
                            child: Text(opt['leave_type'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _selectedLeaveType = value;
                    }),
                  ),
                  const SizedBox(height: 20),

                  // --- 🚀 NEW: DYNAMIC BALANCE VISUAL PREVIEW CARD ---
                  if (activeAlloc != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A36C).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF00A36C).withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricItem(
                            "Entitled",
                            "${(activeAlloc['entitled_days'] as num).toStringAsFixed(0)} d",
                            Colors.grey.shade700,
                          ),
                          _buildMetricItem(
                            "Used",
                            "${(activeAlloc['used_days'] as num).toStringAsFixed(0)} d",
                            Colors.amber.shade800,
                          ),
                          _buildMetricItem(
                            "Available",
                            "${(activeAlloc['remaining_days'] as num).toStringAsFixed(0)} d",
                            const Color(0xFF00A36C),
                            isBoldMetric: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- 2. DATE RANGE PICKER ---
                  const Text(
                    "Dates Requested",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.withOpacity(0.05),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: Color(0xFF00A36C),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedDateRange == null
                                      ? "Tap to select dates"
                                      : "${DateFormat('MMM dd').format(_selectedDateRange!.start)}  -  ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDateRange == null
                                        ? Colors.grey
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                    fontWeight: _selectedDateRange == null
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                if (_selectedDateRange != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Total Request: $_requestedDaysCount Days",
                                    style: const TextStyle(
                                      color: Color(0xFF00A36C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 3. REASON TEXT BOX ---
                  const Text(
                    "Reason (Optional)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Briefly explain why you need this time off...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.05),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- 4. SUBMIT BUTTON ---
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A36C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Submit Request",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricItem(
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
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isBoldMetric ? FontWeight.w900 : FontWeight.bold,
            color: displayColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNoPoliciesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 16),
            const Text(
              "No Leave Layout Set",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Your company configuration hasn't declared official allocation rules yet. Please contact an authorized workspace admin to set system categories.",
              style: TextStyle(color: Colors.grey, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
