import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart'; // 🚀 Added unified picker
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_specifics.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_summary.dart';
import 'package:klockerapp/utils/widgets/k_filter_pills.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];

  // --- UNIFIED DATE STATE ---
  List<DateTime?> _currentSelection = [DateTime.now()];
  bool _isRangeMode = false;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedDateRange;

  // --- PILL FILTER STATE ---
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Overtime', 'Early Leave'];

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

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

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final records = _isRangeMode && _selectedDateRange != null
          ? await SupabaseService().getCompanyAttendanceByDateRange(
              _selectedDateRange!.start,
              _selectedDateRange!.end,
            )
          : await SupabaseService().getCompanyAttendanceByDate(_selectedDate);

      if (mounted) setState(() => _records = records);
    } catch (e) {
      _showSnack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FILTERING ENGINE ---
  List<Map<String, dynamic>> get _filteredRecords {
    if (_activeFilter == 'All') return _records;
    return _records.where((record) {
      final String rawStatus = record['raw_status'] ?? '';
      if (_activeFilter == 'Overtime') {
        return rawStatus == 'overtime_pending';
      }
      if (_activeFilter == 'Early Leave') {
        return rawStatus == 'early_leave_pending';
      }
      return true;
    }).toList();
  }

  // 🚀 THE UNIFIED PICKER LOGIC
  Future<void> _pickDateOrRange() async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = theme.textTheme.bodyMedium!;

    final values = await showCalendarDatePicker2Dialog(
      context: context,
      // calendar_date_picker2 is a package widget — it reads none of this
      // from ThemeData, so every style has to be handed to it or it falls
      // back to its own black-on-white defaults (unreadable in dark mode).
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range, // Allows 1 OR 2 selections
        selectedDayHighlightColor: scheme.primary,
        selectedRangeHighlightColor: scheme.primaryContainer,
        selectedDayTextStyle: body.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        dayTextStyle: body.copyWith(color: scheme.onSurface),
        disabledDayTextStyle: body.copyWith(color: scheme.outline),
        todayTextStyle: body.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.bold,
        ),
        weekdayLabelTextStyle: theme.textTheme.labelMedium!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        controlsTextStyle: theme.textTheme.titleSmall!.copyWith(
          color: scheme.onSurface,
        ),
        okButtonTextStyle: theme.textTheme.labelLarge!.copyWith(
          color: scheme.primary,
        ),
        cancelButtonTextStyle: theme.textTheme.labelLarge!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dialogSize: const Size(325, 400),
      dialogBackgroundColor: scheme.surface,
      value: _currentSelection,
      borderRadius: BorderRadius.circular(15),
    );

    if (values == null || values.isEmpty || !mounted) return;

    setState(() {
      _currentSelection = values;

      // Logic to determine if they picked a single day or a range
      if (values.length == 1 ||
          (values.length == 2 && values[0] == values[1])) {
        _isRangeMode = false;
        _selectedDate = values[0]!;
        _selectedDateRange = null;
      } else if (values.length == 2) {
        _isRangeMode = true;
        _selectedDateRange = DateTimeRange(start: values[0]!, end: values[1]!);
      }
    });

    _fetchAttendance();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final now = DateTime.now();
    final isToday =
        !_isRangeMode &&
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    // Walked the list twice before — once for isEmpty, once to pass down.
    final visibleRecords = _filteredRecords;

    return RefreshIndicator(
      onRefresh: _fetchAttendance,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🚀 SMART UNIFIED DATE BANNER
                    _buildDateBanner(theme),

                    const SizedBox(height: 16),
                    AttendanceSummary(records: _records),
                    const SizedBox(height: 20),

                    // --- SLEEK PILL FILTERS ---
                    KFilterPills(
                      filters: _filters,
                      selected: _activeFilter,
                      onSelected: (filter) =>
                          setState(() => _activeFilter = filter),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _isRangeMode
                          ? "Shifts for Selected Range"
                          : (isToday
                                ? "Today's Shifts"
                                : "Shifts on ${DateFormat('dd MMM yyyy').format(_selectedDate)}"),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),

                    if (visibleRecords.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            _activeFilter == 'All'
                                ? "No records found."
                                : "No ${_activeFilter.toLowerCase()} records for this period.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      AttendanceSpecifics(
                        records: visibleRecords,
                        onRefresh: _fetchAttendance,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateBanner(ThemeData theme) {
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: _pickDateOrRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: scheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _isRangeMode && _selectedDateRange != null
                    ? "${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)}  -  ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}"
                    : DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                style: theme.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
