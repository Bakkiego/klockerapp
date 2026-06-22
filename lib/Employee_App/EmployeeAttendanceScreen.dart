import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  State<EmployeeAttendanceScreen> createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final records = await SupabaseService().getMyAttendance();
      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading attendance: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper to format timestamps from Supabase
  String _formatTime(String? timestamp) {
    if (timestamp == null) return "--:--";
    final date = DateTime.parse(timestamp).toLocal();
    return DateFormat('hh:mm a').format(date); // e.g., 08:30 AM
  }

  // Helper to format dates
  String _formatDate(String? timestamp) {
    if (timestamp == null) return "Unknown Date";
    final date = DateTime.parse(timestamp).toLocal();
    return DateFormat('MMM dd, yyyy').format(date); // e.g., Oct 24, 2024
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _attendanceRecords.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchAttendance,
              color: const Color(0xFF00A36C),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = _attendanceRecords[index];

                  final clockIn = record['clock_in'];
                  final clockOut = record['clock_out'];
                  final status =
                      record['status'] ?? 'completed'; // From your SQL!
                  final minutes = record['standard_minutes'] ?? 0;

                  final hoursWorked = (minutes / 60).toStringAsFixed(1);
                  final isOngoing = clockOut == null;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Date & Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 🚀 FIXED: Expanded forces the text to take available space without pushing the badge off screen
                              Expanded(
                                child: Text(
                                  _formatDate(clockIn),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(isOngoing, status),
                            ],
                          ),
                          const Divider(height: 24),

                          // Middle Row: Clock In & Out Times
                          Row(
                            children: [
                              // 🚀 FIXED: Expanded makes the columns share 50/50 space perfectly
                              Expanded(
                                child: _buildTimeColumn(
                                  "Clock In",
                                  _formatTime(clockIn),
                                  Icons.login,
                                  Colors.green,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: _buildTimeColumn(
                                  "Clock Out",
                                  _formatTime(clockOut),
                                  Icons.logout,
                                  isOngoing ? Colors.grey : Colors.red,
                                ),
                              ),
                            ],
                          ),

                          // Bottom Row: Total Hours (Only show if clocked out)
                          if (!isOngoing) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  // 🚀 FIXED: Flexible prevents long hour/minute strings from breaking the Row
                                  Flexible(
                                    child: Text(
                                      "Total Time: $hoursWorked hrs ($minutes mins)",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // Helper widget to make times look clean
  // Helper widget to make times look clean
  Widget _buildTimeColumn(
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          overflow: TextOverflow.ellipsis, // Prevents label overflow
        ),
        FittedBox(
          // 🚀 NEW: Magically shrinks the text if it's too wide!
          fit: BoxFit.scaleDown,
          child: Text(
            time,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Helper widget for the Status Pill (Catches your "Early Leave" SQL logic!)
  Widget _buildStatusBadge(bool isOngoing, String status) {
    Color bgColor = Colors.green.withOpacity(0.1);
    Color textColor = Colors.green;
    String label = "Completed";

    if (isOngoing) {
      bgColor = Colors.blue.withOpacity(0.1);
      textColor = Colors.blue;
      label = "Active Shift";
    } else if (status == 'early_leave_pending_approval') {
      bgColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      label = "Early Leave";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "No attendance records yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your clock-in history will appear here",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
