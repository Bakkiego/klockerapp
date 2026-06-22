import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:provider/provider.dart'; // 🚀 Added for Permissions
import 'package:klockerapp/providers/user_provider.dart'; // 🚀 Added for Permissions

class AttendanceSpecifics extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  final VoidCallback onRefresh;

  const AttendanceSpecifics({
    super.key,
    required this.records,
    required this.onRefresh,
  });

  @override
  State<AttendanceSpecifics> createState() => _AttendanceSpecificsState();
}

class _AttendanceSpecificsState extends State<AttendanceSpecifics> {
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _resolveOvertime(String id, bool approve) async {
    try {
      await _supabaseService.resolveOvertime(
        attendanceId: id,
        approve: approve,
      );
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OT Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resolveEarlyLeave(String id, bool approve) async {
    try {
      await _supabaseService.resolveEarlyLeave(
        attendanceId: id,
        isApproved: approve,
      );
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Early Leave Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🚀 THE BOUNCER: Are they a Manager or just a Viewer?
    final userProvider = context.watch<UserProvider>();
    final canManage = userProvider.can('manage_attendance');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.records.length,
      itemBuilder: (context, index) {
        final record = widget.records[index];
        final String status = record['status'] ?? 'Unknown';
        final String rawStatus = record['raw_status'] ?? status;
        final String name = record['name'] ?? 'Unknown Employee';
        final String? clockIn = record['clock_in'];
        final String? clockOut = record['clock_out'];

        final bool isOTPending = rawStatus == 'overtime_pending';
        final bool isEarlyPending = rawStatus == 'early_leave_pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clockIn != null
                            ? "${_formatTime(clockIn)} - ${clockOut != null ? _formatTime(clockOut) : 'Active'}"
                            : "No Punch Data",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  _buildStatusBadge(status),
                ],
              ),

              // 🚀 GRANULAR SECURITY: OVERTIME
              if (isOTPending) ...[
                const SizedBox(height: 12),
                if (canManage)
                  _buildResolutionPanel(
                    title: "Overtime: ${record['overtime_minutes']} mins",
                    subtitle: "Employee stayed past rostered shift.",
                    color: Colors.blue,
                    icon: Icons.timer_outlined,
                    onApprove: () => _resolveOvertime(record['id'], true),
                    onReject: () => _resolveOvertime(record['id'], false),
                    approveText: "Approve OT",
                    rejectText: "Reject OT",
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.lock_clock, size: 14, color: Colors.blue),
                      SizedBox(width: 6),
                      Text(
                        "Pending Manager Approval",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
              ],

              // 🚀 GRANULAR SECURITY: EARLY LEAVE
              if (isEarlyPending) ...[
                const SizedBox(height: 12),
                if (canManage)
                  _buildResolutionPanel(
                    title: "Early Departure Alert",
                    subtitle: "Employee clocked out before shift end.",
                    color: Colors.purple,
                    icon: Icons.directions_run,
                    onApprove: () => _resolveEarlyLeave(record['id'], true),
                    onReject: () => _resolveEarlyLeave(record['id'], false),
                    approveText: "Approve",
                    rejectText: "Reject",
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.lock_clock, size: 14, color: Colors.purple),
                      SizedBox(width: 6),
                      Text(
                        "Pending Manager Approval",
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTime(String iso) {
    final DateTime dt = DateTime.parse(iso).toLocal();
    return DateFormat('h:mm a').format(dt);
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Present':
        color = Colors.green;
        break;
      case 'Late':
        color = Colors.orange;
        break;
      case 'Absent':
        color = Colors.red;
        break;
      case 'overtime_pending':
        color = Colors.blue;
        break;
      case 'early_leave_pending':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResolutionPanel({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onApprove,
    required VoidCallback onReject,
    required String approveText,
    required String rejectText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: Text(
                    rejectText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(approveText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
