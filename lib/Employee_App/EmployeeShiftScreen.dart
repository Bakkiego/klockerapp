import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:intl/intl.dart';

class EmployeeShiftsScreen extends StatefulWidget {
  const EmployeeShiftsScreen({super.key});

  @override
  _EmployeeShiftsScreenState createState() => _EmployeeShiftsScreenState();
}

class _EmployeeShiftsScreenState extends State<EmployeeShiftsScreen> {
  late Future<List<Map<String, dynamic>>> _myShiftsFuture;

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  void _fetchShifts() {
    setState(() {
      _myShiftsFuture = SupabaseService().getMyUpcomingShifts();
    });
  }

  // Helper to format the "YYYY-MM-DD" string into something readable
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM d').format(date); // e.g., Monday, Oct 24
    } catch (e) {
      return dateStr;
    }
  }

  // Helper to convert hex string to Color object
  Color _hexToColor(String hexCode) {
    return Color(int.parse(hexCode.substring(1, 7), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Upcoming Shifts"),
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _myShiftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading shifts: ${snapshot.error}"),
            );
          }

          final shifts = snapshot.data ?? [];

          if (shifts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No upcoming shifts assigned.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _fetchShifts();
            },
            color: const Color(0xFF00A36C),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                final shift = shifts[index];
                final template = shift['shift_templates'] ?? {};
                final branch = shift['branches'] ?? {};

                final String shiftDate = shift['shift_date'];
                final String shiftName =
                    template['shift_name'] ?? 'Custom Shift';
                final String startTime = template['start_time'] ?? '--:--';
                final String endTime = template['end_time'] ?? '--:--';
                final String colorHex = template['color_hex'] ?? '#00A36C';
                final String branchName = branch['name'] ?? 'Assigned Branch';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border(
                      left: BorderSide(color: _hexToColor(colorHex), width: 6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(shiftDate),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _hexToColor(colorHex),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _hexToColor(colorHex).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                shiftName,
                                style: TextStyle(
                                  color: _hexToColor(colorHex),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${startTime.substring(0, 5)} - ${endTime.substring(0, 5)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              branchName,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
