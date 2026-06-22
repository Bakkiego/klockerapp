import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_specifics.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/attendance_summary.dart';
import 'package:klockerapp/screens/employee-screens/components/time_management_components/custom_date_picker.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];
  DateTime _selectedDate = DateTime.now();

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
      final records = await SupabaseService().getCompanyAttendanceByDate(
        _selectedDate,
      );
      if (mounted) setState(() => _records = records);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
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

  void _onDateChanged(DateTime newDate) {
    setState(() => _selectedDate = newDate);
    _fetchAttendance();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isToday =
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
                    CustomDatePicker(
                      initialDate: _selectedDate,
                      onDateSelected: _onDateChanged,
                    ),
                    AttendanceSummary(records: _records),

                    const SizedBox(height: 20),

                    // --- SLEEK PILL FILTERS (STYLING FROM LEAVE SCREEN) ---
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
                      isToday
                          ? "Today's Shifts"
                          : "Shifts on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
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
