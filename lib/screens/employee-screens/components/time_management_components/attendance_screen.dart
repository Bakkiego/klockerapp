import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart'; // 🚀 Added unified picker
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_specifics.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_summary.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FILTERING ENGINE ---
  List<Map<String, dynamic>> get _filteredRecords {
    if (_activeFilter == 'All') return _records;
    return _records.where((record) {
      final String rawStatus = record['raw_status'] ?? '';
      if (_activeFilter == 'Overtime') return rawStatus == 'overtime_pending';
      if (_activeFilter == 'Early Leave')
        return rawStatus == 'early_leave_pending';
      return true;
    }).toList();
  }

  // 🚀 THE UNIFIED PICKER LOGIC
  Future<void> _pickDateOrRange() async {
    final values = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range, // Allows 1 OR 2 selections
        selectedDayHighlightColor: const Color(0xFF00A36C),
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        controlsTextStyle: const TextStyle(
          color: Color(0xFF00A36C),
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogSize: const Size(325, 400),
      value: _currentSelection,
      borderRadius: BorderRadius.circular(15),
    );

    if (values != null && values.isNotEmpty) {
      setState(() {
        _currentSelection = values;

        // Logic to determine if they picked a single day or a range
        if (values.length == 1 ||
            (values.length == 2 && values[0] == values[1])) {
          _isRangeMode = false;
          _selectedDate = values[0]!;
        } else if (values.length == 2) {
          _isRangeMode = true;
          _selectedDateRange = DateTimeRange(
            start: values[0]!,
            end: values[1]!,
          );
        }
      });

      _fetchAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isToday =
        !_isRangeMode &&
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return RefreshIndicator(
      color: const Color(0xFF00A36C),
      onRefresh: _fetchAttendance,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🚀 SMART UNIFIED DATE BANNER
                    GestureDetector(
                      onTap: _pickDateOrRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.surface
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF00A36C).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A36C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF00A36C),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _isRangeMode && _selectedDateRange != null
                                    ? "${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)}  -  ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}"
                                    : DateFormat(
                                        'EEEE, MMM d, yyyy',
                                      ).format(_selectedDate),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    AttendanceSummary(records: _records),
                    const SizedBox(height: 20),

                    // --- SLEEK PILL FILTERS ---
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = _activeFilter == filter;

                          return GestureDetector(
                            onTap: () => setState(() => _activeFilter = filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(
                                right: 10,
                                top: 5,
                                bottom: 5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
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

                    const SizedBox(height: 20),

                    Text(
                      _isRangeMode
                          ? "Shifts for Selected Range"
                          : (isToday
                                ? "Today's Shifts"
                                : "Shifts on ${DateFormat('dd MMM yyyy').format(_selectedDate)}"),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _filteredRecords.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                "No records found.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : AttendanceSpecifics(
                            records: _filteredRecords,
                            onRefresh: _fetchAttendance,
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
